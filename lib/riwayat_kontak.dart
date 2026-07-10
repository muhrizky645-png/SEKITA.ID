import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'kebutuhan.dart';

const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);
const Color _green = Color(0xFF16A34A);

/// true jika lead [k] sudah dihubungi mitra ini dalam 24 jam terakhir.
/// Kontak ulang dalam jendela ini gratis (samakan dengan web).
bool _recontactFree(Kebutuhan k) {
  final m = Api.currentMitra;
  if (m == null) return false;
  final mid = m.id.toString();
  final mwa = waNormalize(m.wa);
  const windowMs = 24 * 60 * 60 * 1000;
  var last = 0;
  for (final c in k.contactedBy) {
    final match = (c.id.isNotEmpty && c.id == mid) ||
        (mwa.isNotEmpty && c.wa.isNotEmpty && waNormalize(c.wa) == mwa);
    if (match && c.ts > last) last = c.ts;
  }
  if (last == 0) return false;
  return DateTime.now().millisecondsSinceEpoch - last < windowMs;
}

/// Ikon WhatsApp besar untuk header popup (aset, fallback ikon hijau).
Widget _waBigIcon() => Image.asset(
      'assets/img/wa.png',
      width: 54,
      height: 54,
      color: _green,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (_, __, ___) => const Icon(Icons.chat, size: 54, color: _green),
    );

/// Popup konfirmasi bergaya web: kartu putih, ikon besar, tombol hijau.
Future<bool> _waModal(
  BuildContext context, {
  required String title,
  required String body,
  required String go,
  String sec = '',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _waBigIcon(),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: kInk)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 14.5, height: 1.55)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text(go, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            if (sec.isNotEmpty) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(sec, style: const TextStyle(color: _muted, fontSize: 13.5)),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  return r == true;
}

/// Riwayat Kontak: daftar lead (kebutuhan) yang sudah pernah dihubungi mitra ini.
/// Diturunkan dari daftar kebutuhan (field contactedBy) -> tanpa endpoint backend baru.
class RiwayatKontakScreen extends StatefulWidget {
  const RiwayatKontakScreen({super.key});
  @override
  State<RiwayatKontakScreen> createState() => _RiwayatKontakScreenState();
}

class _RiwayatKontakScreenState extends State<RiwayatKontakScreen> {
  late Future<List<Kebutuhan>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Kebutuhan>> _load() async {
    final mid = '${Api.currentMitra?.id ?? 0}';
    if (mid == '0') return <Kebutuhan>[];
    final all = await Api.fetchKebutuhan();
    final mine = all.where((k) => k.contactedBy.any((c) => c.id == mid)).toList();
    mine.sort((a, b) => b.ts.compareTo(a.ts));
    return mine;
  }

  void _reload() => setState(() {
    _future = _load();
  });

  Future<void> _refresh() async {
    _reload();
    await _future;
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _openDetail(Kebutuhan k) {
    openKebutuhanDetail(context, k, mine: false, onChanged: _reload);
  }

  Future<void> _hubungiLagi(Kebutuhan k) async {
    if (k.wa.isEmpty) return;
    final free = _recontactFree(k);
    final ok = await _waModal(
      context,
      title: free ? 'Sudah pernah kamu hubungi' : 'Lanjut chat WhatsApp?',
      body: free
          ? 'Nomor ini sudah pernah kamu hubungi dalam 24 jam terakhir. Mau hubungi lagi? Tidak akan mengurangi Kontak Tersedia kamu.'
          : 'Kalau lanjut, 1 Kontak Tersedia kepakai ya.',
      go: free ? 'Hubungi lagi' : 'Lanjut buka WhatsApp',
      sec: 'Batal',
    );
    if (!ok || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final r = await Api.kontakLead(k.id);
    if (mounted) Navigator.pop(context);
    if (!r.ok) {
      _snack(r.error.isNotEmpty ? r.error : 'Gagal menghubungi pelanggan.');
      return;
    }
    Api.setMitraKuota(r.kuota);
    if (mounted) setState(() {});
    await openWa(
      k.wa,
      text: pesanMitraKePembeli(
        usaha: Api.currentMitra?.displayName ?? '',
        kebutuhan: k.cat.isNotEmpty ? k.cat : k.title,
        mitraId: Api.currentMitra?.id.toString() ?? '',
      ),
    );
    if (r.deducted) {
      _snack('WhatsApp kebuka. 1 Kontak Tersedia kepakai. Sisa: ${r.kuota} Kontak.');
    } else {
      _snack('WhatsApp kebuka. Tidak ada Kontak terpakai (sudah dihubungi <24 jam).');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Riwayat Kontak',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Muat ulang',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Kebutuhan>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _errorView();
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return _emptyView();
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      '${items.length} lead pernah kamu hubungi',
                      style: const TextStyle(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  );
                }
                final k = items[i - 1];
                return _RiwayatCard(
                  k: k,
                  onTap: () => _openDetail(k),
                  onHubungi: () => _hubungiLagi(k),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _emptyView() {
    return ListView(
      children: [
        const SizedBox(height: 70),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history, color: _green, size: 34),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Belum ada lead yang dihubungi',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kInk)),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Lead yang sudah kamu hubungi dari tab Lead akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _errorView() {
    return ListView(
      children: [
        const SizedBox(height: 90),
        const Icon(Icons.wifi_off_rounded, size: 56, color: _muted),
        const SizedBox(height: 12),
        const Center(child: Text('Gagal memuat riwayat. Periksa koneksi internet.')),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: _reload,
            style: FilledButton.styleFrom(backgroundColor: _green),
            child: const Text('Coba lagi'),
          ),
        ),
      ],
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final Kebutuhan k;
  final VoidCallback onHubungi;
  final VoidCallback onTap;
  const _RiwayatCard({required this.k, required this.onHubungi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = k.status == 'done' || k.status == 'selesai' || k.status == 'closed';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFFEFF4FF),
                        padding: const EdgeInsets.all(9),
                        child: SekitaImage(catIconPath(k.cat), fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kInk)),
                          const SizedBox(height: 2),
                          Text('${k.cat}${k.loc.isNotEmpty ? ' \u00b7 ${k.loc}' : ''}', style: const TextStyle(color: _muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (done ? _muted : _green).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        done ? 'Selesai' : 'Aktif',
                        style: TextStyle(color: done ? _muted : _green, fontWeight: FontWeight.w700, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
                if (k.budget.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16, color: _muted),
                      const SizedBox(width: 6),
                      Expanded(child: Text(k.budget, style: const TextStyle(color: kInk, fontSize: 13))),
                    ],
                  ),
                ],
                if (k.deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(k.deskripsi, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: _green),
                    const SizedBox(width: 6),
                    Text('${k.contactedCount}/7 penawar', style: const TextStyle(color: _muted, fontSize: 12.5)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: onHubungi,
                      style: FilledButton.styleFrom(backgroundColor: _green),
                      icon: Image.asset(
                        'assets/img/wa.png',
                        width: 18,
                        height: 18,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (_, __, ___) => const Icon(Icons.chat_outlined, size: 18, color: Colors.white),
                      ),
                      label: const Text('WhatsApp lagi', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
