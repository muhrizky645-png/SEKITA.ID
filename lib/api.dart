import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class Api {
  static const String base = 'https://sekita.id/api';

  static const List<String> kategoriDasar = [
    'Terapis', 'Tukang', 'Transportasi', 'Servis AC', 'Kebersihan',
    'Les Privat', 'Fotografer', 'MUA', 'Lainnya',
  ];

  static String? _deviceId;
  static String get deviceId {
    _deviceId ??= 'app_${DateTime.now().microsecondsSinceEpoch}';
    return _deviceId!;
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
      final r = await http.post(
        Uri.parse('$base/kebutuhan-tambah.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'kategori': kategori,
          'lokasi': lokasi,
          'deskripsi': deskripsi,
          'budget': budget,
          'wa': wa,
          'pembeli_nama': pembeliNama,
          'device_id': deviceId,
        }),
      );
      final j = jsonDecode(r.body);
      return j is Map && j['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
