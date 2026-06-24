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
  final _pageCtrl = PageController();
  int _bannerIdx = 0;
  static const int _bannerCount = 5;

  @override
  void initState() {
    super.initState();
    _mitraFuture = Api.fetchMitra();
    if (Api.currentUser != null) {
      _myFuture = Api.fetchKebutuhanMine();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _mitraFuture = Api.fetchMitra();
      _myFuture = Api.currentUser != null ? Api.fetchKebutuhanMine() : null;
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
              if (snap.hasError) return _ErrorView(onRetry: _reload);
              final all = snap.data ?? [];
              final sorted = [
                ...all.where((m) => m.promoted > 0),
                ...all.where((m) => m.promoted == 0),
              ];
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _header(user),
                  _searchBar(),
                  const SizedBox(height: 14),
                  _banners(context),
                  const SizedBox(height: 14),
                  _categories(),
                  if (user == null) _guestBanner(),
                  if (user != null && _myFuture != null) _myKebutuhanSection(),
                  _sectionTitle('Mitra'),
                  if (sorted.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Belum ada mitra.')),
                    ),
                  ...sorted.map((m) => MitraCard(m: m, onTap: () => _openDetail(m))),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(dynamic user) {
    final subtitle = (user != null && (user.nama as String).isNotEmpty)
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

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

  // ── Banner: gambar asli dari sekita.id (1600x400 = 4:1) ─────────────────────
  Widget _banners(BuildContext context) {
    final w = MediaQuery.of(context).size.width - 32;
    final h = w / 4;
    return Column(
      children: [
        SizedBox(
          height: h,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _bannerCount,
            onPageChanged: (i) => setState(() => _bannerIdx = i),
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: _openSearch,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFE5E7EB),
                  ),
                  child: SekitaImage(bannerPath(i + 1), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerIdx == i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _bannerIdx == i ? kBrand : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Kategori horizontal scroll dengan icon asli (lebih kecil) ─────────────────
  Widget _categories() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: Api.kategoriDasar.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final c = Api.kategoriDasar[i];
          return GestureDetector(
            onTap: () => _openCategory(c),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: SekitaImage(catIconPath(c), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 58,
                  child: Text(c,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 10, height: 1.2)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _guestBanner() {
    return GestureDetector(
      onTap: _goAkun,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFD1FF)),
        ),
        child: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Login untuk posting kebutuhan & lacak aktivitasmu.',
                style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kBrand,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Login',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kebutuhanmu Terbaru (mode pembeli) ───────────────────────────────
  Widget _myKebutuhanSection() {
    return FutureBuilder<List<Kebutuhan>>(
      future: _myFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final list = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kebutuhanmu Terbaru',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  if (list.isNotEmpty)
                    GestureDetector(
                      onTap: _goKebutuhan,
                      child: const Text('Lihat semua →',
                          style: TextStyle(
                              fontSize: 12,
                              color: kBrand,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            if (list.isEmpty)
              _emptyKebutuhanBox()
            else
              ...list.take(3).map((k) => _miniCard(k)),
          ],
        );
      },
    );
  }

  Widget _emptyKebutuhanBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, color: kBrand, size: 26),
          ),
          const SizedBox(height: 12),
          const Text('Kamu belum punya kebutuhan terbaru',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Posting kebutuhanmu, biar mitra yang datang 🙌',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
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
          Text(k.ic.isEmpty ? '📝' : k.ic,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(k.cat.isEmpty ? 'Umum' : k.cat,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: k.isDone
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              k.isDone ? 'Selesai' : 'Terbuka',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: k.isDone
                    ? const Color(0xFF166534)
                    : kBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child:
          Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
