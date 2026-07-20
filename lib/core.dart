import 'dart:convert';
import 'dart:math' as math;
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

// Loader kustom Sekita: 3 titik memantul (naik-turun) bergiliran.
// Dipakai menggantikan CircularProgressIndicator default di layar loading.
class SekitaDots extends StatefulWidget {
  final Color color;
  final double size;
  const SekitaDots({super.key, this.color = kBrand, this.size = 10});

  @override
  State<SekitaDots> createState() => _SekitaDotsState();
}

class _SekitaDotsState extends State<SekitaDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final amp = s * 0.9; // tinggi pantulan
    return SizedBox(
      height: s + amp,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              // Fase tiap titik digeser supaya memantul bergiliran.
              final t = (_c.value + i * 0.18) % 1.0;
              final dy = -math.sin(t * math.pi) * amp;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: s * 0.3),
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
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
                  ? const SekitaDots(color: Colors.white, size: 9)
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

/// Pesan WhatsApp mitra -> pembeli. Kata-katanya disamakan dengan sekita.id
/// (fungsi sellerToBuyerMsg di web).
String pesanMitraKePembeli({
  required String usaha,
  required String kebutuhan,
  String mitraId = '',
}) {
  final who = usaha.trim().isNotEmpty ? usaha.trim() : 'Mitra';
  final kb = kebutuhan.trim().isNotEmpty ? kebutuhan.trim() : 'kebutuhan Anda';
  final profil = mitraId.trim().isNotEmpty
      ? '\n\nSebelum lanjut, Anda bisa cek dulu profil & portofolio saya di sini:\nsekita.id/jasa/${mitraId.trim()}'
      : '';
  return 'Halo, saya *$who*, mitra dari *sekita.id*. \u{1F64C}\n'
      'Saya melihat postingan kebutuhan Anda soal "$kb" dan ingin menawarkan jasa saya.'
      '$profil\n\n'
      'Kalau berkenan, boleh kita diskusikan detailnya? Terima kasih \u{1F64F}';
}

/// Pesan WhatsApp pembeli -> penjual/mitra. Kata-katanya disamakan dengan
/// sekita.id (fungsi buyerToSellerMsg di web).
String pesanPembeliKeMitra({
  required String usaha,
  required String kebutuhan,
}) {
  final who = usaha.trim().isNotEmpty ? usaha.trim() : 'Mitra';
  final kb = kebutuhan.trim().isNotEmpty ? kebutuhan.trim() : 'sebuah kebutuhan';
  return 'Halo *$who*, saya menemukan profil Anda di *sekita.id*. \u{1F44B}\n'
      'Saya tertarik dengan jasa Anda, kebetulan saya ada kebutuhan soal "$kb".\n\n'
      'Boleh kita diskusikan lebih lanjut? Terima kasih \u{1F64F}';
}

// == Taksonomi kategori (induk + sub) ==
// Sumber kebenaran = web (api/kategori-taxonomy.php). App simpan salinan
// hardcoded sebagai fallback, lalu bisa diperbarui saat runtime lewat
// Api.fetchTaxonomy() (endpoint api/kategori-tree.php).
class KategoriInduk {
  final String key;
  final String name;
  final String emoji;
  final List<String> subs;
  const KategoriInduk(this.key, this.name, this.emoji, this.subs);
}

const List<KategoriInduk> kTaxonomyFallback = [
  KategoriInduk('rumah', 'Rumah & Perbaikan', '\ud83c\udfe0', [
    'Arsitek', 'Kontraktor', 'Tukang Bangunan', 'Servis AC', 'Listrik',
    'Ledeng/Pipa', 'Servis Elektronik', 'Kayu/Mebel', 'Las',
  ]),
  KategoriInduk('kebersihan', 'Kebersihan & Perawatan Rumah', '\ud83e\uddf9', [
    'Cleaning Service', 'Cuci Sofa/Kasur', 'Laundry', 'Sedot WC', 'Perawatan Taman',
  ]),
  KategoriInduk('kecantikan', 'Kecantikan & Kesehatan', '\ud83d\udc84', [
    'MUA', 'Salon', 'Barbershop', 'Facial', 'Terapis/Pijat', 'Nail Art',
  ]),
  KategoriInduk('acara', 'Acara & Dokumentasi', '\ud83d\udcf8', [
    'Fotografer', 'Wedding Organizer', 'Dekorasi', 'Sound System', 'MC', 'Katering',
  ]),
  KategoriInduk('pendidikan', 'Pendidikan & Les', '\ud83d\udcda', [
    'Les Akademik', 'Bimbel', 'Les Musik', 'Les Bahasa', 'Mengaji', 'Les Olahraga',
  ]),
  KategoriInduk('transportasi', 'Transportasi & Logistik', '\ud83d\ude97', [
    'Sewa Mobil', 'Sewa Motor', 'Rental + Sopir', 'Jasa Pindahan', 'Ekspedisi', 'Sewa Bus/Elf',
  ]),
  KategoriInduk('otomotif', 'Otomotif', '\ud83d\udd27', [
    'Bengkel Mobil', 'Bengkel Motor', 'Steam/Cuci', 'Derek', 'Variasi', 'Oli/Ban',
  ]),
  KategoriInduk('digital', 'Digital & Kreatif', '\ud83d\udcbb', [
    'Desain Grafis', 'Pembuatan Website', 'Admin Sosmed', 'Percetakan/Sablon', 'Servis HP/Komputer',
  ]),
  KategoriInduk('harian', 'Jasa Harian & Lainnya', '\ud83e\uddfa', [
    'ART', 'Baby Sitter', 'Jahit/Permak', 'Jasa Titip',
  ]),
];

List<KategoriInduk> sekitaTaxonomy = List<KategoriInduk>.from(kTaxonomyFallback);

void setSekitaTaxonomy(List<KategoriInduk> list) {
  if (list.isEmpty) return;
  sekitaTaxonomy = list;
}

class _CatAliasEntry {
  final String induk;
  final String? sub;
  const _CatAliasEntry(this.induk, this.sub);
}

const Map<String, _CatAliasEntry> _kCatAlias = {
  'tukang': _CatAliasEntry('rumah', 'Tukang Bangunan'),
  'tukang / bangunan': _CatAliasEntry('rumah', 'Tukang Bangunan'),
  'terapis': _CatAliasEntry('kecantikan', 'Terapis/Pijat'),
  'les privat': _CatAliasEntry('pendidikan', null),
  'kebersihan': _CatAliasEntry('kebersihan', null),
  'transportasi': _CatAliasEntry('transportasi', null),
};

String _lc(String s) => s.toLowerCase().trim();

/// Slugify SAMA dengan server (sekita_slug_tag) & notif._slug.
String slugTag(String s) {
  final lower = s.toLowerCase().trim();
  final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return replaced.replaceAll(RegExp(r'^_+|_+$'), '');
}

bool isLainnyaCat(String cat) =>
    RegExp(r'^lainnya', caseSensitive: false).hasMatch(cat.trim());

String indukKeyOf(String cat) {
  final lc = _lc(cat);
  if (lc.isEmpty) return '';
  if (lc.startsWith('lainnya')) return 'harian';
  for (final ind in sekitaTaxonomy) {
    if (_lc(ind.name) == lc) return ind.key;
    for (final s in ind.subs) {
      if (_lc(s) == lc) return ind.key;
    }
  }
  final a = _kCatAlias[lc];
  if (a != null) return a.induk;
  return '';
}

KategoriInduk? indukByKey(String key) {
  for (final ind in sekitaTaxonomy) {
    if (ind.key == key) return ind;
  }
  return null;
}

KategoriInduk? indukOf(String cat) => indukByKey(indukKeyOf(cat));

String indukNameOf(String cat) => indukOf(cat)?.name ?? '';

bool isSpecificSub(String cat) {
  final lc = _lc(cat);
  if (lc.isEmpty) return false;
  for (final ind in sekitaTaxonomy) {
    for (final s in ind.subs) {
      if (_lc(s) == lc) return true;
    }
  }
  return false;
}

String canonicalCat(String cat) {
  final lc = _lc(cat);
  if (lc.isEmpty) return cat;
  for (final ind in sekitaTaxonomy) {
    for (final s in ind.subs) {
      if (_lc(s) == lc) return s;
    }
  }
  final a = _kCatAlias[lc];
  if (a != null && a.sub != null) return a.sub!;
  return cat;
}

bool sameInduk(String a, String b) {
  final ka = indukKeyOf(a);
  final kb = indukKeyOf(b);
  if (ka.isNotEmpty && kb.isNotEmpty) return ka == kb;
  String base(String c) => c.split('(').first.trim().toLowerCase();
  return base(a) == base(b);
}

IconData iconForKategori(String c) {
  switch (indukKeyOf(c)) {
    case 'rumah':
      return Icons.handyman_outlined;
    case 'kebersihan':
      return Icons.cleaning_services_outlined;
    case 'kecantikan':
      return Icons.spa_outlined;
    case 'acara':
      return Icons.camera_alt_outlined;
    case 'pendidikan':
      return Icons.school_outlined;
    case 'transportasi':
      return Icons.local_shipping_outlined;
    case 'otomotif':
      return Icons.build_outlined;
    case 'digital':
      return Icons.devices_outlined;
    case 'harian':
      return Icons.home_repair_service_outlined;
  }
  switch (c.toLowerCase()) {
    case 'terapis':
      return Icons.spa_outlined;
    case 'tukang':
      return Icons.handyman_outlined;
    case 'servis ac':
      return Icons.ac_unit;
    case 'les privat':
      return Icons.school_outlined;
    case 'fotografer':
      return Icons.camera_alt_outlined;
    case 'mua':
      return Icons.brush_outlined;
    default:
      return Icons.work_outline;
  }
}

// Path relatif ke aset kategori di sekita.id. Cocokkan dgn prefix supaya
// kategori seperti "Lainnya (Maklon ...)" tetap dapat icon yang benar.
String catIconPath(String c) {
  const byKey = {
    'rumah': 'assets/img/cat/tukang.png',
    'kebersihan': 'assets/img/cat/kebersihan.png',
    'kecantikan': 'assets/img/cat/mua.png',
    'acara': 'assets/img/cat/foto.png',
    'pendidikan': 'assets/img/cat/les.png',
    'transportasi': 'assets/img/cat/transportasi.png',
    'otomotif': 'assets/img/cat/otomotif.png',
    'digital': 'assets/img/cat/digital.png',
    'harian': 'assets/img/cat/lainnya.png',
  };
  final byInduk = byKey[indukKeyOf(c)];
  if (byInduk != null) return byInduk;
  final lc = c.toLowerCase().trim();
  if (lc.startsWith('terapis')) return 'assets/img/cat/terapis.png';
  if (lc.startsWith('tukang')) return 'assets/img/cat/tukang.png';
  if (lc.startsWith('servis ac') || lc == 'ac') return 'assets/img/cat/ac.png';
  if (lc.startsWith('les')) return 'assets/img/cat/les.png';
  if (lc.startsWith('foto')) return 'assets/img/cat/foto.png';
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
