import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'core.dart';

/// Wrapper tipis untuk push notification OneSignal.
///
/// MVP: device mitra diberi tag `role=mitra` + `cat_<slug>` supaya bisa
/// menerima notifikasi lead sesuai kategori; device pembeli diberi tag
/// `role=pembeli` supaya bisa menerima notifikasi promo. Tap notifikasi lead
/// -> deep-link ke Lead.
/// Semua pemanggilan dibungkus try/catch agar tidak pernah membuat app crash
/// meski OneSignal belum siap / device tanpa Google Play Services.
class Notif {
  Notif._();

  static const String _appId = '37b4c609-8eb1-4499-8650-fd84abf09f54';
  static bool _inited = false;
  static String? _lastCatKey;

  static void Function(Map<String, dynamic> data)? _onOpen;
  static Map<String, dynamic>? _pending;

  /// Inisialisasi OneSignal. Panggil sekali di main().
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
      OneSignal.initialize(_appId);
      OneSignal.Notifications.addClickListener((event) {
        final extra = event.notification.additionalData;
        final data = extra == null ? <String, dynamic>{} : Map<String, dynamic>.from(extra);
        final cb = _onOpen;
        if (cb != null) {
          cb(data);
        } else {
          _pending = data; // simpan untuk cold-start sebelum handler siap
        }
      });
    } catch (_) {}
  }

  /// Daftarkan handler tap-notif (deep-link). Flush event yang tertunda.
  static void setOnOpen(void Function(Map<String, dynamic> data) handler) {
    _onOpen = handler;
    final p = _pending;
    if (p != null) {
      _pending = null;
      handler(p);
    }
  }

  static void clearOnOpen() {
    _onOpen = null;
  }

  /// Minta izin notifikasi (Android 13+/iOS). Aman dipanggil berulang.
  static Future<void> requestPermission() async {
    try {
      await OneSignal.Notifications.requestPermission(true);
    } catch (_) {}
  }

  /// Tandai device sebagai mitra + kategori agar menerima lead yang relevan.
  static Future<void> setMitraTags(String kategori) async {
    try {
      final canon = canonicalCat(kategori);
      final slug = isSpecificSub(canon) ? _slug(canon) : '';
      final newCatKey = slug.isEmpty ? null : 'cat_$slug';
      if (_lastCatKey != null && _lastCatKey != newCatKey) {
        await OneSignal.User.removeTags([_lastCatKey!]);
      }
      final tags = <String, String>{'role': 'mitra'};
      if (newCatKey != null) tags[newCatKey] = '1';
      await OneSignal.User.addTags(tags);
      _lastCatKey = newCatKey;
    } catch (_) {}
  }

  /// Tandai device sebagai pembeli (mode pembeli / tamu / logout) agar bisa
  /// menerima notifikasi promo. Hapus tag kategori mitra bila sebelumnya ada.
  static Future<void> setPembeliTags() async {
    try {
      if (_lastCatKey != null) {
        await OneSignal.User.removeTags([_lastCatKey!]);
        _lastCatKey = null;
      }
      await OneSignal.User.addTags(<String, String>{'role': 'pembeli'});
    } catch (_) {}
  }

  /// Hapus penanda mitra. Dipertahankan untuk kompatibilitas; mode pembeli
  /// kini pakai setPembeliTags() agar tetap bisa di-target promo.
  static Future<void> clearMitraTags() async {
    try {
      final keys = <String>['role'];
      if (_lastCatKey != null) keys.add(_lastCatKey!);
      await OneSignal.User.removeTags(keys);
      _lastCatKey = null;
    } catch (_) {}
  }

  /// Slugify kategori SAMA PERSIS dgn server (sekita_slug_tag di kebutuhan-tambah.php):
  /// lowercase -> ganti tiap runtun non-[a-z0-9] jadi '_' -> trim '_'.
  /// Contoh: 'Servis AC' -> 'servis_ac', 'AC/Kulkas' -> 'ac_kulkas'.
  static String _slug(String s) {
    final lower = s.toLowerCase().trim();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return replaced.replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
