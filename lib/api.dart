import 'dart:convert';
import 'package:flutter/foundation.dart';
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

/// Akun mitra (penyedia jasa) yang sedang aktif di sesi.
class MitraAkun {
  final int id;
  final String nama;
  final String namaUsaha;
  final String kategori;
  final String lokasi;
  final String deskripsi;
  final String wa;
  final String email;
  final String avatar;
  final int kuota;
  final int? perdanaNo;
  final int perdanaClaimed;
  final int verified;
  final double rating;
  final int dilihat;

  const MitraAkun({
    required this.id,
    required this.nama,
    required this.namaUsaha,
    required this.kategori,
    required this.lokasi,
    required this.deskripsi,
    required this.wa,
    required this.email,
    required this.avatar,
    required this.kuota,
    required this.perdanaNo,
    required this.perdanaClaimed,
    required this.verified,
    this.rating = 0,
    this.dilihat = 0,
  });

  String get displayName => namaUsaha.trim().isNotEmpty ? namaUsaha : nama;
  bool get isVerified => verified == 1;
  bool get bisaKlaimPerdana => perdanaNo != null && perdanaClaimed == 0;

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  factory MitraAkun.fromJson(Map<String, dynamic> j) {
    return MitraAkun(
      id: _toInt(j['id']),
      nama: '${j['nama'] ?? ''}',
      namaUsaha: '${j['nama_usaha'] ?? ''}',
      kategori: '${j['kategori'] ?? ''}',
      lokasi: '${j['lokasi'] ?? ''}',
      deskripsi: '${j['deskripsi'] ?? ''}',
      wa: '${j['wa'] ?? ''}',
      email: j['email'] == null ? '' : '${j['email']}',
      avatar: '${j['avatar'] ?? ''}',
      kuota: _toInt(j['kuota']),
      perdanaNo: j['perdana_no'] == null ? null : _toInt(j['perdana_no']),
      perdanaClaimed: _toInt(j['perdana_claimed']),
      verified: _toInt(j['verified']),
      rating: _toDouble(j['rating']),
      dilihat: _toInt(j['dilihat'] ?? j['views']),
    );
  }

  MitraAkun copyWith({int? kuota, int? perdanaClaimed}) {
    return MitraAkun(
      id: id,
      nama: nama,
      namaUsaha: namaUsaha,
      kategori: kategori,
      lokasi: lokasi,
      deskripsi: deskripsi,
      wa: wa,
      email: email,
      avatar: avatar,
      kuota: kuota ?? this.kuota,
      perdanaNo: perdanaNo,
      perdanaClaimed: perdanaClaimed ?? this.perdanaClaimed,
      verified: verified,
      rating: rating,
      dilihat: dilihat,
    );
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

  /// Pembeli yang sedang login (null bila bukan mode pembeli).
  static Pembeli? currentUser;

  /// Mitra yang sedang aktif (null bila bukan mode mitra).
  static MitraAkun? currentMitra;

  /// Peran sesi aktif di server: 'pembeli' | 'mitra' | '' (tamu).
  static String currentRole = '';

  /// Mode UI aktif yang menggerakkan navigasi bawah. 'pembeli' atau 'mitra'.
  static final ValueNotifier<String> mode = ValueNotifier<String>('pembeli');

  static bool get isMitra => currentRole == 'mitra';

  static void _setPembeli(Pembeli u) {
    currentUser = u;
    currentMitra = null;
    currentRole = 'pembeli';
    mode.value = 'pembeli';
  }

  static void _setMitra(MitraAkun m) {
    currentMitra = m;
    currentUser = null;
    currentRole = 'mitra';
    mode.value = 'mitra';
  }

  static void _setGuest() {
    currentUser = null;
    currentMitra = null;
    currentRole = '';
    mode.value = 'pembeli';
  }

  /// Perbarui saldo Kontak mitra di sisi lokal (MitraAkun bersifat immutable).
  static void setMitraKuota(int kuota) {
    final m = currentMitra;
    if (m != null) currentMitra = m.copyWith(kuota: kuota);
  }

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
      // Kirim pembeli_id saat login supaya postingan IKUT AKUN (lintas device),
      // plus device_id supaya postingan lama sebagai tamu di device ini tetap kebawa.
      final pid = currentUser?.id ?? 0;
      final extra = pid > 0 ? '&pembeli_id=$pid' : '';
      final r = await http.get(Uri.parse('$base/kebutuhan-mine.php?device_id=$deviceId$extra'));
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

  // ---------- KEBUTUHAN: status / hapus / edit / ulasan ----------

  static Future<({bool ok, String error})> setKebutuhanStatus(String kebutuhanId, bool selesai) async {
    try {
      // Kepemilikan dicek di server lewat SESI (pembeli_id) ATAU device_id,
      // konsisten dengan edit/hapus. Net.postJson mengirim cookie sesi.
      final r = await Net.postJson('$base/kebutuhan-status.php', {
        'kebutuhan_id': int.tryParse(kebutuhanId) ?? 0,
        'status': selesai ? 'selesai' : 'aktif',
        'device_id': deviceId,
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

  static Future<({bool ok, String error})> editKebutuhan({
    required String id,
    required String title,
    required String kategori,
    required String lokasi,
    String deskripsi = '',
    String budget = '',
    String wa = '',
    String ic = '',
    String bg = '',
    String waktu = '',
  }) async {
    try {
      final r = await Net.postJson('$base/kebutuhan-edit.php', {
        'id': int.tryParse(id) ?? 0,
        'device_id': deviceId,
        'title': title,
        'kategori': kategori,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'budget': budget,
        'wa': wa,
        'ic': ic,
        'bg': bg,
        'waktu': waktu,
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) return (ok: true, error: '');
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal menyimpan perubahan.');
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

  /// Ambil user dari sesi server. Mengisi [currentUser] / [currentMitra] sesuai peran.
  static Future<Pembeli?> me() async {
    try {
      final r = await Net.get('$base/sesi.php?action=me');
      final j = jsonDecode(r.body);
      if (j is Map && j['loggedIn'] == true && j['user'] != null) {
        final tipe = '${j['tipe'] ?? 'pembeli'}';
        if (tipe == 'mitra') {
          _setMitra(MitraAkun.fromJson(Map<String, dynamic>.from(j['user'] as Map)));
          return null;
        }
        _setPembeli(Pembeli.fromJson(j['user'] as Map<String, dynamic>));
        return currentUser;
      }
    } catch (_) {}
    _setGuest();
    return null;
  }

  static Future<({bool ok, String error})> login(String idf, String password, {String tipe = 'pembeli'}) async {
    try {
      final r = await Net.postJson('$base/sesi.php?action=login', {
        'tipe': tipe,
        'id': idf,
        'password': password,
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true && j['loggedIn'] == true && j['user'] != null) {
        final t = '${j['tipe'] ?? tipe}';
        if (t == 'mitra') {
          _setMitra(MitraAkun.fromJson(Map<String, dynamic>.from(j['user'] as Map)));
        } else {
          _setPembeli(Pembeli.fromJson(j['user'] as Map<String, dynamic>));
        }
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

  // ---------- MITRA: peran, pendaftaran, lead, kontak ----------

  /// Pindah peran tanpa login ulang (server mencocokkan via WA).
  /// reason 'no_account' berarti akun peran tujuan belum ada.
  static Future<({bool ok, String error, String reason})> switchRole(String target) async {
    try {
      final r = await Net.postJson('$base/sesi.php?action=switch', {'target': target});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true && j['user'] != null) {
        final t = '${j['tipe'] ?? target}';
        if (t == 'mitra') {
          _setMitra(MitraAkun.fromJson(Map<String, dynamic>.from(j['user'] as Map)));
        } else {
          _setPembeli(Pembeli.fromJson(j['user'] as Map<String, dynamic>));
        }
        return (ok: true, error: '', reason: '');
      }
      return (
        ok: false,
        error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal beralih peran.',
        reason: (j is Map && j['reason'] != null) ? '${j['reason']}' : '',
      );
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.', reason: '');
    }
  }

  /// Daftar sebagai mitra. Bila [upgrade] true, server memakai password & status
  /// verifikasi dari akun pembeli yang sedang login (WA harus sama) -> tanpa password.
  static Future<({bool ok, String error, bool eligible, int bonus, int? perdanaNo})> daftarMitra({
    required String namaUsaha,
    String nama = '',
    String kategori = '',
    String lokasi = '',
    String deskripsi = '',
    required String wa,
    String email = '',
    String password = '',
    bool upgrade = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'tipe': 'mitra',
        'nama_usaha': namaUsaha,
        'nama': nama,
        'kategori': kategori,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'wa': wa,
        'email': email,
      };
      if (upgrade) {
        body['upgrade'] = 'mitra';
      } else {
        body['password'] = password;
      }
      final r = await Net.postJson('$base/daftar.php', body);
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        final p = j['perdana'];
        final eligible = p is Map && p['eligible'] == true;
        final bonus = (p is Map && p['bonus'] is num) ? (p['bonus'] as num).toInt() : 0;
        final no = (p is Map && p['no'] != null) ? int.tryParse('${p['no']}') : null;
        return (ok: true, error: '', eligible: eligible, bonus: bonus, perdanaNo: no);
      }
      return (
        ok: false,
        error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Pendaftaran mitra gagal.',
        eligible: false,
        bonus: 0,
        perdanaNo: null,
      );
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.', eligible: false, bonus: 0, perdanaNo: null);
    }
  }

  /// Klaim bonus Kontak perdana (mitra 100 pertama). Memperbarui saldo lokal.
  static Future<({bool ok, String error, int bonus, int kuota})> claimPerdana() async {
    final id = currentMitra?.id ?? 0;
    if (id <= 0) return (ok: false, error: 'Belum login sebagai mitra.', bonus: 0, kuota: 0);
    try {
      final r = await Net.postJson('$base/perdana-claim.php', {'id': id});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        final bonus = (j['bonus'] is num) ? (j['bonus'] as num).toInt() : 0;
        final kuota = (j['kuota'] is num) ? (j['kuota'] as num).toInt() : (currentMitra?.kuota ?? 0);
        final m = currentMitra;
        if (m != null) currentMitra = m.copyWith(kuota: kuota, perdanaClaimed: 1);
        return (ok: true, error: '', bonus: bonus, kuota: kuota);
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal klaim bonus.', bonus: 0, kuota: 0);
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.', bonus: 0, kuota: 0);
    }
  }

  /// Daftar Lead untuk mitra: kebutuhan TERBUKA, belum penuh penawar (maks 7),
  /// dan (opsional) sesuai kategori mitra.
  static Future<List<Kebutuhan>> fetchLeads({String? kategori, bool onlyMyCategory = false}) async {
    final all = await fetchKebutuhan();
    const maxMitra = 7;
    final cat = (kategori ?? '').trim().toLowerCase();
    return all.where((k) {
      if (k.isDone) return false;
      if (k.contactedCount >= maxMitra) return false;
      if (onlyMyCategory && cat.isNotEmpty) {
        return k.cat.trim().toLowerCase() == cat;
      }
      return true;
    }).toList();
  }

  /// Buka kontak satu lead (potong 1 Kontak; gratis bila ulang dalam 24 jam).
  static Future<({bool ok, String error, String reason, int kuota, int count, bool deducted, bool already})> kontakLead(String kebutuhanId) async {
    try {
      final r = await Net.postJson('$base/kebutuhan-kontak.php', {
        'kebutuhan_id': int.tryParse(kebutuhanId) ?? 0,
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        return (
          ok: true,
          error: '',
          reason: '',
          kuota: (j['kuota'] is num) ? (j['kuota'] as num).toInt() : (currentMitra?.kuota ?? 0),
          count: (j['count'] is num) ? (j['count'] as num).toInt() : 0,
          deducted: j['deducted'] == true,
          already: j['already'] == true,
        );
      }
      return (
        ok: false,
        error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal menghubungi.',
        reason: (j is Map && j['reason'] != null) ? '${j['reason']}' : '',
        kuota: (j is Map && j['kuota'] is num) ? (j['kuota'] as num).toInt() : (currentMitra?.kuota ?? 0),
        count: (j is Map && j['count'] is num) ? (j['count'] as num).toInt() : 0,
        deducted: false,
        already: (j is Map && j['already'] == true),
      );
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.', reason: '', kuota: currentMitra?.kuota ?? 0, count: 0, deducted: false, already: false);
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
      await Net.postJson('$base/sesi.php?action=logout', {});
    } catch (_) {}
    await Net.clear();
    _setGuest();
  }
}
