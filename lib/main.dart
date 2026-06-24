import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'home.dart';
import 'search.dart';
import 'kebutuhan.dart';
import 'post.dart';

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
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const SearchScreen(),
      const KebutuhanScreen(),
      const PostKebutuhanScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _i, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Cari'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Kebutuhan'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Posting'),
        ],
      ),
    );
  }
}
