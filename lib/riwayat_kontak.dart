import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'widgets.dart';

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

  void _reload() => setState(() => _future = _load());

  Future<void> _refresh() async {
    _reload();
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
                return _RiwayatCard(k: k, onHubungi: () => _hubungiLagi(k));
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 44, height: 44, child: KebutuhanAvatar(k: k)),
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
