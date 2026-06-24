import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (Api.currentUser == null
              ? _AuthView(onDone: _refresh)
              : _ProfileView(user: Api.currentUser!, onChanged: _refresh)),
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
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
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

class _ProfileView extends StatelessWidget {
  final Pembeli user;
  final Future<void> Function() onChanged;
  const _ProfileView({required this.user, required this.onChanged});

  String get _initial {
    final n = user.nama.trim();
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  Future<void> _edit(BuildContext context) async {
    final namaC = TextEditingController(text: user.nama);
    final emailC = TextEditingController(text: user.email);
    String? err;
    bool busy = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Edit Profil'),
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
                Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
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
                        await onChanged();
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
      await onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: kBrand,
            child: Text(_initial, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(user.nama.isEmpty ? 'Pengguna' : user.nama,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        if (user.verified == 1)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Chip(
                label: const Text('Terverifikasi'),
                avatar: const Icon(Icons.verified, size: 16, color: kBrand),
              ),
            ),
          ),
        const SizedBox(height: 20),
        _infoTile(Icons.phone_outlined, 'WhatsApp', user.wa.isEmpty ? '-' : user.wa),
        _infoTile(Icons.email_outlined, 'Email', user.email.isEmpty ? '-' : user.email),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profil'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Keluar', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _infoTile(IconData ic, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(ic, color: kBrand, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
