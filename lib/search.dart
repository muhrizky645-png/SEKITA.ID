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

  List<Mitra> _filter(List<Mitra> all) {
    final q = _query.trim().toLowerCase();
    return all.where((m) {
      final okCat = _category == null || m.kategori.toLowerCase() == _category!.toLowerCase();
      final okQ = q.isEmpty ||
          m.displayName.toLowerCase().contains(q) ||
          m.kategori.toLowerCase().contains(q) ||
          m.lokasi.toLowerCase().contains(q) ||
          m.deskripsi.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();
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
      body: Column(
        children: [
          _chips(),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Mitra>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text('Gagal memuat data.'));
                }
                final list = _filter(snap.data ?? []);
                if (list.isEmpty) {
                  return const Center(child: Text('Tidak ada mitra yang cocok.'));
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: list.map((m) => MitraCard(m: m, onTap: () => _openDetail(m))).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chip('Semua', _category == null, () => setState(() => _category = null)),
          ...Api.kategoriDasar.map(
            (c) => _chip(c, _category == c, () => setState(() => _category = c)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: kBrand,
        labelStyle: TextStyle(color: active ? Colors.white : kInk, fontSize: 13),
        backgroundColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: active ? kBrand : const Color(0xFFE5E7EB))),
      ),
    );
  }
}
