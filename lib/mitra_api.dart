import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

/// Satu lead yang sudah pernah dihubungi mitra (untuk Riwayat Kontak).
class KontakRiwayat {
  final String id;
  final String title;
  final String loc;
  final String cat;
  final String ic;
  final String budget;
  final String wa;
  final String deskripsi;
  final String status;
  final int ts; // waktu mitra menghubungi (ms epoch)
  final int penawar;

  KontakRiwayat({
    required this.id,
    required this.title,
    required this.loc,
    required this.cat,
    required this.ic,
    required this.budget,
    required this.wa,
    required this.deskripsi,
    required this.status,
    required this.ts,
    required this.penawar,
  });

  bool get isDone => status == 'done';
}

/// Notifikasi lead untuk lonceng mitra.
class LeadNotif {
  final String nid;
  final String id;
  final String title;
  final String loc;
  final String cat;
  final String ic;
  final String budget;
  final int ts;

  LeadNotif({
    required this.nid,
    required this.id,
    required this.title,
    required this.loc,
    required this.cat,
    required this.ic,
    required this.budget,
    required this.ts,
  });
}

/// API fitur toko mitra: edit profil toko, foto profil, sampul, portofolio,
/// riwayat kontak, dan notifikasi lead (lonceng). Endpoint sama dengan web.
class MitraApi {
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static int get _mid => Api.currentMitra?.id ?? 0;

  // -- Edit profil toko (tentang / nama usaha / kategori / lokasi) --
  static Future<({bool ok, String error})> simpanProfil({
    required String namaUsaha,
    required String kategori,
    required String lokasi,
    required String deskripsi,
  }) async {
    final m = Api.currentMitra;
    if (m == null) return (ok: false, error: 'Belum login sebagai mitra.');
    try {
      final r = await Net.postJson('${Api.base}/verif-profil.php', {
        'id': m.id,
        'nama_usaha': namaUsaha,
        'kategori': kategori,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'nama': m.nama,
        'email': m.email,
      });
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        await Api.me();
        return (ok: true, error: '');
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal menyimpan profil.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  // -- Foto profil (pp) --
  static Future<({bool ok, String error})> simpanAvatar(String dataUrl) async {
    if (_mid <= 0) return (ok: false, error: 'Belum login sebagai mitra.');
    try {
      final r = await Net.postJson('${Api.base}/mitra-avatar.php', {'id': _mid, 'avatar': dataUrl});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) {
        await Api.me();
        return (ok: true, error: '');
      }
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal mengunggah foto.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  // -- Foto sampul (latar belakang) --
  static Future<String> ambilCover() async {
    if (_mid <= 0) return '';
    try {
      final r = await Net.get('${Api.base}/mitra-cover.php?id=$_mid');
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true && j['cover'] != null) return '${j['cover']}';
    } catch (_) {}
    return '';
  }

  static Future<({bool ok, String error})> simpanCover(String dataUrl) async {
    if (_mid <= 0) return (ok: false, error: 'Belum login sebagai mitra.');
    try {
      final r = await Net.postJson('${Api.base}/mitra-cover.php', {'id': _mid, 'cover': dataUrl});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) return (ok: true, error: '');
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal mengunggah sampul.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  // -- Portofolio (porto) --
  static Future<List<String>> ambilPortfolio() async {
    if (_mid <= 0) return [];
    try {
      final r = await Net.get('${Api.base}/mitra-portfolio.php?id=$_mid');
      final j = jsonDecode(r.body);
      if (j is Map && j['portfolio'] is List) {
        return (j['portfolio'] as List).map((e) => '$e').toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<({bool ok, String error})> simpanPortfolio(List<String> foto) async {
    if (_mid <= 0) return (ok: false, error: 'Belum login sebagai mitra.');
    try {
      final r = await Net.postJson('${Api.base}/mitra-portfolio.php', {'id': _mid, 'portfolio': foto});
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true) return (ok: true, error: '');
      return (ok: false, error: (j is Map && j['error'] != null) ? '${j['error']}' : 'Gagal menyimpan portofolio.');
    } catch (_) {
      return (ok: false, error: 'Tidak dapat terhubung ke server.');
    }
  }

  // -- Riwayat Kontak: lead yang sudah dihubungi mitra ini --
  static Future<List<KontakRiwayat>> riwayatKontak() async {
    final mid = '$_mid';
    if (mid == '0') return [];
    try {
      final r = await http.get(Uri.parse('${Api.base}/kebutuhan-list.php')).timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body);
      if (j is Map && j['kebutuhan'] is List) {
        final out = <KontakRiwayat>[];
        for (final e in (j['kebutuhan'] as List)) {
          if (e is! Map) continue;
          final cb = e['contactedBy'];
          if (cb is! List) continue;
          var mine = false;
          var myTs = 0;
          for (final c in cb) {
            if (c is Map && '${c['mitraId']}' == mid) {
              mine = true;
              myTs = _toInt(c['ts']);
              break;
            }
          }
          if (!mine) continue;
          out.add(KontakRiwayat(
            id: '${e['id'] ?? ''}',
            title: '${e['title'] ?? ''}',
            loc: '${e['loc'] ?? ''}',
            cat: '${e['cat'] ?? ''}',
            ic: (e['ic'] != null && '${e['ic']}'.isNotEmpty) ? '${e['ic']}' : '\u{1F4DD}',
            budget: '${e['budget'] ?? ''}',
            wa: '${e['wa'] ?? ''}',
            deskripsi: '${e['deskripsi'] ?? ''}',
            status: '${e['status'] ?? 'open'}',
            ts: myTs,
            penawar: cb.length,
          ));
        }
        out.sort((a, b) => b.ts.compareTo(a.ts));
        return out;
      }
    } catch (_) {}
    return [];
  }

  // -- Lonceng: lead baru relevan & belum dihubungi mitra ini --
  static Future<List<LeadNotif>> leadNotifs() async {
    final m = Api.currentMitra;
    if (m == null) return [];
    final mid = '${m.id}';
    final cat = m.kategori.trim().toLowerCase();
    try {
      final r = await http.get(Uri.parse('${Api.base}/kebutuhan-list.php')).timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body);
      if (j is Map && j['kebutuhan'] is List) {
        final out = <LeadNotif>[];
        for (final e in (j['kebutuhan'] as List)) {
          if (e is! Map) continue;
          if ('${e['status'] ?? 'open'}' == 'done') continue;
          final cb = e['contactedBy'] is List ? (e['contactedBy'] as List) : const [];
          if (cb.length >= 7) continue;
          var contacted = false;
          for (final c in cb) {
            if (c is Map && '${c['mitraId']}' == mid) {
              contacted = true;
              break;
            }
          }
          if (contacted) continue;
          if (cat.isNotEmpty && '${e['cat'] ?? ''}'.trim().toLowerCase() != cat) continue;
          out.add(LeadNotif(
            nid: 'mlead:${e['id'] ?? ''}',
            id: '${e['id'] ?? ''}',
            title: '${e['title'] ?? 'Kebutuhan baru'}',
            loc: '${e['loc'] ?? ''}',
            cat: '${e['cat'] ?? ''}',
            ic: (e['ic'] != null && '${e['ic']}'.isNotEmpty) ? '${e['ic']}' : '\u{1F4DD}',
            budget: '${e['budget'] ?? ''}',
            ts: _toInt(e['ts']),
          ));
        }
        out.sort((a, b) => b.ts.compareTo(a.ts));
        return out;
      }
    } catch (_) {}
    return [];
  }

  // -- Status baca notif (disimpan di server per sesi) --
  static Future<Set<String>> notifTerbaca() async {
    try {
      final r = await Net.get('${Api.base}/notif-read.php?action=list');
      final j = jsonDecode(r.body);
      if (j is Map && j['ok'] == true && j['read'] is Map) {
        return (j['read'] as Map).keys.map((e) => '$e').toSet();
      }
    } catch (_) {}
    return <String>{};
  }

  static Future<void> tandaiTerbaca(List<String> nids) async {
    if (nids.isEmpty) return;
    try {
      await Net.postJson('${Api.base}/notif-read.php?action=read', {'nids': nids});
    } catch (_) {}
  }
}
