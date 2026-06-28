import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

/// Minta tautan reset kata sandi via email (alur sama seperti situs web Sekita).
/// Server selalu membalas sukses (anti-enumerasi); email hanya dikirim bila terdaftar.
Future<({bool ok, String error, String message})> mintaResetSandi(String email, {String tipe = 'pembeli'}) async {
  try {
    final r = await http
        .post(
          Uri.parse('${Api.base}/lupa-password.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'tipe': tipe}),
        )
        .timeout(const Duration(seconds: 20));
    final j = jsonDecode(r.body);
    if (j is Map && j['ok'] == true) {
      final msg = j['message'] != null
          ? '${j['message']}'
          : 'Kalau email terdaftar, tautan reset sudah kami kirim. Cek inbox (dan folder spam) ya.';
      return (ok: true, error: '', message: msg);
    }
    return (
      ok: false,
      error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal mengirim tautan reset.',
      message: '',
    );
  } catch (_) {
    return (ok: false, error: 'Tidak dapat terhubung ke server.', message: '');
  }
}

/// Dialog "Lupa Kata Sandi" bergaya web: minta email -> kirim tautan reset.
/// [tipe] = 'pembeli' atau 'mitra'.
Future<void> showLupaPasswordDialog(BuildContext context, {String tipe = 'pembeli'}) async {
  final emailC = TextEditingController();
  final isMitra = tipe == 'mitra';
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Lupa Kata Sandi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masukkan email akun ${isMitra ? 'mitra ' : ''}kamu. Kami kirim tautan untuk membuat kata sandi baru (berlaku 1 jam).',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailC,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim Tautan')),
      ],
    ),
  );
  if (go != true || !context.mounted) return;
  final email = emailC.text.trim();
  if (email.isEmpty || !email.contains('@')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Masukkan alamat email yang valid.')),
    );
    return;
  }
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final res = await mintaResetSandi(email, tipe: tipe);
  if (!context.mounted) return;
  Navigator.of(context).pop(); // tutup loading
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(res.ok ? 'Cek Email Kamu' : 'Gagal'),
      content: Text(res.ok ? res.message : res.error),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Oke'))],
    ),
  );
}
