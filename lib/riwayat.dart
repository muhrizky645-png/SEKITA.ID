import 'package:flutter/material.dart';
import 'core.dart';
import 'api.dart';
import 'mitra_api.dart';
import 'notif_bell.dart';

const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);
const Color _green = Color(0xFF16A34A);

String _timeAgo(int ms) {
  if (ms <= 0) return '';
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  if (d.inDays < 30) return '${d.inDays} hr lalu';
  final mo = (d.inDays / 30).floor();
  if (mo < 12) return '$mo bln lalu';
  return '${(d.inDays / 365).floor()} thn lalu';
}

/// Konfirmasi + (kalau perlu) potong 1 Kontak, lalu buka WhatsApp.
/// Aturan jendela 24 jam disamakan dengan Lead di web (kebutuhan-kontak.php):
///  - Sudah dihubungi < 24 jam  -> gratis, tidak memotong Kontak.
///  - Sudah dihubungi >= 24 jam -> potong 1 Kontak lagi.
Future<void> _hubungiUlang(BuildContext context, KontakRiwayat k) async {
  if (k.wa.isEmpty) return;
  const windowMs = 24 * 60 * 60 * 1000;
  final free = k.ts > 0 && (DateTime.now().millisecondsSinceEpoch - k.ts) < windowMs;

  final ok = await _waModal(
    context,
    title: free ? 'Sudah pernah kamu hubungi' : 'Lanjut chat WhatsApp?',
    body: free
        ? 'Nomor ini sudah pernah kamu hubungi dalam 24 jam terakhir. Mau hubungi lagi? Tidak akan mengurangi Kontak Tersedia kamu.'
        : 'Kalau lanjut, 1 Kontak Tersedia kepakai ya.',
    go: free ? 'Hubungi lagi' : 'Lanjut buka WhatsApp',
    sec: 'Batal',
  );
  if (!ok || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final r = await Api.kontakLead(k.id);
  if (context.mounted) Navigator.pop(context);
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  if (!r.ok) {
    final pesan = r.reason == 'no_quota'
        ? 'Kontak Tersedia habis. Hubungi admin untuk isi ulang.'
        : r.reason == 'full'
            ? 'Lead ini sudah penuh penawar.'
            : (r.error.isNotEmpty ? r.error : 'Gagal menghubungi.');
    messenger.showSnackBar(SnackBar(content: Text(pesan)));
    return;
  }

  Api.setMitraKuota(r.kuota);
  await openWa(
    k.wa,
    text: pesanMitraKePembeli(
      usaha: Api.currentMitra?.displayName ?? '',
      kebutuhan: k.cat.isNotEmpty ? k.cat : k.title,
      mitraId: Api.currentMitra?.id.toString() ?? '',
    ),
  );
  messenger.showSnackBar(SnackBar(
    content: Text(r.deducted
        ? 'WhatsApp kebuka. 1 Kontak Tersedia kepakai. Sisa: ${r.kuota} Kontak.'
        : 'WhatsApp kebuka. Tidak ada Kontak terpakai (sudah dihubungi <24 jam).'),
  ));
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

/// Daftar lead yang sudah pernah dihubungi mitra (Riwayat Kontak).
class RiwayatKontakScreen extends StatefulWidget {
  const RiwayatKontakScreen({super.key});
  @override
  State<RiwayatKontakScreen> createState() => _RiwayatKontakScreenState();
}

class _RiwayatKontakScreenState extends State<RiwayatKontakScreen> {
  late Future<List<KontakRiwayat>> _future;

  @override
  void initState() {
    super.initState();
    _future = MitraApi.riwayatKontak();
  }

  Future<void> _refresh() async {
    final f = MitraApi.riwayatKontak();
    setState(() { _future = f; });
    await f;
  }

  Future<void> _openDetail(KontakRiwayat k) async {
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RiwayatDetailSheet(k: k),
    );
    if (go == true && mounted) _hubungiUlang(context, k);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Riwayat Kontak', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: const [MitraBell(), SizedBox(width: 4)],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<KontakRiwayat>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 90),
                  Icon(Icons.history_rounded, size: 56, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Center(child: Text('Belum ada riwayat kontak', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                  SizedBox(height: 6),
                  Center(child: Text('Lead yang kamu hubungi akan muncul di sini.', style: TextStyle(color: Color(0xFF94A3B8)))),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _RiwayatCard(items[i], onTap: () => _openDetail(items[i])),
            );
          },
        ),
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final KontakRiwayat k;
  final VoidCallback onTap;
  const _RiwayatCard(this.k, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final waktu = _timeAgo(k.ts);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                        width: 42,
                        height: 42,
                        color: const Color(0xFFEFF4FF),
                        padding: const EdgeInsets.all(8),
                        child: SekitaImage(catIconPath(k.cat), fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(
                            [if (k.cat.isNotEmpty) k.cat, if (k.loc.isNotEmpty) k.loc].join(' \u00b7 '),
                            style: const TextStyle(color: _muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    if (k.isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted)),
                      ),
                  ],
                ),
                if (k.budget.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16, color: _green),
                      const SizedBox(width: 6),
                      Expanded(child: Text(k.budget, style: const TextStyle(fontWeight: FontWeight.w700, color: _green))),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 5),
                    Text(waktu.isEmpty ? 'Sudah dihubungi' : 'Dihubungi $waktu', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    const Spacer(),
                    Text('${k.penawar} penawar', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: k.wa.isEmpty ? null : () => _hubungiUlang(context, k),
                    icon: Image.asset(
                      'assets/img/wa.png',
                      width: 18,
                      height: 18,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
                    ),
                    label: const Text('WhatsApp lagi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RiwayatDetailSheet extends StatelessWidget {
  final KontakRiwayat k;
  const _RiwayatDetailSheet({required this.k});

  Widget _row(IconData ic, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(ic, size: 16, color: _muted),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 14, color: kInk))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final waktu = _timeAgo(k.ts);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: const Color(0xFFEFF4FF),
                        padding: const EdgeInsets.all(9),
                        child: SekitaImage(catIconPath(k.cat), fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(k.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: kInk)),
                    ),
                    if (k.isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _row(Icons.category_outlined, k.cat.isEmpty ? 'Umum' : k.cat),
                _row(Icons.location_on_outlined, k.loc.isEmpty ? '-' : k.loc),
                if (k.budget.isNotEmpty) _row(Icons.payments_outlined, k.budget),
                _row(Icons.schedule_rounded, waktu.isEmpty ? 'Sudah dihubungi' : 'Dihubungi $waktu'),
                _row(Icons.people_outline, '${k.penawar} penawar'),
                if (k.deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                  const SizedBox(height: 4),
                  Text(k.deskripsi, style: const TextStyle(height: 1.5, color: Color(0xFF374151))),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: k.wa.isEmpty ? null : () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(backgroundColor: _green),
                    icon: Image.asset(
                      'assets/img/wa.png',
                      width: 20,
                      height: 20,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => const Icon(Icons.chat_rounded, size: 20, color: Colors.white),
                    ),
                    label: const Text('WhatsApp lagi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
