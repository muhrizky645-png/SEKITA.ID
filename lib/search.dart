import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'widgets.dart';
import 'detail.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  final bool autofocus;
  const SearchScreen({super.key, this.initialCategory, this.autofocus = false});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Mitra>> _future;
  final _ctrl = TextEditingController();
  String _query = '';
  String? _category;
  String? _loc;
  bool _trusted = false;
  bool _topRated = false;
  String _sort = 'rekomendasi';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _future = Api.fetchMitra();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Samakan dgn web: semua kategori diawali "Lainnya" digabung jadi satu.
  String _catKey(String c) {
    final t = c.trim();
    return RegExp(r'^lainnya', caseSensitive: false).hasMatch(t) ? 'Lainnya' : t;
  }

  bool _catMatch(Mitra m) {
    if (_category == null) return true;
    final key = _catKey(m.kategori);
    final sel = _category!.toLowerCase();
    return key == _category ||
        key.toLowerCase().startsWith(sel) ||
        m.kategori.toLowerCase().startsWith(sel);
  }

  List<Mitra> _apply(List<Mitra> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((m) {
      final okQ = q.isEmpty ||
          m.displayName.toLowerCase().contains(q) ||
          m.kategori.toLowerCase().contains(q) ||
          m.lokasi.toLowerCase().contains(q) ||
          m.deskripsi.toLowerCase().contains(q);
      final okLoc = _loc == null || m.lokasi == _loc;
      final okTrust = !_trusted || m.verified >= 1;
      final okTop = !_topRated || m.rating >= 4.5;
      return _catMatch(m) && okQ && okLoc && okTrust && okTop;
    }).toList();

    switch (_sort) {
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'verif':
        list.sort((a, b) {
          final c = b.verified.compareTo(a.verified);
          return c != 0 ? c : b.rating.compareTo(a.rating);
        });
        break;
      case 'nama':
        list.sort((a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        break;
      default:
        // Rekomendasi: sponsor (paket kategori/bundle) naik, lalu verifikasi,
        // lalu rating. Selaras dgn sortPromoted('kategori') di web.
        list.sort((a, b) {
          final sa = sponsorOn(a, 'kategori') ? 1 : 0;
          final sb = sponsorOn(b, 'kategori') ? 1 : 0;
          if (sa != sb) return sb - sa;
          final v = b.verified.compareTo(a.verified);
          if (v != 0) return v;
          return b.rating.compareTo(a.rating);
        });
    }
    return list;
  }

  void _openDetail(Mitra m) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MitraDetailScreen(mitra: m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.initialCategory != null,
        title: TextField(
          controller: _ctrl,
          autofocus: widget.autofocus,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Cari jasa atau mitra...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: FutureBuilder<List<Mitra>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Gagal memuat data.'));
          }
          final all = snap.data ?? [];

          final counts = <String, int>{};
          for (final m in all) {
            final k = _catKey(m.kategori);
            counts[k] = (counts[k] ?? 0) + 1;
          }
          final cats = counts.keys.toList()
            ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
          final locs = all
              .map((m) => m.lokasi.trim())
              .where((l) => l.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final list = _apply(all);

          return Column(
            children: [
              _categoryBar(cats, counts, all.length),
              _filterBar(locs),
              _resultBar(list.length),
              const Divider(height: 1),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Tidak ada mitra yang cocok.'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => MitraCard(
                            m: list[i],
                            surface: 'kategori',
                            onTap: () => _openDetail(list[i])),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Bar kategori dengan icon + jumlah
  Widget _categoryBar(List<String> cats, Map<String, int> counts, int total) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _catChip(
            label: 'Semua',
            icon: Icon(Icons.public,
                size: 16, color: _category == null ? Colors.white : kBrand),
            count: total,
            active: _category == null,
            onTap: () => setState(() => _category = null),
          ),
          ...cats.map((c) {
            final active = _category == c;
            return _catChip(
              label: c,
              icon: SizedBox(
                width: 16,
                height: 16,
                child: SekitaImage(catIconPath(c), fit: BoxFit.contain),
              ),
              count: counts[c] ?? 0,
              active: active,
              onTap: () => setState(() => _category = active ? null : c),
            );
          }),
        ],
      ),
    );
  }

  Widget _catChip({
    required String label,
    required Widget icon,
    required int count,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? kBrand : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: active ? kBrand : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : kInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withOpacity(0.25)
                      : const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$count',
                    style: TextStyle(
                        color: active ? Colors.white : kBrand,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bar filter cepat + lokasi
  Widget _filterBar(List<String> locs) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _toggle(Icons.verified_user_outlined, 'Tepercaya', _trusted,
              () => setState(() => _trusted = !_trusted)),
          _toggle(Icons.star_outline, 'Rating 4.5+', _topRated,
              () => setState(() => _topRated = !_topRated)),
          _locChip(locs),
        ],
      ),
    );
  }

  Widget _toggle(IconData ic, String label, bool active, VoidCallback onTap) {
    final c = active ? kBrand : kInk;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? kBrand.withOpacity(0.10) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: active ? kBrand : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ic, size: 15, color: c),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: c, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locChip(List<String> locs) {
    final active = _loc != null;
    final c = active ? kBrand : kInk;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        onSelected: (v) => setState(() => _loc = v.isEmpty ? null : v),
        itemBuilder: (_) => [
          const PopupMenuItem(value: '', child: Text('Semua lokasi')),
          ...locs.map((l) => PopupMenuItem(value: l, child: Text(l))),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? kBrand.withOpacity(0.10) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: active ? kBrand : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 15, color: c),
              const SizedBox(width: 5),
              Text(_loc ?? 'Lokasi',
                  style: TextStyle(
                      color: c, fontSize: 12.5, fontWeight: FontWeight.w600)),
              Icon(Icons.arrow_drop_down, size: 18, color: c),
            ],
          ),
        ),
      ),
    );
  }

  // Baris jumlah hasil + urutkan
  Widget _resultBar(int n) {
    const labels = {
      'rekomendasi': 'Rekomendasi',
      'rating': 'Rating tertinggi',
      'verif': 'Paling terverifikasi',
      'nama': 'Nama A-Z',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text('$n penyedia ditemukan',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => labels.entries
                .map((e) => CheckedPopupMenuItem<String>(
                      value: e.key,
                      checked: _sort == e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_vert, size: 18, color: kBrand),
                const SizedBox(width: 3),
                Text('Urutkan',
                    style: TextStyle(
                        color: kBrand,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const Icon(Icons.arrow_drop_down, size: 18, color: kBrand),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
