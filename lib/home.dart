import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'widgets.dart';
import 'detail.dart';
import 'search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Mitra>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.fetchMitra();
  }

  Future<void> _reload() async {
    setState(() => _future = Api.fetchMitra());
    await _future;
  }

  void _openDetail(Mitra m) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MitraDetailScreen(mitra: m)));

  void _openCategory(String c) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialCategory: c)));

  void _openSearch() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<Mitra>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _ErrorView(onRetry: _reload);
              }
              final all = snap.data ?? [];
              final promoted = all.where((m) => m.promoted > 0).toList();
              final rest = all.where((m) => m.promoted == 0).toList();
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _header(),
                  _searchBar(),
                  const SizedBox(height: 12),
                  _categories(),
                  if (promoted.isNotEmpty) ...[
                    _sectionTitle('Mitra Pilihan'),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: promoted.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _promoCard(promoted[i]),
                      ),
                    ),
                  ],
                  _sectionTitle('Semua Mitra'),
                  if (all.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Belum ada mitra.')),
                    ),
                  ...rest.map((m) => MitraCard(m: m, onTap: () => _openDetail(m))),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: kBrand, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.search, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Sekita', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: kInk)),
              Text('Temukan jasa profesional di sekitarmu',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: _openSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[500]),
              const SizedBox(width: 10),
              Text('Cari jasa atau mitra...', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categories() {
    final w = (MediaQuery.of(context).size.width - 24) / 4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: Api.kategoriDasar.map((c) {
          return SizedBox(
            width: w,
            child: InkWell(
              onTap: () => _openCategory(c),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconForKategori(c), color: kBrand, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(c,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11, height: 1.1)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }

  Widget _promoCard(Mitra m) {
    return GestureDetector(
      onTap: () => _openDetail(m),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 52, height: 52, child: MitraAvatar(m: m)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(m.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(m.kategori,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        const Center(child: Text('Gagal memuat data. Periksa koneksi internet.')),
        const SizedBox(height: 12),
        Center(child: FilledButton(onPressed: onRetry, child: const Text('Coba lagi'))),
      ],
    );
  }
}
