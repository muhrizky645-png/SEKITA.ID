import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';

const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);
const Color _green = Color(0xFF16A34A);

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

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _hubungiLagi(Kebutuhan k) async {
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
    final loc = k.loc.isNotEmpty ? ' di ${k.loc}' : '';
    await openWa(
      k.wa,
      text: 'Halo, saya mitra Sekita. Saya tertarik membantu kebutuhan \"${k.title}\"$loc. Apakah masih dibutuhkan?',
    );
    if (r.deducted) {
      _snack('1 Kontak terpakai. Sisa saldo: ${r.kuota} Kontak.');
    } else {
      _snack('Gratis - lanjutan kontak dalam 24 jam.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Riwayat Kontak')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Kebutuhan>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Gagal memuat riwayat. Tarik untuk coba lagi.')),
                ],
              );
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.history, size: 48, color: _muted),
                  SizedBox(height: 8),
                  Center(child: Text('Belum ada lead yang kamu hubungi.', style: TextStyle(color: _muted))),
                  SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Center(child: Text('Lead yang sudah kamu hubungi dari tab Lead akan muncul di sini.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12.5))),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _RiwayatCard(k: items[i], onHubungi: () => _hubungiLagi(items[i])),
            );
          },
        ),
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final Kebutuhan k;
  final VoidCallback onHubungi;
  const _RiwayatCard({required this.k, required this.onHubungi});

  @override
  Widget build(BuildContext context) {
    final done = k.status == 'done' || k.status == 'selesai' || k.status == 'closed';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
                child: Text(k.ic.isNotEmpty ? k.ic : '\u{1F4DD}', style: const TextStyle(fontSize: 20)),
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
              OutlinedButton.icon(
                onPressed: onHubungi,
                style: OutlinedButton.styleFrom(foregroundColor: _green, side: const BorderSide(color: _green)),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Hubungi lagi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
