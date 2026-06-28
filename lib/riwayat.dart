import 'package:flutter/material.dart';
import 'core.dart';
import 'mitra_api.dart';
import 'notif_bell.dart';

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
              itemBuilder: (_, i) => _RiwayatCard(items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final KontakRiwayat k;
  const _RiwayatCard(this.k);

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

  @override
  Widget build(BuildContext context) {
    final waktu = _timeAgo(k.ts);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(k.ic, style: const TextStyle(fontSize: 20)),
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
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (k.isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ),
            ],
          ),
          if (k.budget.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Expanded(child: Text(k.budget, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF16A34A)))),
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
              icon: const Icon(Icons.chat_rounded, size: 18, color: Color(0xFF16A34A)),
              label: const Text('Hubungi lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
