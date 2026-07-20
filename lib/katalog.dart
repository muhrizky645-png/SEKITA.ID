import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'core.dart';
import 'models.dart';
import 'mitra_api.dart';

const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);

/// Halaman kelola Katalog / Daftar Harga milik mitra (tambah, edit, hapus).
/// Mirror fitur "Katalog / Daftar Harga" di web (tabel mitra_item).
class KatalogPage extends StatefulWidget {
  const KatalogPage({super.key});
  @override
  State<KatalogPage> createState() => _KatalogPageState();
}

class _KatalogPageState extends State<KatalogPage> {
  List<MitraItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final items = await MitraApi.ambilItemSaya();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? const Color(0xFFDC2626) : null),
    );
  }

  Future<void> _openForm({MitraItem? item}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ItemForm(item: item),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _hapus(MitraItem item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus item?'),
        content: Text('"${item.judul}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final r = await MitraApi.hapusItem(item.id);
    if (!r.ok) {
      _msg(r.error, error: true);
      return;
    }
    _msg('Item dihapus.');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Katalog / Daftar Harga', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah item'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 110),
                      Icon(Icons.sell_outlined, size: 46, color: _muted),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Belum ada item. Tambahkan layanan atau produk beserta harganya agar calon pelanggan langsung tahu tarifmu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, height: 1.45),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _itemCard(_items[i]),
                  ),
      ),
    );
  }

  Widget _itemCard(MitraItem it) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (it.foto.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 64, height: 64, child: SekitaImage(it.foto, fit: BoxFit.cover)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _tag(it.jenisLabel),
                    if (!it.isAktif) ...[
                      const SizedBox(width: 6),
                      _tag('Nonaktif', muted: true),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(it.judul, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  it.hargaLabel + (it.satuan.isNotEmpty ? ' / ${it.satuan}' : ''),
                  style: const TextStyle(color: kBrand, fontWeight: FontWeight.w800),
                ),
                if (it.deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(it.deskripsi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.4)),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _openForm(item: it),
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: () => _hapus(it),
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String s, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF1F5F9) : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(s,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted ? _muted : kBrand)),
    );
  }
}

class _ItemForm extends StatefulWidget {
  final MitraItem? item;
  const _ItemForm({this.item});
  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _judul = TextEditingController();
  final _harga = TextEditingController();
  final _satuan = TextEditingController();
  final _stok = TextEditingController();
  final _desk = TextEditingController();
  String _jenis = 'jasa';
  String _hargaTipe = 'pasti';
  String _foto = '';
  bool _aktif = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    if (it != null) {
      _judul.text = it.judul;
      _harga.text = it.harga > 0 ? '${it.harga}' : '';
      _satuan.text = it.satuan;
      _stok.text = it.stok != null ? '${it.stok}' : '';
      _desk.text = it.deskripsi;
      _jenis = it.jenis;
      _hargaTipe = it.hargaTipe;
      _foto = it.foto;
      _aktif = it.isAktif;
    }
  }

  @override
  void dispose() {
    _judul.dispose();
    _harga.dispose();
    _satuan.dispose();
    _stok.dispose();
    _desk.dispose();
    super.dispose();
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? const Color(0xFFDC2626) : null),
    );
  }

  Future<void> _pickFoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
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
    if (src == null) return;
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1000, maxHeight: 1000, imageQuality: 70);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() => _foto = 'data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (_) {
      _msg('Gagal memuat foto.', error: true);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final judul = _judul.text.trim();
    if (judul.length < 2) {
      _msg('Judul item minimal 2 karakter.', error: true);
      return;
    }
    final harga = _hargaTipe == 'nego'
        ? 0
        : (int.tryParse(_harga.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
    if (_hargaTipe != 'nego' && harga <= 0) {
      _msg('Isi harga, atau pilih tipe "Nego".', error: true);
      return;
    }
    int? stok;
    if (_jenis == 'barang' && _stok.text.trim().isNotEmpty) {
      stok = int.tryParse(_stok.text.trim());
    }
    setState(() => _saving = true);
    final r = await MitraApi.simpanItem(
      id: widget.item?.id,
      jenis: _jenis,
      judul: judul,
      harga: harga,
      hargaTipe: _hargaTipe,
      satuan: _satuan.text.trim(),
      stok: stok,
      foto: _foto,
      deskripsi: _desk.text.trim(),
      aktif: _aktif,
    );
    if (!mounted) return;
    if (!r.ok) {
      setState(() => _saving = false);
      _msg(r.error, error: true);
      return;
    }
    Navigator.pop(context, true);
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBrand)),
      );

  Widget _lbl(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      );

  @override
  Widget build(BuildContext context) {
    final isNego = _hargaTipe == 'nego';
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.item == null ? 'Tambah Item' : 'Edit Item',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            _lbl('Foto (opsional)'),
            GestureDetector(
              onTap: _pickFoto,
              child: Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                child: _foto.isEmpty
                    ? const Icon(Icons.add_a_photo_outlined, color: _muted)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SekitaImage(_foto, fit: BoxFit.cover)),
              ),
            ),
            _lbl('Judul'),
            TextField(controller: _judul, decoration: _dec('Mis. Pijat 60 Menit')),
            _lbl('Jenis'),
            DropdownButtonFormField<String>(
              value: _jenis,
              isExpanded: true,
              decoration: _dec(''),
              items: const [
                DropdownMenuItem(value: 'jasa', child: Text('Jasa')),
                DropdownMenuItem(value: 'barang', child: Text('Barang')),
                DropdownMenuItem(value: 'paket', child: Text('Paket (jasa + barang)')),
              ],
              onChanged: (v) => setState(() => _jenis = v ?? _jenis),
            ),
            _lbl('Tipe harga'),
            DropdownButtonFormField<String>(
              value: _hargaTipe,
              isExpanded: true,
              decoration: _dec(''),
              items: const [
                DropdownMenuItem(value: 'pasti', child: Text('Harga pasti')),
                DropdownMenuItem(value: 'mulai_dari', child: Text('Mulai dari')),
                DropdownMenuItem(value: 'nego', child: Text('Nego')),
              ],
              onChanged: (v) => setState(() => _hargaTipe = v ?? _hargaTipe),
            ),
            if (!isNego) ...[
              _lbl('Harga (Rp)'),
              TextField(
                controller: _harga,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec('Mis. 125000'),
              ),
            ],
            _lbl('Satuan (opsional)'),
            TextField(controller: _satuan, decoration: _dec('Mis. sesi, jam, pcs')),
            if (_jenis == 'barang') ...[
              _lbl('Stok (opsional)'),
              TextField(
                controller: _stok,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec('Kosongkan bila tidak dilacak'),
              ),
            ],
            _lbl('Deskripsi (opsional)'),
            TextField(controller: _desk, maxLines: 3, decoration: _dec('Detail singkat item...')),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _aktif,
              onChanged: (v) => setState(() => _aktif = v),
              title: const Text('Tampilkan di profil',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Nonaktif = tersimpan tapi disembunyikan.',
                  style: TextStyle(color: _muted, fontSize: 12)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
