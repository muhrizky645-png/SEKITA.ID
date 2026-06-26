import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'home.dart';
import 'search.dart';
import 'kebutuhan.dart';
import 'post.dart';
import 'akun.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.initDeviceId();
  runApp(const SekitaApp());
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
  // 0=Beranda 1=Cari 2=Posting(FAB) 3=Kebutuhan 4=Akun
  int _i = 0;

  void _go(int v) => setState(() => _i = v);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
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
}

// ── FAB tengah (tombol Posting) ─ disembunyikan dengan animasi saat di tab Posting ─
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

// ── Bottom bar dengan notch ───────────────────────────────────
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
            // ruang + label FAB
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
            Icon(sel ? selIcon : icon,
                color: sel ? kBrand : Colors.grey[600], size: 24),
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
