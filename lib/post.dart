import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';

class PostKebutuhanScreen extends StatefulWidget {
  const PostKebutuhanScreen({super.key});
  @override
  State<PostKebutuhanScreen> createState() => _PostKebutuhanScreenState();
}

class _PostKebutuhanScreenState extends State<PostKebutuhanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _lokasi = TextEditingController();
  final _deskripsi = TextEditingController();
  final _budget = TextEditingController();
  final _wa = TextEditingController();
  final _nama = TextEditingController();
  String _kategori = Api.kategoriDasar.first;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _lokasi.dispose();
    _deskripsi.dispose();
    _budget.dispose();
    _wa.dispose();
    _nama.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final ok = await Api.postKebutuhan(
      title: _title.text.trim(),
      kategori: _kategori,
      lokasi: _lokasi.text.trim(),
      deskripsi: _deskripsi.text.trim(),
      budget: _budget.text.trim(),
      wa: _wa.text.trim(),
      pembeliNama: _nama.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _formKey.currentState!.reset();
      _title.clear();
      _lokasi.clear();
      _deskripsi.clear();
      _budget.clear();
      _wa.clear();
      _nama.clear();
      setState(() => _kategori = Api.kategoriDasar.first);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Berhasil! 🎉'),
          content: const Text(
              'Kebutuhanmu sudah diposting. Mitra yang sesuai akan menghubungimu lewat WhatsApp.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Oke')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posting Kebutuhan')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Ceritakan jasa yang kamu butuhkan, mitra terkait akan dapat notifikasi.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              _field(_title, 'Judul kebutuhan *', hint: 'cth: Servis AC tidak dingin', required: true),
              const SizedBox(height: 12),
              _dropdown(),
              const SizedBox(height: 12),
              _field(_lokasi, 'Lokasi *', hint: 'cth: Sleman, Yogyakarta', required: true),
              const SizedBox(height: 12),
              _field(_deskripsi, 'Deskripsi', hint: 'Jelaskan detailnya...', maxLines: 4),
              const SizedBox(height: 12),
              _field(_budget, 'Perkiraan budget', hint: 'cth: Rp100.000 - 200.000'),
              const SizedBox(height: 12),
              _field(_wa, 'Nomor WhatsApp', hint: '08xxxx', keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_nama, 'Nama kamu', hint: 'cth: Budi'),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Posting Kebutuhan',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, int maxLines = 1, bool required = false, TextInputType? keyboard}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dropdown() {
    return DropdownButtonFormField<String>(
      value: _kategori,
      decoration: InputDecoration(
        labelText: 'Kategori',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: Api.kategoriDasar.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _kategori = v ?? _kategori),
    );
  }
}
