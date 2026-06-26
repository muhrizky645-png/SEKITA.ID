import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';

const String _adminWa = '089607620368';
const Color _line = Color(0xFFE8ECF3);
const Color _muted = Color(0xFF64748B);
const Color _danger = Color(0xFFDC2626);

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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _AuthScreen()),
    );
    await _refresh();
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _HeaderCard(user: user, onLogin: _openAuth),
                  const SizedBox(height: 18),
                  _menuCard(context, user),
                ],
              ),
            ),
    );
  }

  Widget _menuCard(BuildContext context, Pembeli? user) {
    final rows = <Widget>[];
    if (user != null) {
      rows.add(_MenuRow(
        icon: Icons.manage_accounts_outlined,
        title: 'Edit Informasi Akun',
        subtitle: 'Ubah nama & email',
        onTap: () => _editProfil(context, user),
      ));
    }
    rows.add(_MenuRow(
      icon: Icons.help_outline,
      title: 'Bantuan & FAQ',
      subtitle: 'Pertanyaan umum & hubungi admin',
      onTap: () => _bantuan(context),
    ));
    rows.add(_MenuRow(
      icon: Icons.info_outline,
      title: 'Tentang Aplikasi',
      subtitle: 'Info Sekita, kontak & versi',
      onTap: () => _tentang(context),
    ));
    if (user != null) {
      rows.add(_MenuRow(
        icon: Icons.logout,
        title: 'Keluar',
        subtitle: 'Keluar dari akun ini',
        danger: true,
        onTap: () => _logout(context),
      ));
    }

    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(const Divider(height: 1, thickness: 1, color: _line, indent: 64));
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(children: children),
    );
  }

  Future<void> _editProfil(BuildContext context, Pembeli user) async {
    final namaC = TextEditingController(text: user.nama);
    final emailC = TextEditingController(text: user.email);
    String? err;
    bool busy = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Edit Informasi Akun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaC, decoration: const InputDecoration(labelText: 'Nama')),
              const SizedBox(height: 12),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (opsional)'),
              ),
              if (err != null) ...[
                const SizedBox(height: 10),
                Text(err!, style: const TextStyle(color: _danger, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (namaC.text.trim().isEmpty) {
                        setS(() => err = 'Nama wajib diisi.');
                        return;
                      }
                      setS(() {
                        busy = true;
                        err = null;
                      });
                      final res = await Api.editProfil(nama: namaC.text.trim(), email: emailC.text.trim());
                      if (res.ok) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _refresh();
                      } else {
                        setS(() {
                          busy = false;
                          err = res.error;
                        });
                      }
                    },
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _bantuan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bantuan & FAQ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 14),
            _faq('Bagaimana cara cari jasa?',
                'Buka tab Cari, pilih kategori atau ketik kebutuhanmu, lalu klik tombol WhatsApp pada mitra.'),
            _faq('Apa itu Posting Kebutuhan?',
                'Kalau belum nemu mitra yang pas, posting kebutuhanmu (gratis) supaya mitra yang menghubungi kamu.'),
            _faq('Apakah harus daftar akun?',
                'Tidak wajib. Daftar hanya memudahkan kelola postingan & profilmu.'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                openWa(_adminWa, text: 'Halo admin Sekita, saya butuh bantuan.');
              },
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Hubungi Admin via WhatsApp'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 3),
          Text(a, style: const TextStyle(color: _muted, fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }

  void _tentang(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tentang Sekita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Sekita \u2014 marketplace jasa lokal Jogja.', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text('Versi 1.0.0', style: TextStyle(color: _muted, fontSize: 13)),
            SizedBox(height: 4),
            Text('Website: sekita.id', style: TextStyle(color: _muted, fontSize: 13)),
            SizedBox(height: 4),
            Text('Admin: 0896-0762-0368', style: TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin mau keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (yes == true) {
      await Api.logout();
      await _refresh();
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
        gradient: const LinearGradient(
          colors: [kBrand, kBrandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: u == null ? _guest() : _profile(u),
    );
  }

  Widget _profile(Pembeli u) {
    final initial = u.nama.trim().isEmpty ? '?' : u.nama.trim().substring(0, 1).toUpperCase();
    final verified = u.verified == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Text(initial,
                  style: const TextStyle(color: kBrand, fontWeight: FontWeight.w800, fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.nama.isEmpty ? 'Pengguna' : u.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(u.email.isEmpty ? (u.wa.isEmpty ? 'Akun Sekita' : u.wa) : u.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(verified ? Icons.verified : Icons.person_outline, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(verified ? 'Akun Terverifikasi' : 'Akun Pembeli',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                  Text('Belum masuk',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 2),
                  Text('Masuk untuk kelola postingan & profilmu',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
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
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _danger : kBrand;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15, color: danger ? _danger : kInk)),
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

class _AuthScreen extends StatefulWidget {
  const _AuthScreen();
  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk / Daftar')),
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

  @override
  void dispose() {
    _nama.dispose();
    _wa.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_wa.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Nomor WhatsApp dan password wajib diisi.');
      return;
    }
    if (!_isLogin && _nama.text.trim().isEmpty) {
      setState(() => _error = 'Nama wajib diisi.');
      return;
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: kBrand, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.person, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(_isLogin ? 'Masuk ke akunmu' : 'Buat akun Sekita',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('Akun memudahkan kelola postingan & verifikasi',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ),
        const SizedBox(height: 20),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Masuk')),
            ButtonSegment(value: false, label: Text('Daftar')),
          ],
          selected: {_isLogin},
          onSelectionChanged: (s) => setState(() {
            _isLogin = s.first;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        if (!_isLogin) ...[
          _field(_nama, 'Nama lengkap', Icons.person_outline),
          const SizedBox(height: 12),
        ],
        _field(_wa, _isLogin ? 'WhatsApp / Email' : 'Nomor WhatsApp', Icons.phone_outlined,
            keyboard: TextInputType.text),
        const SizedBox(height: 12),
        if (!_isLogin) ...[
          _field(_email, 'Email (opsional)', Icons.email_outlined, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
        ],
        _field(_pass, 'Password', Icons.lock_outline, obscure: true),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: _danger, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isLogin ? 'Masuk' : 'Daftar'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, IconData ic, {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ic),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
