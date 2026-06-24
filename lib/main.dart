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

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const SearchScreen(),
      const PostKebutuhanScreen(),
      const KebutuhanScreen(),
      const AkunScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _i, children: pages),
      floatingActionButton: _PostingFab(
        selected: _i == 2,
        onTap: () => setState(() => _i = 2),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        selectedIndex: _i,
        onSelect: (v) => setState(() => _i = v),
      ),
    );
  }
}

// ── FAB tengah (tombol Posting) ──────────────────────────────────────────────
class _PostingFab extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _PostingFab({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: selected ? kBrandDark : kBrand,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kBrand.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          selected ? Icons.add_circle : Icons.add_circle_outline,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

// ── Bottom bar dengan notch ──────────────────────────────────────────────────
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
