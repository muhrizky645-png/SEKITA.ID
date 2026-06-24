import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kBrand = Color(0xFF2563EB);
const kBrandDark = Color(0xFF1D4ED8);
const kBg = Color(0xFFF7F8FA);
const kInk = Color(0xFF111827);

ThemeData buildSekitaTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kBrand, primary: kBrand);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kInk,
      elevation: 0,
      centerTitle: false,
    ),
  );
}

String waNormalize(String wa) {
  var s = wa.replaceAll(RegExp(r'[^0-9]'), '');
  if (s.startsWith('0')) s = '62${s.substring(1)}';
  return s;
}

Future<void> openWa(String wa, {String text = ''}) async {
  final n = waNormalize(wa);
  if (n.isEmpty) return;
  final q = text.isNotEmpty ? '?text=${Uri.encodeComponent(text)}' : '';
  final uri = Uri.parse('https://' + 'wa.me/' + n + q);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

IconData iconForKategori(String c) {
  switch (c.toLowerCase()) {
    case 'terapis':
      return Icons.spa_outlined;
    case 'tukang':
      return Icons.handyman_outlined;
    case 'transportasi':
      return Icons.local_shipping_outlined;
    case 'servis ac':
      return Icons.ac_unit;
    case 'kebersihan':
      return Icons.cleaning_services_outlined;
    case 'les privat':
      return Icons.school_outlined;
    case 'fotografer':
      return Icons.camera_alt_outlined;
    case 'mua':
      return Icons.brush_outlined;
    case 'lainnya':
      return Icons.more_horiz;
    default:
      return Icons.work_outline;
  }
}

// Path relatif ke aset kategori di sekita.id. Cocokkan dgn prefix supaya
// kategori seperti "Lainnya (Maklon ...)" tetap dapat icon yang benar.
String catIconPath(String c) {
  final lc = c.toLowerCase().trim();
  if (lc.startsWith('terapis')) return 'assets/img/cat/terapis.png';
  if (lc.startsWith('tukang')) return 'assets/img/cat/tukang.png';
  if (lc.startsWith('transportasi')) return 'assets/img/cat/transportasi.png';
  if (lc.startsWith('servis ac') || lc == 'ac') return 'assets/img/cat/ac.png';
  if (lc.startsWith('kebersihan')) return 'assets/img/cat/kebersihan.png';
  if (lc.startsWith('les')) return 'assets/img/cat/les.png';
  if (lc.startsWith('fotografer') || lc.startsWith('foto')) return 'assets/img/cat/foto.png';
  if (lc.startsWith('mua')) return 'assets/img/cat/mua.png';
  return 'assets/img/cat/lainnya.png';
}

String bannerPath(int n) => 'assets/img/banner/banner-$n.jpg';

// ── Verifikasi mitra (selaras dgn VERIF_TIERS di web) ────────────────────
// Level 0 (Pemula/abu-abu) tidak ditampilkan sebagai badge. Hanya 1/2/3.
class VerifTier {
  final int level;
  final String label;
  final Color color;
  final String desc;
  const VerifTier(this.level, this.label, this.color, this.desc);
}

const List<VerifTier> kVerifTiers = [
  VerifTier(0, 'Pemula', Color(0xFF94A3B8),
      'Mitra baru terdaftar, belum melengkapi verifikasi'),
  VerifTier(1, 'Tepercaya', Color(0xFF16A34A),
      'Profil lengkap + WhatsApp & email terverifikasi'),
  VerifTier(2, 'Terverifikasi', Color(0xFF2563EB),
      'Foto diri & KTP terverifikasi'),
  VerifTier(3, 'Pro', Color(0xFF7C3AED),
      'Verifikasi penuh: foto diri & KTP + surat izin usaha'),
];

VerifTier verifTierFor(int level) {
  var l = level;
  if (l < 0) l = 0;
  if (l > 3) l = 3;
  return kVerifTiers[l];
}

class SekitaImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  const SekitaImage(this.src, {super.key, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (src.startsWith('data:image')) {
      try {
        final b64 = src.substring(src.indexOf(',') + 1);
        return Image.memory(base64Decode(b64), width: width, height: height, fit: fit, gaplessPlayback: true);
      } catch (_) {
        return _placeholder();
      }
    }
    var url = src;
    if (url.isNotEmpty && !url.startsWith('http')) {
      final host = 'https://' + 'sekita.id/';
      url = host + url.replaceFirst(RegExp(r'^/'), '');
    }
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (c, child, progress) =>
          progress == null ? child : Container(width: width, height: height, color: const Color(0xFFE5E7EB)),
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.image_outlined, color: Colors.white),
      );
}
