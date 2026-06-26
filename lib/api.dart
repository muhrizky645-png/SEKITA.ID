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
    String waktu = '',
    String ic = '',
    String bg = '',
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
        'waktu': waktu,
        'ic': ic,
        'bg': bg,
        'device_id': deviceId,
      });
      final j = jsonDecode(r.body);
      return j is Map && j['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---------- KEBUTUHAN: status / hapus / ulasan ----------

  static Future<({bool ok, String error})> setKebutuhanStatus(String kebutuhanId, bool selesai) async {
    try {
      final r = await Net.postJson('$base/kebutuhan-status.php', {
        'kebutuhan_id': int.tryParse(kebutuhanId) ?? 0,
        'status': selesai ? 'selesai' : 'aktif',
        'pembeli_wa': currentUser?.wa ?? '',
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) return (ok: true, error: '');
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal memperbarui status.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  static Future<({bool ok, String error})> hapusKebutuhan(String id) async {
    try {
      final r = await Net.postJson('$base/kebutuhan-hapus.php', {
        'id': int.tryParse(id) ?? 0,
        'device_id': deviceId,
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) return (ok: true, error: '');
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal menghapus postingan.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  static Future<({bool ok, String error})> tambahUlasan({
    required String mitraId,
    required String mitraNama,
    required String kebutuhanId,
    required int rating,
    String komentar = '',
    String postTitle = '',
  }) async {
    try {
      final r = await Net.postJson('$base/ulasan-tambah.php', {
        'mitra_id': int.tryParse(mitraId) ?? 0,
        'mitra_nama': mitraNama,
        'kebutuhan_id': int.tryParse(kebutuhanId) ?? 0,
        'pembeli_id': currentUser?.id,
        'penulis': currentUser?.nama ?? 'Pembeli',
        'pembeli_avatar': currentUser?.avatar ?? '',
        'post_title': postTitle,
        'rating': rating,
        'komentar': komentar,
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) return (ok: true, error: '');
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal mengirim ulasan.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
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
