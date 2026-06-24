import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Klien HTTP sadar-sesi: menyimpan & mengirim ulang cookie login (PHPSESSID)
/// karena app native tidak menyimpan cookie secara otomatis seperti browser.
class Net {
  static String _cookie = '';
  static bool _loaded = false;

  static Future<void> _ensure() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      _cookie = p.getString('session_cookie') ?? '';
    } catch (_) {
      _cookie = '';
    }
    _loaded = true;
  }

  static Future<void> _capture(http.Response r) async {
    final raw = r.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;
    final first = raw.split(';').first.trim();
    if (first.isEmpty || !first.contains('=')) return;
    _cookie = first;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('session_cookie', first);
    } catch (_) {}
  }

  static Map<String, String> _headers([Map<String, String>? extra]) {
    final h = <String, String>{};
    if (extra != null) h.addAll(extra);
    if (_cookie.isNotEmpty) h['Cookie'] = _cookie;
    return h;
  }

  static Future<http.Response> get(String url) async {
    await _ensure();
    final r = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 20));
    await _capture(r);
    return r;
  }

  static Future<http.Response> postJson(String url, Map<String, dynamic> body) async {
    await _ensure();
    final r = await http
        .post(Uri.parse(url), headers: _headers({'Content-Type': 'application/json'}), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    await _capture(r);
    return r;
  }

  static Future<void> clear() async {
    _cookie = '';
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove('session_cookie');
    } catch (_) {}
  }
}

class Api {
  static const String base = 'https://' 'sekita.id/api';

  static const List<String> kategoriDasar = [
    'Terapis', 'Tukang', 'Transportasi', 'Servis AC', 'Kebersihan',
    'Les Privat', 'Fotografer', 'MUA', 'Lainnya',
  ];

  static String _deviceId = '';
  static String get deviceId => _deviceId;

  /// Pembeli yang sedang login (null bila tamu).
  static Pembeli? currentUser;

  static Future<void> initDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('device_id');
      if (id == null || id.isEmpty) {
        id = 'app_${DateTime.now().microsecondsSinceEpoch}';
        await prefs.setString('device_id', id);
      }
      _deviceId = id;
    } catch (_) {
      _deviceId = 'app_${DateTime.now().microsecondsSinceEpoch}';
    }
  }

  static Future<List<Mitra>> fetchMitra() async {
    final r = await http.get(Uri.parse('$base/mitra-list.php')).timeout(const Duration(seconds: 20));
    final j = jsonDecode(r.body);
    if (j is Map && j['ok'] == true && j['mitra'] is List) {
      return (j['mitra'] as List).map((e) => Mitra.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Gagal memuat data mitra');
  }

  static Future<List<String>> fetchKategoriExtra() async {
    try {
      final r = await http.get(Uri.parse('$base/kategori-list.php'));
      final j = jsonDecode(r.body);
      if (j is Map && j['kategori'] is List) {
        return (j['kategori'] as List).map((e) => '$e').toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<String>> fetchPortfolio(String id) async {
    try {
      final r = await http.get(Uri.parse('$base/mitra-portfolio.php?id=$id'));
      final j = jsonDecode(r.body);
      if (j is Map && j['portfolio'] is List) {
        return (j['portfolio'] as List).map((e) => '$e').toList();
      }
    } catch (_) {}
    return [];
  }

  /// Foto sampul (cover) mitra untuk header halaman detail.
  static Future<String> fetchCover(String id) async {
    if (id.isEmpty) return '';
    try {
      final r = await http.get(Uri.parse('$base/mitra-cover.php?id=$id'));
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true && j['cover'] != null) {
        return '${j['cover']}';
      }
    } catch (_) {}
    return '';
  }

  static Future<List<Ulasan>> fetchUlasan(String mitraId) async {
    try {
      final r = await http.get(Uri.parse('$base/ulasan-list.php'));
      final j = jsonDecode(r.body);
      if (j is Map && j['ulasan'] is List) {
        return (j['ulasan'] as List)
            .map((e) => Ulasan.fromJson(e as Map<String, dynamic>))
            .where((u) => u.mitraId == mitraId)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Kebutuhan>> fetchKebutuhan() async {
    final r = await http.get(Uri.parse('$base/kebutuhan-list.php')).timeout(const Duration(seconds: 20));
    final j = jsonDecode(r.body);
    if (j is Map && j['kebutuhan'] is List) {
      return (j['kebutuhan'] as List).map((e) => Kebutuhan.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Gagal memuat kebutuhan');
  }

  static Future<List<Kebutuhan>> fetchKebutuhanMine() async {
    try {
      final r = await http.get(Uri.parse('$base/kebutuhan-mine.php?device_id=$deviceId'));
      final j = jsonDecode(r.body);
      if (j is Map && j['kebutuhan'] is List) {
        return (j['kebutuhan'] as List).map((e) => Kebutuhan.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> postKebutuhan({
    required String title,
    required String kategori,
    required String lokasi,
    String deskripsi = '',
    String budget = '',
    String wa = '',
    String pembeliNama = '',
  }) async {
    try {
      final r = await Net.postJson('$base/kebutuhan-tambah.php', {
        'title': title,
        'kategori': kategori,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'budget': budget,
        'wa': wa,
        'pembeli_nama': pembeliNama,
        'device_id': deviceId,
      });
      final j = jsonDecode(r.body);
      return j is Map && j['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---------- AKUN ----------

  /// Ambil user dari sesi server. Mengisi [currentUser] bila login sebagai pembeli.
  static Future<Pembeli?> me() async {
    try {
      final r = await Net.get('$base/sesi.php?action=me');
      final j = jsonDecode(r.body);
      if (j is Map && j['loggedIn'] == true && j['tipe'] == 'pembeli' && j['user'] != null) {
        currentUser = Pembeli.fromJson(j['user'] as Map<String, dynamic>);
        return currentUser;
      }
    } catch (_) {}
    currentUser = null;
    return null;
  }

  static Future<({bool ok, String error})> login(String idf, String password) async {
    try {
      final r = await Net.postJson('$base/sesi.php?action=login', {
        'tipe': 'pembeli',
        'id': idf,
        'password': password,
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true && j['loggedIn'] == true && j['user'] != null) {
        currentUser = Pembeli.fromJson(j['user'] as Map<String, dynamic>);
        return (ok: true, error: '');
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Login gagal.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  static Future<({bool ok, String error})> register({
    required String nama,
    required String wa,
    required String password,
    String email = '',
  }) async {
    try {
      final r = await Net.postJson('$base/daftar.php', {
        'tipe': 'pembeli',
        'nama': nama,
        'wa': wa,
        'password': password,
        'email': email,
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        // daftar.php tidak otomatis login -> login setelah daftar.
        return await login(wa, password);
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Pendaftaran gagal.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  static Future<({bool ok, String error})> editProfil({required String nama, String email = ''}) async {
    try {
      final r = await Net.postJson('$base/pembeli-edit.php', {'nama': nama, 'email': email});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        if (j['user'] != null) currentUser = Pembeli.fromJson(j['user'] as Map<String, dynamic>);
        return (ok: true, error: '');
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal menyimpan profil.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  static Future<void> logout() async {
    try {
      await Net.postJson('$base/sesi.php?action=logout', {});
    } catch (_) {}
    await Net.clear();
    currentUser = null;
  }
}
