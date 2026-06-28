import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'core.dart';

const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);
const Color _ok = Color(0xFF16A34A);
const Color _warn = Color(0xFFD97706);
const Color _danger = Color(0xFFDC2626);

class _VerifApi {
  static int get _id => Api.currentMitra?.id ?? 0;
  static String get _wa => Api.currentMitra?.wa ?? '';

  static Map<String, dynamic> _decode(http.Response r) {
    try {
      final j = jsonDecode(r.body);
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}
    return {'ok': false, 'error': 'Respons server tidak valid.'};
  }

  static Future<Map<String, dynamic>> status() async {
    try {
      final http.Response r = await Net.get('${Api.base}/verif-status.php?id=$_id&wa=${Uri.encodeComponent(_wa)}');
      return _decode(r);
    } catch (_) {
      return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
    }
  }

  static Future<Map<String, dynamic>> ajukan(String step, String doc) async {
    try {
      final http.Response r = await Net.postJson('${Api.base}/verif-ajukan.php', {'id': _id, 'wa': _wa, 'step': step, 'doc': doc});
      return _decode(r);
    } catch (_) {
      return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
    }
  }

  static Future<Map<String, dynamic>> emailSend() async {
    try {
      final http.Response r = await Net.postJson('${Api.base}/verif-email-otp.php?action=send', {'id': _id, 'wa': _wa});
      return _decode(r);
    } catch (_) {
      return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
    }
  }

  static Future<Map<String, dynamic>> emailVerify(String code) async {
    try {
      final http.Response r = await Net.postJson('${Api.base}/verif-email-otp.php?action=verify', {'id': _id, 'wa': _wa, 'code': code});
      return _decode(r);
    } catch (_) {
      return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
    }
  }

  static Future<Map<String, dynamic>> waAjukan() async {
    try {
      final http.Response r = await Net.postJson('${Api.base}/verif-wa-ajukan.php', {'id': _id, 'wa': _wa});
      return _decode(r);
    } catch (_) {
      return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
    }
  }

  static Future<Map<String, dynamic>> claim() async {
    try {
      final http.Response r = await Net.postJson('${Api.base}/verif-claim.php', {});
      return _decode(r);
    } catch (_) {
      return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
    }
  }
}

Future<ImageSource?> _pickSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: kBrand),
            title: const Text('Ambil dari Kamera'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: kBrand),
            title: const Text('Pilih dari Galeri'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

Future<String?> _pickImageDataUrl(ImageSource source) async {
  try {
    final x = await ImagePicker().pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 70);
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  } catch (_) {
    return null;
  }
}

ImageProvider? _dataUrlImage(String s) {
  if (s.startsWith('data:image')) {
    final i = s.indexOf(',');
    if (i > 0) {
      try {
        return MemoryImage(base64Decode(s.substring(i + 1)));
      } catch (_) {}
    }
  }
  return null;
}

class VerifikasiMitraScreen extends StatefulWidget {
  const VerifikasiMitraScreen({super.key});
  @override
  State<VerifikasiMitraScreen> createState() => _VerifikasiMitraScreenState();
}

class _VerifikasiMitraScreenState extends State<VerifikasiMitraScreen> {
  bool _loading = true;
  bool _busy = false;
  Map<String, dynamic> _steps = {};
  int _verified = 0;
  int _unclaimed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final j = await _VerifApi.status();
    await Api.me();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _steps = (j['steps'] is Map) ? Map<String, dynamic>.from(j['steps'] as Map) : {};
      _verified = (j['verified'] is num) ? (j['verified'] as num).toInt() : (Api.currentMitra?.verified ?? 0);
      final unc = j['unclaimed'];
      _unclaimed = (unc is Map && unc['total'] is num) ? (unc['total'] as num).toInt() : 0;
    });
  }

  String _statusOf(String k) {
    final s = _steps[k];
    return (s is Map && s['status'] != null) ? '${s['status']}' : 'none';
  }

  String _alasanOf(String k) {
    final s = _steps[k];
    return (s is Map && s['alasan'] != null) ? '${s['alasan']}' : '';
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _showLoading() {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  }

  Future<void> _info(String title, String msg) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Oke'))],
      ),
    );
  }

  Future<void> _klaim() async {
    setState(() => _busy = true);
    final r = await _VerifApi.claim();
    if (!mounted) return;
    setState(() => _busy = false);
    if (r['ok'] == true) {
      final c = (r['credited'] is num) ? (r['credited'] as num).toInt() : 0;
      _snack(c > 0 ? 'Berhasil! +$c Kontak masuk ke saldo.' : 'Reward sudah diklaim.');
      await _load();
    } else {
      _snack('${r['error'] ?? 'Gagal klaim reward.'}');
    }
  }

  Future<void> _verifEmail() async {
    _showLoading();
    final send = await _VerifApi.emailSend();
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (send['ok'] != true) {
      _snack('${send['error'] ?? 'Gagal mengirim kode.'}');
      return;
    }
    final codeC = TextEditingController();
    final masked = send['email_masked'] ?? send['email'] ?? 'email kamu';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kode 6 digit dikirim ke $masked.', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: codeC,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Kode OTP', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verifikasi')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _showLoading();
    final res = await _VerifApi.emailVerify(codeC.text.trim());
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (res['ok'] == true) {
      _snack('Email berhasil diverifikasi.');
      await _load();
    } else {
      _snack('${res['error'] ?? 'Kode salah atau kedaluwarsa.'}');
    }
  }

  Future<void> _verifWa() async {
    _showLoading();
    final res = await _VerifApi.waAjukan();
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (res['ok'] == true) {
      await _load();
      await _info('Pengajuan Terkirim', 'Permintaan verifikasi WhatsApp sudah masuk antrean admin. Admin akan mengonfirmasi lalu menyetujuinya. Status diperbarui otomatis di sini.');
    } else {
      _snack('${res['error'] ?? 'Gagal mengajukan verifikasi WA.'}');
    }
  }

  Future<void> _submitDoc(String step, String doc) async {
    if (doc.length > 2700000) {
      _snack('Berkas terlalu besar. Gunakan foto yang lebih kecil.');
      return;
    }
    _showLoading();
    final res = await _VerifApi.ajukan(step, doc);
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (res['ok'] == true) {
      await _load();
      await _info('Dokumen Terkirim', 'Dokumen kamu sudah dikirim dan menunggu persetujuan admin. Status diperbarui otomatis di sini.');
    } else {
      _snack('${res['error'] ?? 'Gagal mengirim dokumen.'}');
    }
  }

  Future<void> _uploadKtp() async {
    final res = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => const _DocUploadPage(
          title: 'Foto Diri & KTP',
          labels: ['1. Foto diri (selfie, wajah jelas)', '2. Foto KTP (tulisan terbaca)'],
          help: 'Foto ditinjau admin sebelum disetujui. Pastikan tidak buram dan tulisan KTP terbaca.',
        ),
      ),
    );
    if (res == null || res.length < 2 || res[0].isEmpty || res[1].isEmpty) return;
    await _submitDoc('ktp', jsonEncode({'selfie': res[0], 'ktp': res[1]}));
  }

  Future<void> _uploadIzin() async {
    final res = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => const _DocUploadPage(
          title: 'Surat Izin Usaha',
          labels: ['Foto dokumen izin usaha'],
          help: 'Mis. NIB, SIUP, surat keterangan usaha, atau foto tempat usaha. Ditinjau admin.',
        ),
      ),
    );
    if (res == null || res.isEmpty || res[0].isEmpty) return;
    await _submitDoc('izin', res[0]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Verifikasi Mitra')),
      body: Api.currentMitra == null
          ? const Center(child: Text('Belum login sebagai mitra.'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _tierBanner(),
                      if (_unclaimed > 0) ...[const SizedBox(height: 12), _claimBanner()],
                      const SizedBox(height: 16),
                      const Text('Selesaikan langkah berikut untuk menaikkan tingkat verifikasimu. Sebagian langkah ditinjau admin sebelum disetujui.', style: TextStyle(color: _muted, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 12),
                      _profilTile(),
                      const SizedBox(height: 12),
                      _kontakTile(),
                      const SizedBox(height: 12),
                      _docTile(step: 'ktp', prev: 'kontak', icon: Icons.badge_outlined, title: 'Foto Diri & KTP', reward: 5, onUpload: _uploadKtp),
                      const SizedBox(height: 12),
                      _docTile(step: 'izin', prev: 'ktp', icon: Icons.workspace_premium_outlined, title: 'Surat Izin Usaha', reward: 8, onUpload: _uploadIzin),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _tierBanner() {
    final t = verifTierFor(_verified);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [t.color.withOpacity(0.92), t.color], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tingkat verifikasi kamu', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text('Mitra ${t.label}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 2),
                Text(t.desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _claimBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFED7AA))),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Color(0xFFEA580C)),
          const SizedBox(width: 12),
          Expanded(child: Text('Kamu punya $_unclaimed Kontak hadiah verifikasi yang belum diklaim.', style: const TextStyle(fontWeight: FontWeight.w600, color: kInk, fontSize: 13))),
          FilledButton(onPressed: _busy ? null : _klaim, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEA580C)), child: const Text('Klaim')),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    String label;
    Color c;
    switch (status) {
      case 'approved':
        label = 'Terverifikasi';
        c = _ok;
        break;
      case 'pending':
        label = 'Menunggu';
        c = _warn;
        break;
      case 'rejected':
        label = 'Ditolak';
        c = _danger;
        break;
      default:
        label = 'Belum';
        c = _muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _card({required IconData icon, required String title, required int reward, required String status, required bool locked, Widget? child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kBrand.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                child: Icon(locked ? Icons.lock_outline : icon, color: locked ? _muted : kBrand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kInk)),
                    const SizedBox(height: 2),
                    Text('+$reward Kontak', style: const TextStyle(color: kBrand, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _statusChip(status),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }

  Widget _profilTile() {
    final st = _statusOf('profil');
    return _card(
      icon: Icons.assignment_ind_outlined,
      title: 'Lengkapi Profil',
      reward: 3,
      status: st,
      locked: false,
      child: st == 'approved'
          ? null
          : const Text('Lengkapi nama usaha, kategori, lokasi, dan deskripsi usaha lewat Edit Profil (web sekita.id) agar langkah ini otomatis disetujui.', style: TextStyle(color: _muted, fontSize: 12.5)),
    );
  }

  Widget _kontakTile() {
    final profilOk = _statusOf('profil') == 'approved';
    final st = _statusOf('kontak');
    final emailSt = _statusOf('kontak_email');
    final waSt = _statusOf('kontak_wa');
    final locked = !profilOk;
    Widget? body;
    if (st == 'approved') {
      body = null;
    } else if (locked) {
      body = const Text('Selesaikan Lengkapi Profil dulu.', style: TextStyle(color: _muted, fontSize: 12.5));
    } else {
      body = Column(
        children: [
          _subRow('Email', emailSt, emailSt == 'approved' ? null : _verifEmail, 'Verifikasi'),
          const SizedBox(height: 8),
          _subRow('WhatsApp', waSt, (waSt == 'approved' || waSt == 'pending') ? null : _verifWa, waSt == 'pending' ? 'Menunggu' : 'Ajukan'),
          if (waSt == 'rejected' && _alasanOf('kontak_wa').isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text('Ditolak: ${_alasanOf('kontak_wa')}', style: const TextStyle(color: _danger, fontSize: 12))),
          ],
        ],
      );
    }
    return _card(icon: Icons.contact_phone_outlined, title: 'Verifikasi WA & Email', reward: 4, status: st, locked: locked, child: body);
  }

  Widget _subRow(String label, String status, VoidCallback? onTap, String actionLabel) {
    Widget trailing;
    if (status == 'approved') {
      trailing = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: _ok, size: 18),
          SizedBox(width: 4),
          Text('Terverifikasi', style: TextStyle(color: _ok, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      );
    } else {
      trailing = OutlinedButton(onPressed: (_busy || onTap == null) ? null : onTap, child: Text(actionLabel));
    }
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: kInk, fontWeight: FontWeight.w600))),
        trailing,
      ],
    );
  }

  Widget _docTile({required String step, required String prev, required IconData icon, required String title, required int reward, required Future<void> Function() onUpload}) {
    final st = _statusOf(step);
    final locked = _statusOf(prev) != 'approved';
    Widget? body;
    if (st == 'approved') {
      body = null;
    } else if (locked) {
      final prevLabel = prev == 'kontak' ? 'Verifikasi WA & Email' : 'Foto Diri & KTP';
      body = Text('Selesaikan $prevLabel dulu.', style: const TextStyle(color: _muted, fontSize: 12.5));
    } else if (st == 'pending') {
      body = const Text('Dokumen sedang ditinjau admin.', style: TextStyle(color: _warn, fontSize: 12.5));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (st == 'rejected' && _alasanOf(step).isNotEmpty) ...[
            Text('Ditolak: ${_alasanOf(step)}', style: const TextStyle(color: _danger, fontSize: 12.5)),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _busy ? null : () => onUpload(),
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(st == 'rejected' ? 'Ajukan Ulang' : 'Upload Dokumen'),
          ),
        ],
      );
    }
    return _card(icon: icon, title: title, reward: reward, status: st, locked: locked, child: body);
  }
}

class _DocUploadPage extends StatefulWidget {
  final String title;
  final List<String> labels;
  final String help;
  const _DocUploadPage({required this.title, required this.labels, required this.help});
  @override
  State<_DocUploadPage> createState() => _DocUploadPageState();
}

class _DocUploadPageState extends State<_DocUploadPage> {
  late final List<ValueNotifier<String>> _vals;

  @override
  void initState() {
    super.initState();
    _vals = widget.labels.map((_) => ValueNotifier<String>('')).toList();
  }

  @override
  void dispose() {
    for (final v in _vals) {
      v.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (int i = 0; i < widget.labels.length; i++) ...[
            _DocSlot(label: widget.labels[i], value: _vals[i]),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: kBrand, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.help, style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.4))),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AnimatedBuilder(
            animation: Listenable.merge(_vals),
            builder: (_, __) {
              final ready = _vals.every((v) => v.value.isNotEmpty);
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: ready ? () => Navigator.pop(context, _vals.map((v) => v.value).toList()) : null,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Ajukan untuk Ditinjau'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DocSlot extends StatelessWidget {
  final String label;
  final ValueNotifier<String> value;
  const _DocSlot({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: kInk)),
        const SizedBox(height: 8),
        ValueListenableBuilder<String>(
          valueListenable: value,
          builder: (_, v, __) {
            final img = _dataUrlImage(v);
            return Column(
              children: [
                GestureDetector(
                  onTap: () => _pick(context),
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
                    alignment: Alignment.center,
                    child: img != null
                        ? Image(image: img, height: 170, width: double.infinity, fit: BoxFit.cover)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add_a_photo_outlined, color: _muted, size: 28),
                              SizedBox(height: 6),
                              Text('Ketuk untuk ambil foto', style: TextStyle(color: _muted, fontSize: 12.5)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(context),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(v.isEmpty ? 'Pilih Foto (Kamera / Galeri)' : 'Ganti Foto'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final src = await _pickSourceSheet(context);
    if (src == null) return;
    final d = await _pickImageDataUrl(src);
    if (d != null) value.value = d;
  }
}
