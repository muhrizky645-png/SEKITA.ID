import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'widgets.dart';
import 'detail.dart';
import 'search.dart';
import 'kebutuhan.dart';
import 'akun.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Mitra>> _mitraFuture;
  Future<List<Kebutuhan>>? _myFuture;

  @override
  void initState() {
    super.initState();
    _mitraFuture = Api.fetchMitra();
    if (Api.currentUser != null) {
      _myFuture = Api.fetchKebutuhanMine();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _mitraFuture = Api.fetchMitra();
      if (Api.currentUser != null) {
        _myFuture = Api.fetchKebutuhanMine();
      } else {
        _myFuture = null;
      }
    });
    await _mitraFuture;
  }

  void _openDetail(Mitra m) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MitraDetailScreen(mitra: m)));

  void _openCategory(String c) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialCategory: c)));

  void _openSearch() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true)));

  void _goAkun() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AkunScreen()));

  void _goKebutuhan() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const KebutuhanScreen()));

  @override
  Widget build(BuildContext context) {
    final user = Api.currentUser;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<Mitra>>(
            future: _mitraFuture,
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
                  _header(user),
                  _searchBar(),
                  const SizedBox(height: 12),
                  _categories(),
                  // ─ Guest: banner CTA login/posting ─
                  if (user == null) _guestBanner(),
                  // ─ Pembeli: kebutuhan saya ─
                  if (user != null && _myFuture != null) _myKebutuhanSection(),
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

  // ── Header ──────────────────────────────────────────────────────────
  Widget _header(dynamic user) {
    final subtitle = (user != null && user.nama.isNotEmpty)
        ? 'Hai, ${(user.nama as String).split(' ').first}! 👋'
        : 'Temukan jasa profesional di sekitarmu';
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
            children: [
              const Text('Sekita',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: kInk)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────
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

  // ── Kategori grid ─────────────────────────────────────────────────
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

  // ── Guest banner ───────────────────────────────────────────────────
  Widget _guestBanner() {
    return GestureDetector(
      onTap: _goAkun,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Punya kebutuhan jasa?',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  SizedBox(height: 3),
                  Text('Login & posting, mitra siap menghubungimu.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Login',
                  style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kebutuhan Saya (pembeli login) ──────────────────────────────────
  Widget _myKebutuhanSection() {
    return FutureBuilder<List<Kebutuhan>>(
      future: _myFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();
        final preview = list.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kebutuhanmu',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  GestureDetector(
                    onTap: _goKebutuhan,
                    child: const Text('Lihat semua →',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            ...preview.map((k) => _miniCard(k)),
          ],
        );
      },
    );
  }

  Widget _miniCard(Kebutuhan k) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Text(k.ic.isEmpty ? '📝' : k.ic, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(k.cat.isEmpty ? 'Umum' : k.cat,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: k.isDone ? const Color(0xFFDCFCE7) : const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              k.isDone ? 'Selesai' : 'Terbuka',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: k.isDone ? const Color(0xFF166534) : kBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ───────────────────────────────────────────────────
  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }

  // ── Promo card ─────────────────────────────────────────────────────
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

// ── Error view ──────────────────────────────────────────────────────────
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
