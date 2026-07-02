import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';

const kBrand = Color(0xFF2563EB);
const kBrandDark = Color(0xFF1D4ED8);
const kBrandPurple = Color(0xFF7C3AED);
const kBg = Color(0xFFF7F8FA);
const kInk = Color(0xFF111827);
const kLine = Color(0xFFE8ECF3);

// Gradient tema Sekita (mengikuti logo): ungu -> biru.
const LinearGradient kBrandGradient = LinearGradient(
  colors: [kBrandPurple, kBrand],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

ThemeData buildSekitaTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kBrand, primary: kBrand);
  final btnShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
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
    // Semua pop-up (AlertDialog) jadi konsisten: sudut membulat, latar putih,
    // judul tebal. Dialog yang sudah set shape sendiri tetap menimpa ini.
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk),
      contentTextStyle: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF475569)),
    ),
    // Tombol global membulat (mis. tombol konfirmasi di dialog).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: btnShape),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(shape: btnShape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: btnShape),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// Dekorasi input field halus & konsisten: borderless dgn isian lembut, dan
// garis fokus ungu (tema). Dipakai di form login/daftar (pembeli & mitra).
InputDecoration sekitaInput(String label, IconData icon, {bool enabled = true, String? hint}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: 1.6),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
    filled: true,
    fillColor: enabled ? const Color(0xFFF3F5F9) : const Color(0xFFE9ECF2),
    floatingLabelStyle: const TextStyle(color: kBrandPurple, fontWeight: FontWeight.w600),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    disabledBorder: border(Colors.transparent),
    focusedBorder: border(kBrandPurple),
  );
}

// Tombol utama ber-gradient (ungu -> biru) dengan status loading + ripple.
class SekitaGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final double height;
  final IconData? icon;
  const SekitaGradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.busy = false,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: kBrandGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x33512DA8), blurRadius: 16, offset: Offset(0, 7)),
            ],
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
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

// Verifikasi mitra (selaras dgn VERIF_TIERS di web).
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

// Sponsor (selaras dgn sponsorOn & sortPromoted di web).
// 3 paket: 'beranda' (hanya di beranda), 'kategori' (hanya di halaman
// kategori/cari), 'bundle' (tampil di mana saja). Paket kosong = sponsor lama
// yang dianggap tampil di mana saja.
bool sponsorOn(Mitra m, String surface) {
  if (m.promoted <= 0) return false;
  final plan = m.sponsorPlan.toLowerCase().trim();
  if (plan == 'bundle' || plan.isEmpty) return true;
  if (surface == 'beranda') return plan == 'beranda';
  if (surface == 'kategori') return plan == 'kategori';
  return true;
}

// Angkat mitra bersponsor (sesuai permukaan) ke atas daftar, dgn rotasi adil
// tiap 10 menit bila ada lebih dari satu sponsor.
List<Mitra> sortPromoted(List<Mitra> arr, String surface) {
  final promo = <Mitra>[];
  final rest = <Mitra>[];
  for (final m in arr) {
    if (sponsorOn(m, surface)) {
      promo.add(m);
    } else {
      rest.add(m);
    }
  }
  if (promo.length > 1) {
    final win = DateTime.now().millisecondsSinceEpoch ~/ 600000;
    final off = win % promo.length;
    final rotated = [...promo.sublist(off), ...promo.sublist(0, off)];
    return [...rotated, ...rest];
  }
  return [...promo, ...rest];
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
