import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Lapisan jaringan + state user untuk Sekita.
class Net {
  static String? _cookie;

  static Future<void> _load() async {
    if (_cookie != null) return;
    final sp = await SharedPreferences.getInstance();
    _cookie = sp.getString('session_cookie') ?? '';
  }

  static Future<void> _save(http.Response r) async {
    final raw = r.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;
    final m = RegExp(r'PHPSESSID=[^;]+').firstMatch(raw);
    if (m != null) {
      _cookie = m.group(0);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('session_cookie', _cookie ?? '');
    }
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    await _load();
    return {
      if (json) 'Content-Type': 'application/json',
      if ((_cookie ?? '').isNotEmpty) 'Cookie': _cookie!,
    };
  }

  static Future<http.Response> get(String url) async {
    final r = await http.get(Uri.parse(url), headers: await _headers()).timeout(const Duration(seconds: 20));
    await _save(r);
    return r;
  }

  static Future<http.Response> postJson(String url, Object body) async {
    final r = await http
        .post(Uri.parse(url), headers: await _headers(json: true), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    await _save(r);
    return r;
  }

  static Future<void> clear() async {
    _cookie = '';
    final sp = await SharedPreferences.getInstance();
    await sp.remove('session_cookie');
  }
}

class Api {
  static const String base = 'https://' 'sekita.id/api';
  static Pembeli? currentUser;
  static String deviceId = '';

  static Future<void> initDeviceId() async {
    final sp = await SharedPreferences.getInstance();
    var id = sp.getString('device_id');
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      await sp.setString('device_id', id);
    }
    deviceId = id;
  }

  static Future<List<Mitra>> fetchMitra() async {
    try {
      final r = await Net.get('$base/mitra-list.php');
      final j = jsonDecode(r.body);
      final list = (j is Map ? j['data'] : j) as List? ?? [];
      return list.map((e) => Mitra.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> fetchKategoriExtra() async {
    try {
      final r = await Net.get('$base/kategori-list.php');
      final j = jsonDecode(r.body);
      final list = (j is Map ? j['data'] : j) as List? ?? [];
      return list.map((e) => '$e').toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> fetchPortfolio(int mitraId) async {
    try {
      final r = await Net.get('$base/mitra-portfolio.php?id=$mitraId');
      final j = jsonDecode(r.body);
      final list = (j is Map ? j['data'] : j) as List? ?? [];
      return list.map((e) => '$e').toList();
    } catch (_) {
      return [];
    }
  }

  static Future<String?> fetchCover(int mitraId) async {
    try {
      final r = await Net.get('$base/mitra-cover.php?id=$mitraId');
      final j = jsonDecode(r.body);
      if (j is Map && j['cover'] != null) return '${j['cover']}';
    } catch (_) {}
    return null;
  }

  static Future<List<Ulasan>> fetchUlasan(int mitraId) async {
    try {
      final r = await Net.get('$base/ulasan-list.php?mitra_id=$mitraId');
      final j = jsonDecode(r.body);
      final list = (j is Map ? j['data'] : j) as List? ?? [];
      return list.map((e) => Ulasan.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Kebutuhan>> fetchKebutuhan() async {
    try {
      final r = await Net.get('$base/kebutuhan-list.php');
      final j = jsonDecode(r.body);
      final list = (j is Map ? j['data'] : j) as List? ?? [];
      return list.map((e) => Kebutuhan.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Kebutuhan>> fetchKebutuhanMine() async {
    try {
      final r = await Net.get('$base/kebutuhan-mine.php?device_id=$deviceId');
      final j = jsonDecode(r.body);
      final list = (j is Map ? j['data'] : j) as List? ?? [];
      return list.map((e) => Kebutuhan.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<({bool ok, String error})> postKebutuhan(Map<String, dynamic> data) async {
    try {
      final payload = {...data, 'device_id': deviceId};
      final r = await Net.postJson('$base/kebutuhan-tambah.php', payload);
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) return (ok: true, error: '');
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal posting kebutuhan.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  static Future<Pembeli?> me() async {
    try {
      final r = await Net.get('$base/sesi.php?action=me');
      final j = jsonDecode(r.body);
      if (j is Map && j['loggedIn'] == true && j['tipe'] == 'pembeli' && j['user'] != null) {
        currentUser = Pembeli.fromJson(j['user'] as Map<String, dynamic>);
      } else {
        currentUser = null;
      }
    } catch (_) {
      currentUser = null;
    }
    return currentUser;
  }

  static Future<({bool ok, String error})> login(String idf, String password) async {
    try {
      final r = await Net.postJson('$base/sesi.php?action=login', {'identifier': idf, 'password': password, 'tipe': 'pembeli'});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        await me();
        return (ok: true, error: '');
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal masuk.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  static Future<({bool ok, String error})> register({required String nama, required String wa, required String password, String email = ''}) async {
    try {
      final r = await Net.postJson('$base/daftar.php', {'nama': nama, 'wa': wa, 'password': password, 'email': email, 'tipe': 'pembeli'});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        await me();
        return (ok: true, error: '');
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal mendaftar.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  /// Edit profil pembeli. Mengubah WA/email akan mereset status verifikasi di server.
  static Future<({bool ok, String error, bool reverify})> editProfil({
    required String nama,
    String email = '',
    String? wa,
  }) async {
    try {
      final payload = <String, dynamic>{'nama': nama, 'email': email};
      if (wa != null) payload['wa'] = wa;
      final r = await Net.postJson('$base/pembeli-edit.php', payload);
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        if (j['user'] != null) currentUser = Pembeli.fromJson(j['user'] as Map<String, dynamic>);
        return (ok: true, error: '', reverify: j['reverify'] == true);
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal menyimpan profil.', reverify: false);
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.', reverify: false);
    }
  }

  /// Unggah/ubah foto profil pembeli (data URL base64). Menyegarkan currentUser.
  static Future<({bool ok, String error})> uploadAvatar(String dataUrl) async {
    final id = currentUser?.id ?? 0;
    if (id <= 0) return (ok: false, error: 'Belum login.');
    try {
      final r = await Net.postJson('$base/pembeli-avatar.php', {'id': id, 'avatar': dataUrl});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        await me();
        return (ok: true, error: '');
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal mengunggah foto.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  /// Hapus permanen akun pembeli beserta postingannya.
  static Future<({bool ok, String error})> hapusAkun() async {
    try {
      final r = await Net.postJson('$base/pembeli-hapus.php', {'confirm': true});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        await Net.clear();
        currentUser = null;
        return (ok: true, error: '');
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal menghapus akun.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  // ---------- VERIFIKASI PEMBELI ----------

  static Future<Map<String, dynamic>> verifStatus() async {
    final id = currentUser?.id ?? 0;
    if (id <= 0) return {'ok': false, 'error': 'Belum login.'};
    try {
      final r = await Net.get('$base/verif-pembeli-status.php?id=$id');
      final j = jsonDecode(r.body);
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}
    return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
  }

  static Future<Map<String, dynamic>> verifEmailSend() async {
    final id = currentUser?.id ?? 0;
    try {
      final r = await Net.postJson('$base/verif-pembeli-email-otp.php?action=send', {'id': id});
      final j = jsonDecode(r.body);
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}
    return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
  }

  static Future<Map<String, dynamic>> verifEmailVerify(String code) async {
    final id = currentUser?.id ?? 0;
    try {
      final r = await Net.postJson('$base/verif-pembeli-email-otp.php?action=verify', {'id': id, 'code': code});
      final j = jsonDecode(r.body);
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}
    return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
  }

  static Future<Map<String, dynamic>> verifWaAjukan() async {
    final id = currentUser?.id ?? 0;
    try {
      final r = await Net.postJson('$base/verif-pembeli-wa-ajukan.php', {'id': id});
      final j = jsonDecode(r.body);
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}
    return {'ok': false, 'error': 'Tidak dapat terhubung ke server.'};
  }

  static Future<void> logout() async {
    try {
      await Net.get('$base/sesi.php?action=logout');
    } catch (_) {}
    await Net.clear();
    currentUser = null;
  }
}
