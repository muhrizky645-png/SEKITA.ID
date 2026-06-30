import 'package:flutter/material.dart';
import 'core.dart';
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
    setState(() => _future = f);
    await f;
  }

  void _openDetail(KontakRiwayat k) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RiwayatDetailSheet(k: k),
    );
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
                  child: OutlinedButton.icon(
                    onPressed: k.wa.isEmpty ? null : () => openWa(k.wa, text: 'Halo, saya mitra Sekita soal ${k.title}.'),
                    icon: Image.asset(
                      'assets/img/wa.png',
                      width: 18,
                      height: 18,
                      errorBuilder: (_, __, ___) => const Icon(Icons.chat_rounded, size: 18, color: _green),
                    ),
                    label: const Text('WhatsApp lagi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
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
                    onPressed: k.wa.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            openWa(k.wa, text: 'Halo, saya mitra Sekita soal ${k.title}.');
                          },
                    style: FilledButton.styleFrom(backgroundColor: _green),
                    icon: Image.asset(
                      'assets/img/wa.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(Icons.chat_rounded, size: 20),
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
