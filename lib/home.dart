import 'dart:async';
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
  final int activeTab;
  const HomeScreen({super.key, this.activeTab = 0});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Mitra>> _mitraFuture;
  Future<List<Kebutuhan>>? _myFuture;
  int? _shownUid;
  late final PageController _pageCtrl;
  Timer? _autoTimer;
  int _bannerIdx = 0;
  static const int _bannerCount = 5;
  static const int _maxMitraBeranda = 15;

  @override
  void initState() {
    super.initState();
    _mitraFuture = Api.fetchMitra();
    _loadMine();
    _ensureSession();
    _pageCtrl = PageController(initialPage: _bannerCount * 1000);
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _loadMine() {
    final u = Api.currentUser;
    _shownUid = u?.id;
    _myFuture = u != null ? Api.fetchKebutuhanMine() : null;
  }

  // Saat app start, layar ini dibangun sekali (IndexedStack) padahal me() belum
  // dipanggil. Muat sesi supaya "Kebutuhanmu Terbaru" langsung tampil tanpa
  // harus refresh manual dulu.
  Future<void> _ensureSession() async {
    if (Api.currentUser != null) return;
    try {
      await Api.me();
    } catch (_) {}
    if (!mounted) return;
    if (Api.currentUser != null) setState(_loadMine);
  }

  @override
  void didUpdateWidget(covariant HomeScreen old) {
    super.didUpdateWidget(old);
    // Segarkan daftar kebutuhanku tiap kali Beranda kembali jadi tab aktif,
    // sekaligus menangkap perubahan status login (real-time).
    if (widget.activeTab == 0 && old.activeTab != 0) {
      setState(_loadMine);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _mitraFuture = Api.fetchMitra();
      _loadMine();
    });
    await _mitraFuture;
  }

  void _openDetail(Mitra m) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MitraDetailScreen(mitra: m)));

  void _openCategory(String c) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialCategory: c)));

  void _openSearch() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true)));

  void _openAllMitra() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));

  void _goAkun() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AkunScreen()));

  void _goKebutuhan() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const KebutuhanScreen()));

  @override
  Widget build(BuildContext context) {
    final user = Api.currentUser;
    // Kalau status login berubah (mis. baru login lewat Akun) tapi daftar belum
    // dimuat ulang, jadwalkan reload pada frame berikutnya.
    if (user?.id != _shownUid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Api.currentUser?.id != _shownUid) {
          setState(_loadMine);
        }
      });
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<Mitra>>(
            future: _mitraFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: SekitaDots());
              }
              if (snap.hasError) return _ErrorView(onRetry: _reload);
              final all = snap.data ?? [];
              final sorted = sortPromoted(all, 'beranda');
              final shown = sorted.take(_maxMitraBeranda).toList();
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _hero(user),
                  const SizedBox(height: 14),
                  _banners(context),
                  const SizedBox(height: 14),
                  _categories(),
                  if (user == null) _guestBanner(),
                  if (user != null) _myKebutuhanSection(),
                  _sectionTitle('Mitra'),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Belum ada mitra.')),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                        children: shown
                            .map((m) => MitraCard(
                                m: m,
                                surface: 'beranda',
                                onTap: () => _openDetail(m)))
                            .toList(),
                      ),
                    ),
                  if (sorted.length > _maxMitraBeranda) _lihatMitraLain(),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _lihatMitraLain() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: GestureDetector(
        onTap: _openAllMitra,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: kBrandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Lihat mitra lain',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  // Hero header dengan gradient ungu->biru (setema logo) + kolom pencarian.
  Widget _hero(dynamic user) {
    final subtitle = (user != null && (user.nama as String).isNotEmpty)
        ? 'Hai, ${(user.nama as String).split(' ').first}! \ud83d\udc4b'
        : 'Temukan jasa profesional di sekitarmu';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: const BoxDecoration(
        gradient: kBrandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  'assets/icon/sekita_icon.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.search, color: kBrand, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sekita',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFFE0E7FF))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _searchBar(),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return GestureDetector(
      onTap: _openSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[500]),
            const SizedBox(width: 10),
            Text('Cari jasa atau mitra...', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  // Banner auto-scroll (3 detik, infinite ke kiri)
  Widget _banners(BuildContext context) {
    final w = MediaQuery.of(context).size.width - 32;
    final h = w / 4;
    return Column(
      children: [
        SizedBox(
          height: h,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _bannerIdx = i % _bannerCount),
            itemBuilder: (_, i) {
              final n = (i % _bannerCount) + 1;
              return GestureDetector(
                onTap: _openSearch,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFE5E7EB),
                  ),
                  child: SekitaImage(bannerPath(n), fit: BoxFit.cover),
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
                gradient: _bannerIdx == i ? kBrandGradient : null,
                color: _bannerIdx == i ? null : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Kategori: icon dibungkus kotak (seperti card mitra)
  Widget _categories() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: Api.kategoriDasar.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = Api.kategoriDasar[i];
          return GestureDetector(
            onTap: () => _openCategory(c),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: SekitaImage(catIconPath(c), fit: BoxFit.contain),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60,
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
            const Text('\ud83d\udcdd', style: TextStyle(fontSize: 24)),
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
                gradient: kBrandGradient,
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

  // Kebutuhanmu Terbaru (mode pembeli)
  Widget _myKebutuhanSection() {
    return FutureBuilder<List<Kebutuhan>>(
      future: _myFuture,
      builder: (context, snap) {
        final loading = _myFuture != null &&
            snap.connectionState == ConnectionState.waiting;
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
                      child: const Text('Lihat semua \u2192',
                          style: TextStyle(
                              fontSize: 12,
                              color: kBrand,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: SekitaDots(size: 8)),
              )
            else if (list.isEmpty)
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, color: kBrand, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Kamu belum punya kebutuhan terbaru',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 6),
          Text('Posting kebutuhanmu, biar mitra yang datang \ud83d\ude4c',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _miniCard(Kebutuhan k) {
    return GestureDetector(
      onTap: () => openKebutuhanDetail(context, k, mine: true, onChanged: _reload),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Text(k.ic.isEmpty ? '\ud83d\udcdd' : k.ic,
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
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
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
