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
    await Api.me();
    await _syncNotifTags();
    if (mounted) setState(() {});
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
        hidden: onPosting,
        onTap: () => _go(2),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

// -- FAB tengah (tombol Posting) - disembunyikan dengan animasi saat di tab Posting --
class _PostingFab extends StatelessWidget {
  final bool hidden;
  final VoidCallback onTap;
  const _PostingFab({required this.hidden, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedScale(
        scale: hidden ? 0.0 : 1.0,
        duration: Duration(milliseconds: hidden ? 200 : 320),
        curve: hidden ? Curves.easeInBack : Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: hidden ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kBrand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kBrand.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -- Bottom bar dengan notch --
class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _BottomBar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            _item(Icons.home_outlined, Icons.home, 'Beranda', 0),
            _item(Icons.search_outlined, Icons.search, 'Cari', 1),
            Expanded(
              child: InkWell(
                onTap: () => onSelect(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Posting',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selectedIndex == 2 ? FontWeight.w700 : FontWeight.normal,
                        color: selectedIndex == 2 ? kBrand : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            _item(Icons.assignment_outlined, Icons.assignment, 'Kebutuhan', 3),
            _item(Icons.person_outline, Icons.person, 'Akun', 4),
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
            Icon(sel ? selIcon : icon, color: sel ? kBrand : Colors.grey[600], size: 24),
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
