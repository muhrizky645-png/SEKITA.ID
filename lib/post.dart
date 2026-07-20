import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'core.dart';

const Color _kOrange = Color(0xFFF97316);
const Color _kLine = Color(0xFFE2E8F0);
const Color _kMuted = Color(0xFF64748B);
const Color _kHint = Color(0xFF94A3B8);

class _CatOpt {
  final String name;
  final String emoji;
  final String bgHex;
  const _CatOpt(this.name, this.emoji, this.bgHex);
}

const List<_CatOpt> _cats = [
  _CatOpt('Terapis', '\u{1F486}', '#ecfdf5'),
  _CatOpt('Tukang', '\u{1F528}', '#fffbeb'),
  _CatOpt('Transportasi', '\u{1F697}', '#eff6ff'),
  _CatOpt('Servis AC', '\u2744\uFE0F', '#f0f9ff'),
  _CatOpt('Kebersihan', '\u{1F9F9}', '#f0f9ff'),
  _CatOpt('Les Privat', '\u{1F4DA}', '#eef2ff'),
  _CatOpt('Fotografer', '\u{1F4F7}', '#eef2ff'),
  _CatOpt('MUA', '\u{1F484}', '#fdf2f8'),
  _CatOpt('Lainnya', '\u{1F9F0}', '#f1f5f9'),
];

const List<String> _lokasiOpts = [
  'Kota Yogyakarta',
  'Sleman, Yogyakarta',
  'Bantul, Yogyakarta',
  'Kulon Progo, Yogyakarta',
  'Gunungkidul, Yogyakarta',
];

const List<String> _waktuOpts = [
  'Secepatnya',
  'Hari ini',
  'Minggu ini',
  'Bulan ini',
  'Tanggal tertentu (jelaskan di deskripsi)',
];

String _groupThousands(String digits) {
  final b = StringBuffer();
  final n = digits.length;
  for (var i = 0; i < n; i++) {
    if (i > 0 && (n - i) % 3 == 0) b.write('.');
    b.write(digits[i]);
  }
  return b.toString();
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final s = _groupThousands(digits);
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class PostKebutuhanScreen extends StatefulWidget {
  final void Function(int tab)? onGoTab;
  const PostKebutuhanScreen({super.key, this.onGoTab});
  @override
  State<PostKebutuhanScreen> createState() => _PostKebutuhanScreenState();
}

class _PostKebutuhanScreenState extends State<PostKebutuhanScreen> {
  final _title = TextEditingController();
  final _catOther = TextEditingController();
  final _deskripsi = TextEditingController();
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();
  final _wa = TextEditingController();

  String? _selectedCat;
  String? _selectedInduk;
  String? _selectedSub;
  String? _lokasi;
  int _wilGen = 0;
  String? _waktu;
  bool _budgetNego = false;
  bool _waLocked = false;
  bool _sending = false;

  bool _eCat = false, _eSub = false, _eCatOther = false, _eTitle = false, _eLokasi = false, _eWaktu = false, _eWa = false;

  @override
  void initState() {
    super.initState();
    _ensureSession();
  }

  // Saat app start, layar ini dibangun sekali (di IndexedStack) padahal me()
  // belum dipanggil. Pastikan sesi termuat supaya WA bisa terkunci dari akun.
  Future<void> _ensureSession() async {
    if (Api.currentUser == null) {
      try {
        await Api.me();
      } catch (_) {}
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _catOther.dispose();
    _deskripsi.dispose();
    _budgetMin.dispose();
    _budgetMax.dispose();
    _wa.dispose();
    super.dispose();
  }

  String _catLabel() {
    if (_selectedCat == 'Lainnya') {
      final v = _catOther.text.trim();
      return v.isNotEmpty ? 'Lainnya ($v)' : 'Lainnya';
    }
    return _selectedCat ?? '';
  }

  String _budgetText() {
    if (_budgetNego) return 'Nego';
    final mn = _budgetMin.text.trim();
    final mx = _budgetMax.text.trim();
    if (mn.isNotEmpty && mx.isNotEmpty) return 'Rp$mn \u2013 Rp$mx';
    if (mn.isNotEmpty) return 'Mulai Rp$mn';
    if (mx.isNotEmpty) return 's/d Rp$mx';
    return 'Nego';
  }

  // Pembeli yang sudah login tapi belum terverifikasi tidak bisa posting
  // (mirror gate di web). Tampilkan popup ramah yang mengarahkan ke tab Akun.
  bool _needVerif() {
    final u = Api.currentUser;
    return u != null && u.verified != 1;
  }

  void _showVerifGate() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('\ud83d\udd12', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Verifikasi akun dulu, yuk',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ),
          ],
        ),
        content: const Text(
          'Akun pembelimu belum terverifikasi. Verifikasi email & nomor WhatsApp dulu di halaman Akun supaya kamu bisa posting kebutuhan dan dapat badge \u2714 Terverifikasi. Tenang, prosesnya cepat kok \ud83d\ude4c',
          style: TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF475569)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Nanti saja'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kOrange),
            onPressed: () {
              Navigator.pop(c);
              widget.onGoTab?.call(4);
            },
            child: const Text('Ke Halaman Verifikasi'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_needVerif()) {
      _showVerifGate();
      return;
    }
    final waDigits = _wa.text.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _eCat = _selectedInduk == null;
      _eSub = _selectedInduk != null && _selectedSub == null;
      _eCatOther = _selectedSub == 'Lainnya' && _catOther.text.trim().isEmpty;
      _eTitle = _title.text.trim().isEmpty;
      _eLokasi = _lokasi == null;
      _eWaktu = _waktu == null;
      _eWa = waDigits.length < 9;
    });
    if (_eCat || _eSub || _eCatOther || _eTitle || _eLokasi || _eWaktu || _eWa) return;

    setState(() => _sending = true);
    final ind = indukByKey(_selectedInduk ?? '');
    final emoji = ind?.emoji ?? '';
    final extra = _selectedSub == 'Lainnya' ? _catOther.text.trim() : '';
    final desk = _deskripsi.text.trim();
    final fullDesk = extra.isEmpty ? desk : (desk.isEmpty ? 'Kebutuhan: ' + extra : desk + '  |  Kebutuhan: ' + extra);
    final catVal = (ind == null) ? '' : ((_selectedSub == 'Lainnya' || _selectedSub == null) ? ind.name : _selectedSub!);
    final ok = await Api.postKebutuhan(
      title: _title.text.trim(),
      kategori: catVal,
      lokasi: _lokasi ?? '',
      deskripsi: fullDesk,
      budget: _budgetText(),
      wa: _wa.text.trim(),
      waktu: _waktu ?? '',
      ic: emoji,
      bg: '#eff6ff',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim. Coba lagi.')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _title.clear();
      _catOther.clear();
      _deskripsi.clear();
      _budgetMin.clear();
      _budgetMax.clear();
      _selectedCat = null;
      _selectedInduk = null;
      _selectedSub = null;
      _lokasi = null;
      _wilGen++;
      _waktu = null;
      _budgetNego = false;
      _eCat = _eSub = _eCatOther = _eTitle = _eLokasi = _eWaktu = _eWa = false;
      if (!_waLocked) _wa.clear();
    });
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u{1F389}', style: TextStyle(fontSize: 46)),
              const SizedBox(height: 8),
              const Text('Kebutuhanmu sudah tayang!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'Penyedia jasa terverifikasi di sekitarmu akan segera menghubungi via WhatsApp. Pantau terus, ya!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetForm();
                      },
                      child: const Text('Posting lagi'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _kOrange),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetForm();
                        widget.onGoTab?.call(0);
                      },
                      child: const Text('Selesai'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sinkronkan status kunci WA tiap build supaya tetap akurat walau user baru
    // login setelah layar ini dibangun (IndexedStack mempertahankan state).
    final u = Api.currentUser;
    final uw = (u != null) ? u.wa.trim() : '';
    _waLocked = uw.isNotEmpty;
    if (_waLocked && _wa.text != uw) {
      _wa.text = uw;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Posting Kebutuhan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                const Text('Posting Kebutuhan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Text('\u2728 Gratis',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Tinggal isi kebutuhanmu, biarkan penyedia jasa yang menghubungi. Nggak perlu daftar.',
                style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
            const SizedBox(height: 20),
            _label('Kategori', required: true),
            const SizedBox(height: 8),
            Wrap(spacing: 9, runSpacing: 9, children: sekitaTaxonomy.map(_indukPill).toList()),
            if (_eCat) _errText('Pilih kategori dulu ya.'),
            if (_selectedInduk != null) ...[
              const SizedBox(height: 16),
              _label('Layanan yang dibutuhkan', required: true),
              const SizedBox(height: 8),
              Wrap(spacing: 9, runSpacing: 9, children: _subPills()),
              if (_eSub) _errText('Pilih layanan dulu ya.'),
            ],
            if (_selectedSub == 'Lainnya') ...[
              const SizedBox(height: 16),
              _label('Sebutkan kebutuhanmu', required: true),
              const SizedBox(height: 7),
              _input(_catOther, hint: 'Contoh: sesuatu yang belum ada di daftar', maxLength: 40),
              if (_eCatOther) _errText('Tulis dulu kebutuhan spesifikmu ya.'),
            ],
            const SizedBox(height: 16),
            _label('Judul kebutuhan', required: true),
            const SizedBox(height: 7),
            _input(_title, hint: 'Contoh: Butuh Fotografer Wisuda', maxLength: 70,
                onChanged: (_) { if (_eTitle) setState(() => _eTitle = false); }),
            if (_eTitle) _errText('Isi judul kebutuhanmu.'),
            const SizedBox(height: 16),
            _label('Lokasi', required: true),
            const SizedBox(height: 7),
            WilayahField(
              key: ValueKey('wil_' + _wilGen.toString()),
              initial: _lokasi ?? '',
              onChanged: (v) => setState(() {
                _lokasi = v.isEmpty ? null : v;
                _eLokasi = false;
              }),
              decoration: (label, hint) => _dec(hint: hint),
            ),
            if (_eLokasi) _errText('Pilih lokasi kamu.'),
            const SizedBox(height: 16),
            _labelHint('Perkiraan budget', '(boleh dikosongi kalau masih nego)'),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: _money(_budgetMin, 'Min')),
              const SizedBox(width: 12),
              Expanded(child: _money(_budgetMax, 'Maks')),
            ]),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() {
                _budgetNego = !_budgetNego;
                if (_budgetNego) { _budgetMin.clear(); _budgetMax.clear(); }
              }),
              child: Row(children: [
                Checkbox(
                  value: _budgetNego,
                  onChanged: (v) => setState(() {
                    _budgetNego = v ?? false;
                    if (_budgetNego) { _budgetMin.clear(); _budgetMax.clear(); }
                  }),
                ),
                const Text('Belum tahu / nego aja',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF475569))),
              ]),
            ),
            const SizedBox(height: 4),
            _label('Kapan dibutuhkan?', required: true),
            const SizedBox(height: 7),
            _dropdown(
              value: _waktu,
              hint: 'Pilih waktu\u2026',
              items: _waktuOpts,
              onChanged: (v) => setState(() { _waktu = v; _eWaktu = false; }),
            ),
            if (_eWaktu) _errText('Pilih kapan kamu butuh jasanya.'),
            const SizedBox(height: 16),
            _labelHint('Deskripsi', '(opsional, tapi bikin penawaran lebih pas)'),
            const SizedBox(height: 7),
            _input(_deskripsi, hint: 'Ceritakan detail: jumlah, durasi, lokasi spesifik, dll.', maxLines: 4),
            const SizedBox(height: 16),
            _label('Nomor WhatsApp kamu', required: true),
            const SizedBox(height: 7),
            _input(_wa, hint: '08xxxxxxxxxx', keyboard: TextInputType.phone, readOnly: _waLocked,
                onChanged: (_) { if (_eWa) setState(() => _eWa = false); }),
            if (_waLocked)
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: Text('\ud83d\udd12 Nomor terkunci dari akunmu yang sudah terverifikasi.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
              )
            else
              _note('Nomormu disembunyikan di feed. Cuma penyedia jasa terverifikasi yang bisa buka kontakmu \u2014 jadi aman dari spam.'),
            if (_eWa) _errText('Isi nomor WhatsApp yang aktif.'),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _kOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Posting Sekarang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indukPill(KategoriInduk ind) {
    final active = _selectedInduk == ind.key;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() {
        _selectedInduk = ind.key;
        _selectedSub = null;
        _eCat = false;
        _eSub = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(color: active ? kBrand : _kLine),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SekitaImage(catIconPath(ind.name), width: 18, height: 18, fit: BoxFit.contain),
            const SizedBox(width: 7),
            Text(ind.name,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: active ? kBrand : const Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  List<Widget> _subPills() {
    final ind = indukByKey(_selectedInduk ?? '');
    if (ind == null) return const [];
    final subs = <String>[...ind.subs, 'Lainnya'];
    return subs.map((s) {
      final active = _selectedSub == s;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() {
          _selectedSub = s;
          _eSub = false;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : Colors.white,
            border: Border.all(color: active ? kBrand : _kLine),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(s,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? kBrand : const Color(0xFF334155))),
        ),
      );
    }).toList();
  }

  Widget _catPill(_CatOpt c) {
    final active = _selectedCat == c.name;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() {
        _selectedCat = c.name;
        _eCat = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(color: active ? kBrand : _kLine),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SekitaImage(catIconPath(c.name), width: 18, height: 18, fit: BoxFit.contain),
            const SizedBox(width: 7),
            Text(c.name,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: active ? kBrand : const Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Text.rich(TextSpan(
      text: text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk),
      children: required ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : const [],
    ));
  }

  Widget _labelHint(String text, String hint) {
    return Text.rich(TextSpan(
      text: text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk),
      children: [
        TextSpan(text: '  $hint',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: _kMuted)),
      ],
    ));
  }

  Widget _errText(String t) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(t, style: const TextStyle(fontSize: 12.5, color: Color(0xFFEF4444))),
      );

  InputDecoration _dec({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kHint),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kLine)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBrand, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kLine)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _input(TextEditingController c,
      {String? hint, int maxLines = 1, int? maxLength, TextInputType? keyboard, bool readOnly = false, void Function(String)? onChanged}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboard,
      readOnly: readOnly,
      onChanged: onChanged,
      style: readOnly ? const TextStyle(color: Color(0xFF475569)) : null,
      decoration: _dec(hint: hint).copyWith(counterText: ''),
    );
  }

  Widget _money(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      enabled: !_budgetNego,
      keyboardType: TextInputType.number,
      inputFormatters: [_ThousandsFormatter()],
      decoration: _dec(hint: hint).copyWith(
        prefixText: 'Rp ',
        prefixStyle: const TextStyle(color: _kMuted, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _dropdown({required String? value, required String hint, required List<String> items, required void Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(color: _kHint)),
      decoration: _dec(),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _note(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('\ud83d\udd12', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.4)),
          ),
        ],
      ),
    );
  }
}
