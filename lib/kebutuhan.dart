import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';

String timeAgo(int ms) {
  if (ms <= 0) return '';
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inMinutes < 1) return 'Baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  if (d.inDays < 30) return '${d.inDays} hari lalu';
  final months = (d.inDays / 30).floor();
  if (months < 12) return '$months bln lalu';
  return '${(d.inDays / 365).floor()} thn lalu';
}

class KebutuhanScreen extends StatefulWidget {
  const KebutuhanScreen({super.key});
  @override
  State<KebutuhanScreen> createState() => _KebutuhanScreenState();
}

class _KebutuhanScreenState extends State<KebutuhanScreen> {
  late Future<List<Kebutuhan>> _future;
  bool _mine = false;

  @override
  void initState() {
    super.initState();
    _future = Api.fetchKebutuhan();
  }

  void _load() {
    setState(() {
      _future = _mine ? Api.fetchKebutuhanMine() : Api.fetchKebutuhan();
    });
  }

  Future<void> _refresh() async {
    _load();
    await _future;
  }

  void _setMine(bool v) {
    _mine = v;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebutuhan'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Semua'), icon: Icon(Icons.public, size: 18)),
                ButtonSegment(value: true, label: Text('Postingan Saya'), icon: Icon(Icons.person_outline, size: 18)),
              ],
              selected: {_mine},
              onSelectionChanged: (s) => _setMine(s.first),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Kebutuhan>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ListView(children: const [
                      SizedBox(height: 140),
                      Center(child: Text('Gagal memuat kebutuhan.')),
                    ]);
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return ListView(children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(_mine
                            ? 'Kamu belum punya postingan.'
                            : 'Belum ada kebutuhan yang diposting.'),
                      ),
                    ]);
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: list.map((k) => _card(k)).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(Kebutuhan k) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(k: k),
    );
  }

  Widget _statusChip(String t, Color bg, Color fg) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _card(Kebutuhan k) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openDetail(k),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(k.ic, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(k.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        if (k.isDone)
                          _statusChip('Selesai', const Color(0xFFDCFCE7), const Color(0xFF166534))
                        else
                          _statusChip('Terbuka', const Color(0xFFEFF4FF), kBrand),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${k.cat.isEmpty ? 'Umum' : k.cat} · ${k.loc.isEmpty ? '-' : k.loc}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    if (k.budget.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Budget: ${k.budget}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(k.pembeliNama.isEmpty ? 'Pengguna' : k.pembeliNama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ),
                        const SizedBox(width: 8),
                        Text('· ${timeAgo(k.ts)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                    if (k.contactedCount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${k.contactedCount} mitra menghubungi',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final Kebutuhan k;
  const _DetailSheet({required this.k});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k.ic, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(k.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(Icons.category_outlined, k.cat.isEmpty ? 'Umum' : k.cat),
            _row(Icons.location_on_outlined, k.loc.isEmpty ? '-' : k.loc),
            if (k.budget.isNotEmpty) _row(Icons.payments_outlined, k.budget),
            _row(Icons.person_outline, k.pembeliNama.isEmpty ? 'Pengguna' : k.pembeliNama),
            _row(Icons.schedule, timeAgo(k.ts)),
            if (k.deskripsi.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(k.deskripsi, style: const TextStyle(height: 1.5, color: Color(0xFF374151))),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData ic, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(ic, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
}
