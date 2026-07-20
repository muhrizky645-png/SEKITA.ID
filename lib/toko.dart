import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'mitra_api.dart';
import 'katalog.dart';
import 'notif_bell.dart';

const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);

/// Tab Detail Toko: etalase publik mitra + tombol edit (pp, sampul, tentang,
/// portofolio). Mirror halaman profil mitra di web.
class TokoScreen extends StatefulWidget {
  const TokoScreen({super.key});
  @override
  State<TokoScreen> createState() => _TokoScreenState();
}

class _TokoScreenState extends State<TokoScreen> {
  String _cover = '';
  List<String> _porto = [];
  List<Ulasan> _ulasan = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final cover = await MitraApi.ambilCover();
    final porto = await MitraApi.ambilPortfolio();
    final mid = '${Api.currentMitra?.id ?? 0}';
    final ulasan = mid == '0' ? <Ulasan>[] : await Api.fetchUlasan(mid);
    if (!mounted) return;
    setState(() {
      _cover = cover;
      _porto = porto;
      _ulasan = ulasan;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditTokoPage(cover: _cover, porto: _porto)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final m = Api.currentMitra;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Detail Toko', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          const MitraBell(),
          IconButton(onPressed: m == null ? null : _edit, icon: const Icon(Icons.edit_outlined), tooltip: 'Edit toko'),
          const SizedBox(width: 4),
        ],
      ),
      body: m == null
          ? const Center(child: Text('Belum login sebagai mitra.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _header(m),
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _aboutSection(m),
                        const SizedBox(height: 16),
                        _katalogNav(),
                        const SizedBox(height: 16),
                        _portoSection(),
                        const SizedBox(height: 16),
                        _ulasanSection(),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _edit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Toko'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _header(MitraAkun m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: _cover.isNotEmpty
              ? SekitaImage(_cover, fit: BoxFit.cover)
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [kBrand, kBrandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE5E7EB),
                  child: ClipOval(
                    child: m.avatar.isNotEmpty
                        ? SekitaImage(m.avatar, width: 64, height: 64, fit: BoxFit.cover)
                        : const Icon(Icons.storefront_rounded, size: 30, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(m.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        ),
                        if (m.isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified, size: 18, color: kBrand),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [if (m.kategori.isNotEmpty) m.kategori, if (m.lokasi.isNotEmpty) m.lokasi].join(' \u00b7 '),
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _katalogNav() {
    return _card(
      title: 'Katalog / Daftar Harga',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tampilkan layanan atau produk beserta harga di profilmu.',
              style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KatalogPage()),
              ),
              icon: const Icon(Icons.sell_outlined, size: 18),
              label: const Text('Kelola Katalog'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutSection(MitraAkun m) {
    final has = m.deskripsi.trim().isNotEmpty;
    return _card(
      title: 'Tentang',
      child: Text(
        has ? m.deskripsi : 'Belum ada deskripsi toko. Ketuk Edit Toko untuk menambahkan.',
        style: TextStyle(color: has ? const Color(0xFF334155) : _muted, fontSize: 13.5, height: 1.45),
      ),
    );
  }

  Widget _portoSection() {
    return _card(
      title: 'Portofolio',
      child: _porto.isEmpty
          ? const Text('Belum ada foto portofolio.', style: TextStyle(color: _muted, fontSize: 13))
          : GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
              children: _porto
                  .map((p) => ClipRRect(borderRadius: BorderRadius.circular(10), child: SekitaImage(p, fit: BoxFit.cover)))
                  .toList(),
            ),
    );
  }

  Widget _ulasanSection() {
    final avg = _ulasan.isEmpty ? 0.0 : _ulasan.map((u) => u.rating).reduce((a, b) => a + b) / _ulasan.length;
    return _card(
      title: 'Ulasan (${_ulasan.length})',
      child: _ulasan.isEmpty
          ? const Text('Belum ada ulasan.', style: TextStyle(color: _muted, fontSize: 13))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 4),
                    Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Text('dari ${_ulasan.length} ulasan', style: const TextStyle(color: _muted, fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 10),
                ..._ulasan.take(5).map((u) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(u.pembeliNama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(i < u.rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: const Color(0xFFF59E0B)),
                                ),
                              ),
                            ],
                          ),
                          if (u.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(u.text, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                          ],
                        ],
                      ),
                    )),
              ],
            ),
    );
  }
}

/// Halaman edit toko: pp, sampul, nama usaha, kategori, lokasi, tentang,
/// portofolio. Halaman penuh (bukan dialog) untuk hindari layar blank Android.
class EditTokoPage extends StatefulWidget {
  final String cover;
  final List<String> porto;
  const EditTokoPage({super.key, required this.cover, required this.porto});
  @override
  State<EditTokoPage> createState() => _EditTokoPageState();
}

class _EditTokoPageState extends State<EditTokoPage> {
  final _nama = TextEditingController();
  String _lokasiVal = '';
  final _desk = TextEditingController();
  late String _indukKey;
  late String _subChoice;
  String _avatar = '';
  String _cover = '';
  List<String> _porto = [];
  bool _avatarChanged = false;
  bool _coverChanged = false;
  bool _portoChanged = false;
  bool _saving = false;
  List<MitraItem> _items = [];
  bool _itemsLoading = true;

  @override
  void initState() {
    super.initState();
    final m = Api.currentMitra;
    _nama.text = m?.namaUsaha ?? '';
    _lokasiVal = m?.lokasi ?? '';
    _desk.text = m?.deskripsi ?? '';
    final k = (m?.kategori ?? '').trim();
    final canon = canonicalCat(k);
    final ik = indukKeyOf(k);
    _indukKey = ik.isNotEmpty ? ik : sekitaTaxonomy.first.key;
    final ind0 = indukByKey(_indukKey) ?? sekitaTaxonomy.first;
    if (k.isEmpty) {
      _subChoice = ind0.subs.isNotEmpty ? ind0.subs.first : 'Lainnya';
    } else if (isSpecificSub(canon)) {
      _subChoice = canon;
    } else {
      _subChoice = 'Lainnya';
    }
    _cover = widget.cover;
    _porto = List<String>.from(widget.porto);
    _loadItems();
  }

  @override
  void dispose() {
    _nama.dispose();
    _desk.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await MitraApi.ambilItemSaya();
    if (!mounted) return;
    setState(() {
      _items = items;
      _itemsLoading = false;
    });
  }

  Future<void> _kelolaKatalog() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KatalogPage()),
    );
    _loadItems();
  }

  Widget _katalogEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Katalog / Daftar Harga',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const Spacer(),
            if (!_itemsLoading)
              Text('${_items.length} item',
                  style: const TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        if (_itemsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (_items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            child: const Text(
              'Belum ada item katalog. Tambahkan layanan atau produk beserta harganya.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
            ),
          )
        else
          Column(children: _items.map(_katalogRow).toList()),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.tonalIcon(
            onPressed: _kelolaKatalog,
            icon: const Icon(Icons.sell_outlined, size: 18),
            label: Text(_items.isEmpty ? 'Tambah / Kelola Katalog' : 'Kelola Katalog'),
          ),
        ),
      ],
    );
  }

  Widget _katalogRow(MitraItem it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (it.foto.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 46, height: 46, child: SekitaImage(it.foto, fit: BoxFit.cover)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(it.judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                    if (!it.isAktif)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text('Nonaktif', style: TextStyle(color: _muted, fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  it.jenisLabel + ' · ' + it.hargaLabel + (it.satuan.isNotEmpty ? ' / ' + it.satuan : ''),
                  style: const TextStyle(color: kBrand, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pick({required int w, required int h, required int q}) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (src == null) return null;
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: w.toDouble(), maxHeight: h.toDouble(), imageQuality: q);
      if (x == null) return null;
      final bytes = await x.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAvatar() async {
    final d = await _pick(w: 480, h: 480, q: 82);
    if (d == null) return;
    setState(() {
      _avatar = d;
      _avatarChanged = true;
    });
  }

  Future<void> _pickCover() async {
    final d = await _pick(w: 1280, h: 520, q: 72);
    if (d == null) return;
    setState(() {
      _cover = d;
      _coverChanged = true;
    });
  }

  Future<void> _addPorto() async {
    if (_porto.length >= 6) {
      _msg('Maksimal 6 foto portofolio.');
      return;
    }
    final d = await _pick(w: 1000, h: 1000, q: 62);
    if (d == null) return;
    setState(() {
      _porto.add(d);
      _portoChanged = true;
    });
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: error ? const Color(0xFFDC2626) : null));
  }

  String get _kategoriValue {
    final ind = indukByKey(_indukKey);
    if (ind == null) return _subChoice;
    return _subChoice == 'Lainnya' ? ind.name : _subChoice;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_nama.text.trim().isEmpty) {
      _msg('Nama usaha wajib diisi.', error: true);
      return;
    }
    setState(() => _saving = true);
    final p = await MitraApi.simpanProfil(
      namaUsaha: _nama.text.trim(),
      kategori: _kategoriValue,
      lokasi: _lokasiVal.trim(),
      deskripsi: _desk.text.trim(),
    );
    if (!p.ok) {
      _fail(p.error);
      return;
    }
    if (_avatarChanged && _avatar.isNotEmpty) {
      final a = await MitraApi.simpanAvatar(_avatar);
      if (!a.ok) {
        _fail(a.error);
        return;
      }
    }
    if (_coverChanged && _cover.isNotEmpty) {
      final c = await MitraApi.simpanCover(_cover);
      if (!c.ok) {
        _fail(c.error);
        return;
      }
    }
    if (_portoChanged) {
      final f = await MitraApi.simpanPortfolio(_porto);
      if (!f.ok) {
        _fail(f.error);
        return;
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    _msg('Profil toko tersimpan.');
    Navigator.pop(context, true);
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() => _saving = false);
    _msg(msg, error: true);
  }

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _line)),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Edit Toko'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Simpan'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          _coverEditor(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _avatarEditor()),
                const SizedBox(height: 6),
                const Center(child: Text('Foto profil', style: TextStyle(color: _muted, fontSize: 12))),
                const SizedBox(height: 18),
                _label('Nama usaha'),
                TextField(controller: _nama, decoration: _dec('Nama usaha')),
                const SizedBox(height: 14),
                _label('Kategori'),
                DropdownButtonFormField<String>(
                  value: _indukKey,
                  isExpanded: true,
                  decoration: _dec(null),
                  items: sekitaTaxonomy
                      .map((ind) => DropdownMenuItem<String>(value: ind.key, child: Text(ind.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _indukKey = v ?? _indukKey;
                    final ind = indukByKey(_indukKey);
                    _subChoice = (ind != null && ind.subs.isNotEmpty) ? ind.subs.first : 'Lainnya';
                  }),
                ),
                const SizedBox(height: 14),
                _label('Layanan'),
                DropdownButtonFormField<String>(
                  value: _subChoice,
                  isExpanded: true,
                  decoration: _dec(null),
                  items: <DropdownMenuItem<String>>[
                    ...?indukByKey(_indukKey)?.subs.map((s) => DropdownMenuItem<String>(value: s, child: Text(s, overflow: TextOverflow.ellipsis))),
                    const DropdownMenuItem<String>(value: 'Lainnya', child: Text('Lainnya (umum)')),
                  ],
                  onChanged: (v) => setState(() => _subChoice = v ?? _subChoice),
                ),
                const SizedBox(height: 14),
                _label('Lokasi'),
                WilayahField(
                  initial: _lokasiVal,
                  onChanged: (v) => _lokasiVal = v,
                  decoration: (label, hint) => _dec(hint),
                ),
                const SizedBox(height: 14),
                _label('Tentang / deskripsi'),
                TextField(controller: _desk, maxLines: 5, decoration: _dec('Ceritakan layanan tokomu...')),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text('Portofolio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const Spacer(),
                    Text('${_porto.length}/6', style: const TextStyle(color: _muted, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                _portoEditor(),
                const SizedBox(height: 22),
                _katalogEditor(),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverEditor() {
    final has = _cover.isNotEmpty;
    return GestureDetector(
      onTap: _pickCover,
      child: Stack(
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: has
                ? SekitaImage(_cover, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [kBrand, kBrandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                  ),
          ),
          Positioned(right: 12, bottom: 12, child: _camBadge('Ganti sampul')),
        ],
      ),
    );
  }

  Widget _camBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _avatarEditor() {
    final src = _avatarChanged ? _avatar : (Api.currentMitra?.avatar ?? '');
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: const Color(0xFFE5E7EB),
            child: ClipOval(
              child: src.isNotEmpty
                  ? SekitaImage(src, width: 92, height: 92, fit: BoxFit.cover)
                  : const Icon(Icons.storefront_rounded, size: 40, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: kBrand, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _portoEditor() {
    final tiles = <Widget>[];
    for (var i = 0; i < _porto.length; i++) {
      final idx = i;
      final p = _porto[i];
      tiles.add(Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 90, height: 90, child: SekitaImage(p, fit: BoxFit.cover))),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => setState(() {
                _porto.removeAt(idx);
                _portoChanged = true;
              }),
              child: Container(
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.close, color: Colors.white, size: 15),
              ),
            ),
          ),
        ],
      ));
    }
    if (_porto.length < 6) {
      tiles.add(GestureDetector(
        onTap: _addPorto,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: _line)),
          child: const Icon(Icons.add_a_photo_outlined, color: _muted),
        ),
      ));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: tiles);
  }
}
