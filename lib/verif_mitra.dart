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

/// Pemanggil endpoint verifikasi mitra. Server adalah sumber kebenaran; sebagian
/// langkah butuh persetujuan (ACC) admin lewat panel admin di web.
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

Future<String?> _pickImageDataUrl() async {
  try {
    final x = await ImagePicker().pickImage(source: ImageSource.gall