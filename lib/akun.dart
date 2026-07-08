import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'mitra.dart';
import 'lupa_password.dart';

const String _adminWa = '089607620368';
const Color _line = Color(0xFFE8ECF3);
const Color _muted = Color(0xFF64748B);
const Color _danger = Color(0xFFDC2626);
const Color _ok = Color(0xFF16A34A);

ImageProvider? _avatarProvider(String avatar) {
  if (avatar.startsWith('data:image')) {
    final i = avatar.indexOf(',');
    if (i > 0) {
      try {
        return MemoryImage(base64Decode(avatar.substring(i + 1).replaceAll(RegExp(r'\s'), '')));
      } catch (_) {}
    }
  }
  return null;
}

String _initial(String nama) {
  final t = nama.trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});
  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _loading = true);
    await Api.me();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openAuth() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _AuthScreen()));
    await _refresh();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    await _refresh();
  }

  /// User pembeli yang sudah login menekan \"Mode Mitra\".
  /// Coba pindah peran via WA; bila belum punya akun mitra -> form Jadi Mitra.
  Future<void> _goMitra() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final r = await Api.switchRole('mitra');
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (r.ok) return; // RootNav mendengar Api.mode -> otomatis pindah ke UI mitra
    if (r.reason == 'no_account') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JadiMitraScreen()));
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error)));
    }
  }

  /// Tamu (belum login) menekan entry mitra -> pilih Masuk atau Daftar mitra.
  void _mitraGuest() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.login, color: kBrand),
              title: const Text('Masuk sebagai Mitra'),
              subtitle: const Text('Sudah punya akun mitra'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MitraLoginScreen()));
                await _refresh();
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined, color: Color(0xFF7C3AED)),
              title: const Text('Daftar jadi Mitra'),
              subtitle: const Text('Daftarkan usahamu, gratis'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JadiMitraScreen()));
                await _refresh();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Api.currentUser;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Akun Saya')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _HeaderCard(user: user, onLogin: _openAuth),
                  const SizedBox(height: 18),
                  if (user != null) ..._pembeliMenu(user) else ..._guestMenu(),
                ],
              ),
            ),
    );
  }

  List<Widget> _pembeliMenu(Pembeli user) {
    final verified = user.verified == 1;
    return [
      _card([
        _MenuRow(icon: Icons.manage_accounts_outlined, color: kBrand, title: 'Edit Informasi Akun', subtitle: 'Foto, nama, WhatsApp & email', onTap: () => _open(const _EditProfilScreen())),
        _MenuRow(icon: verified ? Icons.verified_outlined : Icons.shield_outlined, color: _ok, title: 'Verifikasi Akun', subtitle: verified ? 'Akun kamu sudah terverifikasi' : 'Verifikasi email & WhatsApp', onTap: () => _open(const _VerifikasiScreen())),
      ]),
      const SizedBox(height: 14),
      _label('Untuk Penyedia Jasa'),
      _card([
        _MenuRow(icon: Icons.storefront_outlined, color: const Color(0xFF7C3AED), title: 'Mode Mitra', subtitle: 'Terima & hubungi lead sebagai penyedia jasa', onTap: _goMitra),
      ]),
      const SizedBox(height: 14),
      _label('Bantuan & Info'),
      _card([
        _MenuRow(icon: Icons.help_outline, color: kBrand, title: 'Bantuan & FAQ', subtitle: 'Pertanyaan yang sering ditanya', onTap: () => _open(const _FaqScreen())),
        _MenuRow(icon: Icons.gavel_outlined, color: const Color(0xFF7C3AED), title: 'Syarat & Ketentuan', subtitle: 'Ketentuan penggunaan Sekita', onTap: () => _open(const _SyaratScreen())),
        _MenuRow(icon: Icons.privacy_tip_outlined, color: kBrand, title: 'Kebijakan Privasi', subtitle: 'Cara kami mengelola datamu', onTap: _privasi),
        _MenuRow(icon: Icons.info_outline, color: _muted, title: 'Tentang Aplikasi', subtitle: 'Info Sekita, kontak & versi', onTap: _tentang),
      ]),
      const SizedBox(height: 14),
      _card([
        _MenuRow(icon: Icons.logout, color: _muted, title: 'Keluar', subtitle: 'Keluar dari akun ini', onTap: _logout),
        _MenuRow(icon: Icons.delete_outline, color: _danger, title: 'Hapus Akun Saya', subtitle: 'Hapus permanen akun & postingan', danger: true, onTap: _hapusAkun),
      ]),
    ];
  }

  List<Widget> _guestMenu() {
    return [
      _card([
        _MenuRow(icon: Icons.help_outline, color: kBrand, title: 'Bantuan & FAQ', subtitle: 'Pertanyaan yang sering ditanya', onTap: () => _open(const _FaqScreen())),
        _MenuRow(icon: Icons.gavel_outlined, color: const Color(0xFF7C3AED), title: 'Syarat & Ketentuan', subtitle: 'Ketentuan penggunaan Sekita', onTap: () => _open(const _SyaratScreen())),
        _MenuRow(icon: Icons.privacy_tip_outlined, color: kBrand, title: 'Kebijakan Privasi', subtitle: 'Cara kami mengelola datamu', onTap: _privasi),
        _MenuRow(icon: Icons.info_outline, color: _muted, title: 'Tentang Aplikasi', subtitle: 'Info Sekita, kontak & versi', onTap: _tentang),
      ]),
      const SizedBox(height: 14),
      _label('Untuk Penyedia Jasa'),
      _card([
        _MenuRow(icon: Icons.storefront_outlined, color: const Color(0xFF7C3AED), title: 'Masuk / Daftar sebagai Mitra', subtitle: 'Punya usaha? Terima lead dari pelanggan', onTap: _mitraGuest),
      ]),
    ];
  }

  Widget _card(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(const Divider(height: 1, thickness: 1, color: _line, indent: 64));
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
      child: Column(children: children),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.3)),
      );

  void _tentang() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(gradient: kBrandGradient),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Image.asset(
                      'assets/icon/sekita_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.handshake_outlined, color: kBrand, size: 24),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Sekita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
                  const SizedBox(height: 6),
                  const Text(
                    'Marketplace jasa lokal Jogja yang mempertemukan kamu dengan penyedia jasa terpercaya di sekitarmu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Posting kebutuhanmu. Biarkan ahlinya datang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF334155), fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  _tentangRow(Icons.verified_outlined, 'Versi', '1.0.0'),
                  const SizedBox(height: 10),
                  _tentangRow(Icons.language_outlined, 'Website', 'sekita.id'),
                  const SizedBox(height: 10),
                  _tentangRow(Icons.support_agent_outlined, 'Admin', '0896-0762-0368'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(foregroundColor: kBrand),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tentangRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: kBrand.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: kBrand, size: 18),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: kInk, fontSize: 13.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  /// Buka halaman Kebijakan Privasi di web Sekita (sumber tunggal, anti basi).
  Future<void> _privasi() async {
    final uri = Uri.parse('https://' 'sekita.id/kebijakan-privasi.html');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka halaman. Coba lagi.')),
      );
    }
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: kBrand.withOpacity(0.10), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: kBrand, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Keluar dari akun?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kInk)),
              const SizedBox(height: 6),
              const Text(
                'Kamu perlu masuk lagi untuk mengelola postingan & profilmu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kInk,
                        side: const BorderSide(color: _line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _danger,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true) {
      await Api.logout();
      await _refresh();
    }
  }

  Future<void> _hapusAkun() async {
    final ctrl = TextEditingController();
    final canDelete = ValueNotifier<bool>(false);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun Saya'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tindakan ini permanen. Akun beserta SEMUA postingan kebutuhanmu akan dihapus dan tidak bisa dikembalikan.'),
            const SizedBox(height: 14),
            const Text('Ketik HAPUS untuk konfirmasi:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: 'HAPUS', filled: true, fillColor: const Color(0xFFF7F8FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrand, width: 1.5))),
              onChanged: (v) => canDelete.value = v.trim().toUpperCase() == 'HAPUS',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ValueListenableBuilder<bool>(
            valueListenable: canDelete,
            builder: (_, can, __) => FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _danger),
              onPressed: can ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Hapus Permanen'),
            ),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final res = await Api.hapusAkun();
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun kamu sudah dihapus.')));
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error)));
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final Pembeli? user;
  final Future<void> Function() onLogin;
  const _HeaderCard({required this.user, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final u = user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: kBrandGradient,
      ),
      child: u == null ? _guest() : _profile(u),
    );
  }

  Widget _profile(Pembeli u) {
    final verified = u.verified == 1;
    final img = _avatarProvider(u.avatar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              backgroundImage: img,
              child: img == null ? Text(_initial(u.nama), style: const TextStyle(color: kBrand, fontWeight: FontWeight.w800, fontSize: 24)) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.nama.isEmpty ? 'Pengguna' : u.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(u.email.isEmpty ? (u.wa.isEmpty ? 'Akun Sekita' : u.wa) : u.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(verified ? Icons.verified : Icons.info_outline, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(verified ? 'Akun Terverifikasi' : 'Belum Terverifikasi', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_outline, color: kBrand, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Belum masuk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 2),
                  Text('Masuk untuk kelola postingan & profilmu', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: onLogin,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: kBrand,
            minimumSize: const Size.fromHeight(46),
          ),
          child: const Text('Masuk atau Daftar', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = danger ? _danger : color;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: c, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: danger ? _danger : kInk)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB0B8C4)),
          ],
        ),
      ),
    );
  }
}

class _EditProfilScreen extends StatefulWidget {
  const _EditProfilScreen();
  @override
  State<_EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<_EditProfilScreen> {
  late final TextEditingController _nama;
  late final TextEditingController _wa;
  late final TextEditingController _email;
  String _avatar = '';
  bool _busy = false;
  bool _uploadingFoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = Api.currentUser;
    _nama = TextEditingController(text: u?.nama ?? '');
    _wa = TextEditingController(text: u?.wa ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _avatar = u?.avatar ?? '';
  }

  @override
  void dispose() {
    _nama.dispose();
    _wa.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600, imageQuality: 70);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() => _uploadingFoto = true);
      final res = await Api.uploadAvatar(dataUrl);
      if (!mounted) return;
      setState(() {
        _uploadingFoto = false;
        if (res.ok) _avatar = Api.currentUser?.avatar ?? dataUrl;
      });
      if (!res.ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploadingFoto = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memilih foto.')));
      }
    }
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();
    if (_nama.text.trim().isEmpty) {
      setState(() => _error = 'Nama wajib diisi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await Api.editProfil(nama: _nama.text.trim(), email: _email.text.trim(), wa: _wa.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.reverify ? 'Profil tersimpan. WA/email berubah - silakan verifikasi ulang.' : 'Profil tersimpan.')));
      Navigator.of(context).pop();
    } else {
      setState(() => _error = res.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _avatarProvider(_avatar);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Edit Informasi Akun')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: kBrand.withOpacity(0.12),
                  backgroundImage: img,
                  child: img == null ? Text(_initial(_nama.text), style: const TextStyle(color: kBrand, fontWeight: FontWeight.w800, fontSize: 36)) : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _uploadingFoto ? null : _pickFoto,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kBrand, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: _uploadingFoto
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: _uploadingFoto ? null : _pickFoto, child: const Text('Ubah Foto Profil'))),
          const SizedBox(height: 12),
          _field(_nama, 'Nama lengkap', Icons.person_outline),
          const SizedBox(height: 14),
          _field(_wa, 'Nomor WhatsApp', Icons.phone_outlined, keyboard: TextInputType.phone),
          const SizedBox(height: 14),
          _field(_email, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFED7AA))),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(child: Text('Mengubah nomor WhatsApp atau email akan mereset status verifikasi ke \"belum diverifikasi\", dan perlu diverifikasi ulang.', style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF92400E)))),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: _danger, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _simpan,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData ic, {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 15, color: kInk),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ic, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        floatingLabelStyle: const TextStyle(color: kBrand),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrand, width: 1.5)),
      ),
    );
  }
}

class _VerifikasiScreen extends StatefulWidget {
  const _VerifikasiScreen();
  @override
  State<_VerifikasiScreen> createState() => _VerifikasiScreenState();
}

class _VerifikasiScreenState extends State<_VerifikasiScreen> {
  bool _loading = true;
  String _emailStatus = 'none';
  String _waStatus = 'none';
  String _waAlasan = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final j = await Api.verifStatus();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _emailStatus = '${j['email_status'] ?? j['emailStatus'] ?? 'none'}';
      _waStatus = '${j['wa_status'] ?? j['waStatus'] ?? 'none'}';
      _waAlasan = '${j['wa_alasan'] ?? j['waAlasan'] ?? ''}';
    });
  }

  Future<void> _emailOtp() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final send = await Api.verifEmailSend();
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (send['ok'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${send['error'] ?? 'Gagal mengirim kode.'}')));
      return;
    }
    final codeC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kami mengirim 6 digit kode ke emailmu. Masukkan kode di bawah ini.'),
            const SizedBox(height: 12),
            TextField(controller: codeC, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(labelText: 'Kode OTP', filled: true, fillColor: const Color(0xFFF7F8FA), floatingLabelStyle: const TextStyle(color: kBrand), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrand, width: 1.5)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verifikasi')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final res = await Api.verifEmailVerify(codeC.text.trim());
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (res['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email berhasil diverifikasi.')));
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['error'] ?? 'Kode salah / kedaluwarsa.'}')));
    }
  }

  Future<void> _waAjukanFn() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final res = await Api.verifWaAjukan();
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (res['ok'] == true) {
      await _load();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pengajuan Terkirim'),
          content: const Text('Permintaan verifikasi WhatsApp sudah dikirim ke admin. Admin akan meninjau dan memverifikasi secara manual. Statusnya diperbarui di sini.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Oke'))],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['error'] ?? 'Gagal mengajukan verifikasi.'}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Verifikasi Akun')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Verifikasi akunmu untuk menambah kepercayaan. Akun terverifikasi penuh ketika email & WhatsApp sudah disetujui.', style: TextStyle(color: _muted, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 16),
                  _tile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    status: _emailStatus,
                    actionLabel: 'Verifikasi via Kode',
                    onAction: _emailStatus == 'approved' ? null : _emailOtp,
                  ),
                  const SizedBox(height: 12),
                  _tile(
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp',
                    status: _waStatus,
                    note: _waStatus == 'rejected' && _waAlasan.isNotEmpty ? 'Ditolak: $_waAlasan' : (_waStatus == 'pending' ? 'Menunggu peninjauan admin.' : null),
                    actionLabel: _waStatus == 'pending' ? 'Menunggu Admin' : 'Ajukan Verifikasi',
                    onAction: (_waStatus == 'approved' || _waStatus == 'pending') ? null : _waAjukanFn,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tile({required IconData icon, required String title, required String status, String? note, required String actionLabel, VoidCallback? onAction}) {
    final s = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kBrand, size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: s.$2.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(s.$1, style: TextStyle(color: s.$2, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(note, style: const TextStyle(color: _muted, fontSize: 12.5)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusInfo(String s) {
    switch (s) {
      case 'approved':
        return ('Terverifikasi', _ok);
      case 'pending':
        return ('Menunggu', const Color(0xFFD97706));
      case 'rejected':
        return ('Ditolak', _danger);
      default:
        return ('Belum', _muted);
    }
  }
}

class _FaqScreen extends StatelessWidget {
  const _FaqScreen();
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const Text('Bantuan & FAQ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      const SizedBox(height: 4),
      const Text('Pertanyaan yang sering ditanyakan seputar Sekita.', style: TextStyle(fontSize: 13, color: _muted)),
      const SizedBox(height: 12),
    ];
    for (final g in _faqData) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6, left: 2),
        child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kBrand)),
      ));
      children.add(Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
        child: Column(
          children: [
            for (var i = 0; i < g.items.length; i++) ...[
              if (i != 0) const Divider(height: 1, thickness: 1, color: _line),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  expandedAlignment: Alignment.topLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(g.items[i].q, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  children: [Text(g.items[i].a, style: const TextStyle(color: Color(0xFF334155), fontSize: 13.5, height: 1.5))],
                ),
              ),
            ],
          ],
        ),
      ));
    }
    children.add(const SizedBox(height: 18));
    children.add(Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [kBrand, kBrandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Masih butuh bantuan?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Hubungi admin Sekita langsung via WhatsApp.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => openWa(_adminWa, text: 'Halo admin Sekita, saya butuh bantuan.'),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Hubungi Admin'),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kBrand, minimumSize: const Size.fromHeight(46)),
          ),
        ],
      ),
    ));
    children.add(const SizedBox(height: 24));
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Bantuan & FAQ')),
      body: ListView(padding: const EdgeInsets.all(16), children: children),
    );
  }
}

class _SyaratScreen extends StatelessWidget {
  const _SyaratScreen();
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const Text('Syarat & Ketentuan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      const SizedBox(height: 4),
      const Text('Berlaku sejak: 20 Juni 2026', style: TextStyle(fontSize: 12, color: _muted)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
        child: const Text('Dengan mendaftar, mengakses, atau menggunakan platform Sekita, kamu menyatakan telah membaca, memahami, dan menyetujui seluruh Syarat & Ketentuan di bawah ini. Jika kamu tidak setuju, mohon untuk tidak menggunakan layanan kami.', style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155))),
      ),
    ];
    for (var i = 0; i < _skData.length; i++) {
      final s = _skData[i];
      children.add(Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text('${i + 1}. ${s.title}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kInk)),
      ));
      for (final p in s.points) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 6, right: 8), child: Icon(Icons.circle, size: 6, color: kBrand)),
              Expanded(child: Text(p, style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)))),
            ],
          ),
        ));
      }
    }
    children.add(const SizedBox(height: 24));
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Syarat & Ketentuan')),
      body: ListView(padding: const EdgeInsets.all(16), children: children),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}

class _FaqGroup {
  final String title;
  final List<_Faq> items;
  const _FaqGroup(this.title, this.items);
}

const List<_FaqGroup> _faqData = [
  _FaqGroup('Untuk Pelanggan', [
    _Faq('Apa itu Sekita?', 'Sekita adalah platform yang mempertemukan kamu dengan penyedia jasa lokal di Yogyakarta & sekitarnya. Cukup posting kebutuhanmu secara gratis, lalu penyedia jasa yang sesuai akan datang menghubungimu. Slogannya: Posting kebutuhanmu. Biarkan ahlinya datang.'),
    _Faq('Bagaimana cara posting kebutuhan?', 'Buka tab Posting, isi jenis kebutuhan, lokasi, perkiraan budget, dan deskripsi singkat. Setelah diposting, kebutuhanmu tampil di Sekita dan mitra yang relevan bisa menghubungimu via WhatsApp. Catatan: kalau kamu sudah punya akun pembeli, verifikasi email & WhatsApp dulu di halaman akun supaya bisa posting.'),
    _Faq('Apakah memakai Sekita gratis?', 'Buat pelanggan, 100% gratis - posting kebutuhan dan menerima penawaran tidak dipungut biaya. Mitra (penyedia jasa) menggunakan paket Kontak untuk membuka data pelanggan.'),
    _Faq('Bagaimana penyedia jasa menghubungi saya?', 'Mitra yang tertarik akan membuka kontakmu lalu menghubungi langsung lewat WhatsApp. Nomormu tidak ditampilkan bebas - hanya terbuka saat mitra menekan tombol \"Hubungi\", dan setiap pembukaan tercatat.'),
    _Faq('Bagaimana cara memberi ulasan?', 'Buka dashboard akunmu, tandai kebutuhan yang sudah beres dengan \"Tandai Selesai\", lalu tombol \"Beri ulasan\" akan muncul. Ulasanmu membantu pelanggan lain memilih mitra terbaik.'),
  ]),
  _FaqGroup('Untuk Mitra (Penyedia Jasa)', [
    _Faq('Bagaimana cara jadi mitra?', 'Buka halaman Daftar / Masuk, pilih peran Mitra, lalu isi tab Daftar Jadi Mitra - gratis. Lengkapi nama usaha, kategori jasa, lokasi, WhatsApp, email & kata sandi. Setelah daftar, kamu langsung dapat 20 Kontak gratis dan bisa melihat kebutuhan pelanggan di sekitarmu.'),
    _Faq('Apa itu Kontak?', '1 Kontak = membuka 1 lead (data kontak satu pelanggan). Saat kamu membuka kebutuhan pelanggan untuk menghubunginya, 1 Kontak terpakai. Mitra baru dapat 20 Kontak gratis.'),
    _Faq('Bagaimana cara menambah Kontak?', 'Pilihan paket Kontak beserta harga dan ketentuannya tersedia di situs Sekita. Penambahan Kontak diatur lewat situs; setelah diproses, saldo Kontak pada akunmu akan diperbarui. Butuh bantuan? Hubungi admin lewat menu Hubungi Admin.'),
    _Faq('Apa arti badge verifikasi?', 'Badge menunjukkan tingkat kepercayaan mitra dalam 4 tingkat: Pemula (baru daftar) -> Tepercaya (profil lengkap + WA & email terverifikasi) -> Terverifikasi (foto diri & KTP) -> Pro (lengkap + surat izin usaha). Badge membantu pelanggan menilai, tapi bukan jaminan mutlak - selalu cek profil & ulasan sebelum bertransaksi.'),
  ]),
  _FaqGroup('Akun & Privasi', [
    _Faq('Apakah nomor WhatsApp saya aman?', 'Aman. Nomor pembeli maupun penyedia tidak ditampilkan ke publik. Nomor hanya terbuka lewat tombol \"Hubungi\", dan setiap pembukaan dicatat.'),
    _Faq('Saya lupa kata sandi, bagaimana?', 'Buka halaman Daftar / Masuk, masuk ke tab Masuk, lalu klik Lupa kata sandi di bawah kolom sandi. Masukkan email akunmu, dan kami kirim tautan reset ke email itu (berlaku 1 jam).'),
    _Faq('Bagaimana data saya dikelola?', 'Kami hanya memakai datamu untuk menjalankan layanan dan tidak menjualnya ke pihak mana pun. Selengkapnya baca Kebijakan Privasi dan Syarat & Ketentuan.'),
  ]),
];

class _SkSection {
  final String title;
  final List<String> points;
  const _SkSection(this.title, this.points);
}

const List<_SkSection> _skData = [
  _SkSection('Definisi', [
    'Sekita: platform (aplikasi & situs) yang mempertemukan pembeli dengan penyedia jasa.',
    'Pembeli/Pelanggan: pengguna yang memposting kebutuhan atau mencari jasa.',
    'Mitra/Penyedia: pengguna yang menawarkan jasa di Sekita.',
    'Kebutuhan: permintaan jasa yang diposting pembeli.',
    'Kontak: kuota untuk membuka data satu lead pelanggan.',
    'Lead: data kontak pelanggan yang dapat dibuka mitra.',
    'Konten: teks, foto, atau materi lain yang diunggah pengguna.',
  ]),
  _SkSection('Penerimaan & Kelayakan', [
    'Kamu wajib berusia minimal 17 tahun atau sudah cakap hukum untuk membuat perjanjian yang sah.',
    'Jika menggunakan Sekita atas nama usaha/badan, kamu menjamin punya wewenang untuk mewakilinya.',
    'Dengan memakai Sekita, kamu menyetujui Syarat & Ketentuan ini beserta Kebijakan Privasi.',
  ]),
  _SkSection('Peran Sekita', [
    'Sekita hanya mempertemukan pembeli & penyedia jasa (platform penghubung).',
    'Sekita bukan pihak dalam kesepakatan, negosiasi, transaksi, atau pekerjaan apa pun antar pengguna.',
    'Sekita tidak mempekerjakan mitra dan tidak menjamin tersedianya pekerjaan atau pelanggan.',
  ]),
  _SkSection('Akun & Keamanan', [
    'Kamu wajib memberikan data yang benar, akurat, dan terkini.',
    'Jaga kerahasiaan akun & kata sandimu. Seluruh aktivitas dari akunmu menjadi tanggung jawabmu.',
    'Segera beri tahu kami bila ada penggunaan akun tanpa izin.',
    'Satu orang/usaha sebaiknya tidak membuat akun ganda untuk menyalahgunakan layanan.',
  ]),
  _SkSection('Layanan untuk Pembeli', [
    'Pembeli dapat memposting kebutuhan jasa secara jujur, jelas, dan wajar.',
    'Nomor WhatsApp pembeli tidak ditampilkan ke publik dan hanya terbuka bagi mitra yang membuka lead.',
    'Pembeli bertanggung jawab memeriksa profil, portofolio, dan reputasi mitra sebelum bertransaksi.',
  ]),
  _SkSection('Layanan untuk Mitra / Penyedia', [
    'Mitra wajib menawarkan jasa sesuai kemampuan dan tidak menyesatkan.',
    'Foto portofolio, deskripsi, dan harga harus asli & akurat; dilarang memakai karya orang lain seolah milik sendiri.',
    'Mitra dilarang menyalahgunakan data kontak pembeli untuk tujuan di luar penawaran jasa (mis. spam atau jual data).',
    'Kualitas, harga, dan penyelesaian pekerjaan sepenuhnya menjadi tanggung jawab mitra.',
  ]),
  _SkSection('Kontak & Paket', [
    '1 Kontak = membuka 1 lead. Mitra menggunakan paket Kontak untuk membuka data kontak pembeli.',
    'Pilihan dan harga paket tertera di situs Sekita dan dapat berubah sewaktu-waktu; perubahan tidak berlaku surut atas paket yang sudah diperoleh.',
    'Pengaturan paket dan pembayaran dilakukan di luar aplikasi, yaitu melalui situs Sekita. Sekita tidak menyimpan data kartu/rekeningmu.',
    'Kontak yang sudah digunakan tidak dapat dikembalikan, kecuali ada kesalahan sistem yang kami verifikasi.',
    'Kontak/paket dapat memiliki masa berlaku; sisa kuota yang kedaluwarsa dapat hangus sesuai ketentuan paket.',
  ]),
  _SkSection('Sponsor & Promosi', [
    'Mitra dapat mengatur paket sponsor lewat situs Sekita untuk menonjolkan profil atau penempatan tertentu.',
    'Sponsor memengaruhi visibilitas/penempatan, bukan jaminan jumlah pesanan, klik, atau pendapatan.',
    'Sekita berhak menolak atau menghentikan promosi yang melanggar ketentuan atau hukum.',
  ]),
  _SkSection('Konten Pengguna', [
    'Kamu tetap memiliki konten yang kamu unggah, namun memberi Sekita izin untuk menampilkan & mempromosikan konten tersebut dalam rangka menjalankan layanan.',
    'Kamu menjamin punya hak atas konten yang diunggah dan tidak melanggar hak pihak lain.',
    'Sekita berhak menurunkan konten yang melanggar ketentuan, hukum, atau hak orang lain.',
  ]),
  _SkSection('Kewajiban & Larangan Pengguna', [
    'Wajib: memberi informasi jujur, menghormati pengguna lain, dan mematuhi hukum yang berlaku.',
    'Dilarang: menipu, melakukan spam, memalsukan identitas/ulasan, memposting konten ilegal, pornografi, SARA, atau menyinggung.',
    'Dilarang: menyalahgunakan data pengguna lain, meretas, atau mengganggu kerja sistem Sekita.',
    'Dilarang: bertransaksi di luar platform untuk menghindari ketentuan, lalu menyalahkan Sekita atas akibatnya.',
  ]),
  _SkSection('Ulasan & Moderasi', [
    'Ulasan harus jujur dan berdasarkan pengalaman nyata.',
    'Dilarang membuat ulasan palsu, memesan ulasan, atau menjatuhkan pesaing secara tidak adil.',
    'Sekita berhak memoderasi atau menghapus ulasan/konten yang melanggar atau dilaporkan.',
  ]),
  _SkSection('Verifikasi & Badge', [
    'Badge verifikasi adalah indikator kepercayaan, bukan jaminan mutlak atas kualitas atau perilaku mitra.',
    'Sekita dapat meninjau ulang atau mencabut badge bila ditemukan pelanggaran atau data tidak valid.',
  ]),
  _SkSection('Penangguhan & Penghentian Akun', [
    'Sekita berhak menangguhkan atau menghentikan akun yang melanggar ketentuan, merugikan pengguna lain, atau menyalahgunakan layanan.',
    'Untuk pelanggaran berat, penghentian dapat dilakukan tanpa pemberitahuan terlebih dahulu.',
    'Kamu dapat berhenti memakai Sekita kapan saja. Kuota/paket yang sudah diperoleh mengikuti ketentuan pada bagian Kontak & Paket.',
  ]),
  _SkSection('Batasan Tanggung Jawab', [
    'Segala transaksi, kesepakatan, pembayaran, dan hasil pekerjaan adalah tanggung jawab penuh pembeli & penyedia.',
    'Sekita tidak bertanggung jawab atas kerugian, penipuan, kualitas jasa, keterlambatan, cedera, sengketa, atau hal lain yang timbul dari interaksi antar pengguna.',
    'Layanan disediakan sebagaimana adanya (as is) tanpa jaminan apa pun. Selalu cek profil, portofolio, & reputasi sebelum bertransaksi.',
  ]),
  _SkSection('Hak Kekayaan Intelektual', [
    'Nama, logo, desain, dan sistem Sekita adalah milik Sekita dan dilindungi hukum.',
    'Dilarang menyalin, memodifikasi, atau memakai merek/aset Sekita tanpa izin tertulis.',
  ]),
  _SkSection('Privasi Data', [
    'Pengelolaan data pribadi diatur dalam Kebijakan Privasi yang merupakan bagian tak terpisahkan dari ketentuan ini.',
    'Kami tidak menjual data pribadimu ke pihak mana pun.',
  ]),
  _SkSection('Perubahan Ketentuan', [
    'Syarat & Ketentuan ini dapat diperbarui sewaktu-waktu. Perubahan penting akan diinformasikan di platform.',
    'Dengan tetap memakai Sekita setelah perubahan berlaku, kamu dianggap menyetujui versi terbaru.',
  ]),
  _SkSection('Penyelesaian Sengketa', [
    'Sengketa antar pengguna (pembeli & mitra) diselesaikan secara langsung di antara mereka. Sekita bukan pihak dan tidak menanggung hasilnya.',
    'Sengketa antara pengguna dengan Sekita diupayakan diselesaikan secara musyawarah terlebih dahulu sebelum menempuh jalur hukum.',
  ]),
  _SkSection('Hukum yang Berlaku', [
    'Syarat & Ketentuan ini tunduk pada hukum Republik Indonesia.',
  ]),
  _SkSection('Hubungi Kami', [
    'Ada pertanyaan soal ketentuan ini? Hubungi admin Sekita via WhatsApp: 089607620368.',
  ]),
];

class _AuthScreen extends StatefulWidget {
  const _AuthScreen();
  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kInk,
      ),
      body: _AuthView(onDone: () async {
        if (mounted) Navigator.of(context).pop();
      }),
    );
  }
}

class _AuthView extends StatefulWidget {
  final Future<void> Function() onDone;
  const _AuthView({required this.onDone});
  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  bool _isLogin = true;
  bool _busy = false;
  String? _error;
  final _nama = TextEditingController();
  final _wa = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _googleSignIn = GoogleSignIn(
    serverClientId: Api.googleServerClientId,
    scopes: const ['email', 'profile'],
  );

  @override
  void dispose() {
    _nama.dispose();
    _wa.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _lupaPassword() => showLupaPasswordDialog(context, tipe: 'pembeli');

  void _switchMode(bool login) {
    if (_busy) return;
    setState(() {
      _isLogin = login;
      _error = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_wa.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Nomor WhatsApp dan password wajib diisi.');
      return;
    }
    if (!_isLogin) {
      if (_nama.text.trim().isEmpty) {
        setState(() => _error = 'Nama wajib diisi.');
        return;
      }
      final emailReg = _email.text.trim();
      if (emailReg.isEmpty || !emailReg.contains('@')) {
        setState(() => _error = 'Email wajib diisi dengan benar.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = _isLogin
        ? await Api.login(_wa.text.trim(), _pass.text)
        : await Api.register(nama: _nama.text.trim(), wa: _wa.text.trim(), password: _pass.text, email: _email.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      await widget.onDone();
    } else {
      setState(() => _error = res.error);
    }
  }

  /// Login/daftar dengan Google: ambil idToken via google_sign_in lalu kirim ke
  /// backend. Bila akun baru belum punya WA -> tampilkan layar Lengkapi WA dulu.
  Future<void> _googleMasuk() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _googleSignIn.signOut();
      final acc = await _googleSignIn.signIn();
      if (acc == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final auth = await acc.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (mounted) {
          setState(() {
            _busy = false;
            _error = 'Gagal mendapatkan token Google. Coba lagi.';
          });
        }
        return;
      }
      final res = await Api.loginGoogle(idToken);
      if (!mounted) return;
      setState(() => _busy = false);
      if (!res.ok) {
        setState(() => _error = res.error);
        return;
      }
      if (res.needWa) {
        final done = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const _LengkapiWaScreen()),
        );
        if (done != true) return;
      }
      await widget.onDone();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Login Google gagal. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: [BoxShadow(color: Color(0x447C3AED), blurRadius: 22, offset: Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon/sekita_icon.png',
                width: 78,
                height: 78,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(gradient: kBrandGradient),
                  child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('Sekita', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: kInk))),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _isLogin ? 'Masuk untuk lanjut ke akunmu' : 'Buat akun untuk mulai pakai Sekita',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFEFF1F5), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              _toggleTab('Masuk', true),
              _toggleTab('Daftar', false),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: [
              if (!_isLogin) ...[
                _field(_nama, 'Nama lengkap', Icons.person_outline),
                const SizedBox(height: 14),
              ],
              _field(_wa, _isLogin ? 'WhatsApp / Email' : 'Nomor WhatsApp', Icons.phone_outlined, keyboard: TextInputType.text),
              const SizedBox(height: 14),
              if (!_isLogin) ...[
                _field(_email, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 14),
              ],
              _field(_pass, 'Password', Icons.lock_outline, obscure: true),
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _lupaPassword,
                    style: TextButton.styleFrom(foregroundColor: kBrand, padding: const EdgeInsets.symmetric(horizontal: 4)),
                    child: const Text('Lupa kata sandi?'),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: _danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: _danger, fontSize: 13))),
                    ],
                  ),
                ),
              ],
              SizedBox(height: _isLogin ? 6 : 18),
              SekitaGradientButton(
                label: _isLogin ? 'Masuk' : 'Daftar',
                busy: _busy,
                onTap: _busy ? null : _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: Divider(color: _line)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('atau', style: TextStyle(color: _muted, fontSize: 12.5)),
            ),
            Expanded(child: Divider(color: _line)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _googleMasuk,
            icon: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              child: const Text('G', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF4285F4))),
            ),
            label: Text(
              _isLogin ? 'Masuk dengan Google' : 'Daftar dengan Google',
              style: const TextStyle(fontWeight: FontWeight.w700, color: kInk),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: GestureDetector(
            onTap: () => _switchMode(!_isLogin),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: _muted, fontSize: 13.5),
                children: [
                  TextSpan(text: _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? '),
                  TextSpan(text: _isLogin ? 'Daftar' : 'Masuk', style: const TextStyle(color: kBrand, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleTab(String label, bool loginTab) {
    final active = _isLogin == loginTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(loginTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: active ? kBrand : _muted),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData ic, {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 15, color: kInk),
      decoration: sekitaInput(label, ic),
    );
  }
}

class _LengkapiWaScreen extends StatefulWidget {
  const _LengkapiWaScreen();
  @override
  State<_LengkapiWaScreen> createState() => _LengkapiWaScreenState();
}

class _LengkapiWaScreenState extends State<_LengkapiWaScreen> {
  final _wa = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _wa.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();
    final wa = _wa.text.trim();
    if (wa.length < 8) {
      setState(() => _error = 'Nomor WhatsApp tidak valid.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await Api.lengkapiWa(wa);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = res.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Lengkapi Nomor WhatsApp')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.chat_outlined, color: Colors.white, size: 28),
                SizedBox(height: 10),
                Text('Satu langkah lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                SizedBox(height: 4),
                Text('Tambahkan nomor WhatsApp agar mitra bisa menghubungimu saat kebutuhanmu cocok.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _wa,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 15, color: kInk),
            decoration: sekitaInput('Nomor WhatsApp', Icons.phone_outlined),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: _danger, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SekitaGradientButton(
            label: 'Simpan & Lanjut',
            busy: _busy,
            onTap: _busy ? null : _simpan,
          ),
        ],
      ),
    );
  }
}
