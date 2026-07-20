import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'home.dart';
import 'search.dart';
import 'kebutuhan.dart';
import 'post.dart';
import 'akun.dart';
import 'mitra.dart';
import 'riwayat.dart';
import 'toko.dart';
import 'notif_bell.dart';
import 'notif.dart';

// Titik masuk app. Dibungkus runZonedGuarded + ErrorWidget kustom supaya bila
// terjadi error saat startup/render, app TIDAK force-close diam-diam, melainkan
// menampilkan pesan error yang bisa discreenshot untuk debugging.
void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      _FatalErrorScreen(message: details.exceptionAsString());

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught async error: $error\n$stack');
      return true;
    };

    // Inisialisasi ringan. Masing-masing sudah aman (try/catch internal),
    // tapi tetap dibungkus agar kegagalan init tak pernah menutup app.
    try {
      await Api.initDeviceId();
    } catch (e, s) {
      debugPrint('initDeviceId gagal: $e\n$s');
    }
    unawaited(Api.fetchTaxonomy());
    try {
      await Notif.init();
    } catch (e, s) {
      debugPrint('Notif.init gagal: $e\n$s');
    }

    runApp(const SekitaApp());
  }, (error, stack) {
    runApp(_FatalErrorApp(message: '$error\n\n$stack'));
  });
}

// Layar error fatal (dipakai saat startup gagal total).
class _FatalErrorApp extends StatelessWidget {
  final String message;
  const _FatalErrorApp({required this.message});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _FatalErrorScreen(message: message),
    );
  }
}

class _FatalErrorScreen extends StatelessWidget {
  final String message;
  const _FatalErrorScreen({required this.message});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromView(ui.PlatformDispatcher.instance.views.first),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Terjadi kesalahan saat membuka aplikasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Screenshot layar ini lalu kirim ke pengembang.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          message,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SekitaApp extends StatelessWidget {
  const SekitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sekita',
      debugShowCheckedModeBanner: false,
      theme: buildSekitaTheme(),
      home: const RootNav(),
    );
  }
}

// Splash bergaya loading: gradient brand + logo + loader titik. Ditampilkan
// selagi sesi dipulihkan supaya tidak ada kedip layar putih saat app dibuka.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kBrandGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/icon/sekita_icon.png',
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.search, color: kBrand, size: 52),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Sekita',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Jasa lokal, dekat denganmu',
                  style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 13)),
              const SizedBox(height: 30),
              const SekitaDots(color: Colors.white, size: 11),
            ],
          ),
        ),
      ),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  // Mode pembeli: 0=Beranda 1=Cari 2=Posting(FAB) 3=Kebutuhan 4=Akun
  int _i = 0;
  // Mode mitra: 0=Lead 1=Riwayat 2=Toko 3=Akun Mitra
  int _mi = 0;
  // Splash aktif sampai sesi selesai dipulihkan.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Notif.setOnOpen(_onNotifOpen);
    Api.mode.addListener(_onMode);
    mitraTab.addListener(_onMitraTab);
    _restore();
  }

  // Pulihkan sesi (pembeli/mitra) saat app dibuka, lalu setState agar nav sesuai.
  Future<void> _restore() async {
    try {
      await Api.me();
      await _syncNotifTags();
    } catch (_) {}
    if (mounted) setState(() => _ready = true);
  }

  void _onMode() {
    _syncNotifTags();
    if (mounted) setState(() {});
  }

  // Lonceng / pindah tab mitra dari mana saja.
  void _onMitraTab() {
    if (!mounted) return;
    setState(() => _mi = mitraTab.value);
  }

  // Tap notifikasi lead -> pastikan tab Lead aktif (mode mitra).
  void _onNotifOpen(Map<String, dynamic> data) {
    if (!mounted) return;
    if (Api.mode.value == 'mitra') {
      mitraTab.value = 0;
    }
  }

  // Sinkronkan tag OneSignal sesuai peran aktif.
  Future<void> _syncNotifTags() async {
    await Notif.requestPermission();
    if (Api.mode.value == 'mitra') {
      await Notif.setMitraTags(Api.currentMitra?.kategori ?? '');
    } else {
      await Notif.setPembeliTags();
    }
  }

  @override
  void dispose() {
    Api.mode.removeListener(_onMode);
    mitraTab.removeListener(_onMitraTab);
    Notif.clearOnOpen();
    super.dispose();
  }

  void _go(int v) => setState(() => _i = v);

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _SplashScreen();
    return Api.mode.value == 'mitra' ? _buildMitra() : _buildPembeli();
  }

  Widget _buildPembeli() {
    final pages = [
      HomeScreen(activeTab: _i),
      const SearchScreen(),
      PostKebutuhanScreen(onGoTab: _go),
      const KebutuhanScreen(),
      const AkunScreen(),
    ];

    final onPosting = _i == 2;

    return Scaffold(
      body: IndexedStack(index: _i, children: pages),
      floatingActionButton: _PostingFab(
        active: onPosting,
        onTap: () => _go(2),
      ),
      floatingActionButtonLocation: const _LoweredDockedFab(8),
      bottomNavigationBar: _BottomBar(
        selectedIndex: _i,
        onSelect: _go,
      ),
    );
  }

  Widget _buildMitra() {
    final pages = const [
      LeadScreen(),
      RiwayatKontakScreen(),
      TokoScreen(),
      AkunMitraScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _mi, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mi,
        height: 60,
        onDestinationSelected: (v) => mitraTab.value = v,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Lead'),
          NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Toko'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}

// Lokasi FAB: sama seperti centerDocked tapi diturunkan beberapa piksel
// supaya tombol + duduk lebih dalam di cekungan (notch ikut menyesuaikan).
class _LoweredDockedFab extends FloatingActionButtonLocation {
  final double dy;
  const _LoweredDockedFab(this.dy);
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final base = FloatingActionButtonLocation.centerDocked.getOffset(geometry);
    return Offset(base.dx, base.dy + dy);
  }
}

// -- FAB tengah (tombol Posting) - selalu bulat & terlihat. Warna berubah ungu
// saat tab Posting aktif; biru saat tidak aktif. --
class _PostingFab extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _PostingFab({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? kBrandPurple : kBrand,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: active ? const Color(0x597C3AED) : const Color(0x592563EB),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// -- Bottom bar dengan cekungan (notch) untuk FAB Posting yang selalu ada.
// Tinggi background dikontrol eksplisit (height) + padding 0 supaya latar
// putihnya mepet dengan ikon, tidak menyisakan ruang kosong berlebih. --
class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _BottomBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 5,
      color: Colors.white,
      elevation: 10,
      height: 52,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          _item(Icons.home_outlined, Icons.home, 'Beranda', 0),
          _item(Icons.search_outlined, Icons.search, 'Cari', 1),
          _middle(),
          _item(Icons.assignment_outlined, Icons.assignment, 'Kebutuhan', 3),
          _item(Icons.person_outline, Icons.person, 'Akun', 4),
        ],
      ),
    );
  }

  // Item tengah: cuma label 'Posting' di bawah, karena tombol + (FAB) selalu
  // menempati cekungan di atasnya.
  Widget _middle() {
    final sel = selectedIndex == 2;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Spacer(),
            Text(
              'Posting',
              style: TextStyle(
                fontSize: 10,
                fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                color: sel ? kBrandPurple : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, IconData selIcon, String label, int idx) {
    final sel = selectedIndex == idx;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(idx),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sel ? selIcon : icon, color: sel ? kBrand : Colors.grey[600], size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: sel ? kBrand : Colors.grey[600],
                fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
