# Petunjuk Build Sekita (Android) via Codemagic

Project ini adalah aplikasi Flutter WebView yang membungkus situs https://sekita.id.
Alurnya sama persis seperti SALDOKU: push ke GitHub -> build di Codemagic -> upload ke Play Console.

---

## Prasyarat
- Akun Codemagic (sudah ada, dipakai untuk SALDOKU).
- Akun Google Play Developer (biaya 1x $25).
- Java/keytool terpasang di komputer (untuk membuat keystore).

---

## Langkah 1 — Buat keystore (1x saja, SIMPAN baik-baik!)

Jalankan di terminal komputer:

```
keytool -genkey -v -keystore sekita-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sekita
```

- Catat **store password**, **key password**, dan **alias** (`sekita`).
- File `sekita-release.jks` ini WAJIB disimpan & dibackup. Kalau hilang, kamu tidak bisa update aplikasi yang sama di Play Store selamanya.
- JANGAN commit file ini ke GitHub (sudah otomatis diabaikan oleh .gitignore).

---

## Langkah 2 — Hubungkan repo ke Codemagic

1. Buka https://codemagic.io -> **Add application**.
2. Pilih GitHub -> repo **SEKITA.ID**.
3. Pilih tipe project **Flutter App**.

---

## Langkah 3 — Aktifkan Android code signing

Di Workflow Editor Codemagic:

1. Bagian **Distribution -> Android code signing**.
2. Upload file **sekita-release.jks**.
3. Isi:
   - Keystore password: (store password dari Langkah 1)
   - Key alias: `sekita`
   - Key password: (key password dari Langkah 1)
4. Codemagic otomatis membuat `android/key.properties` saat build — build.gradle.kts sudah disetel membacanya.

---

## Langkah 4 — Atur build

1. Build for platforms: **Android**.
2. Mode: **Release**.
3. Format output: **AAB** (Android App Bundle — wajib untuk Play Store).
   - Kalau mau tes pasang manual di HP, tambahkan juga **APK**.
4. Klik **Start new build**.

Catatan: `gradlew` & `gradle-wrapper.jar` sengaja TIDAK ada di repo (sama seperti SALDOKU). Flutter akan membuatnya otomatis saat build. Semua aman.

---

## Langkah 5 — Download hasil & upload ke Play Console

1. Setelah build sukses, download **app-release.aab**.
2. Buka https://play.google.com/console -> **Create app**.
   - Nama: Sekita
   - Bahasa default: Bahasa Indonesia
   - Tipe: App, Gratis
3. Buat rilis (Internal testing dulu disarankan) -> upload AAB.
4. Lengkapi yang diminta Play Console:
   - **Privacy policy:** https://sekita.id/kebijakan-privasi.html
   - **Data safety:** aplikasi mengumpulkan nomor WhatsApp & email (untuk menghubungkan pembeli & mitra).
   - **Content rating:** isi kuesioner.
   - **App icon & screenshot:** ambil dari sekita.id.
5. Kirim untuk review.

---

## Identitas aplikasi
| | |
|---|---|
| applicationId | `id.sekita.app` |
| Nama | Sekita |
| Versi | 1.0.0+1 |
| URL | https://sekita.id/?src=app |
| Keystore alias | `sekita` |

## Update versi berikutnya
Naikkan `version:` di `pubspec.yaml`, contoh `1.0.1+2` (angka setelah `+` = versionCode, harus selalu naik), lalu build ulang di Codemagic.

## Mengganti ikon ke logo asli
Ikon default saat ini berupa vektor (kaca pembesar putih di latar biru). Untuk memakai logo asli Sekita:
1. Tambahkan paket `flutter_launcher_icons` di pubspec.
2. Taruh `assets/icon/ic_launcher.png` (512x512).
3. Jalankan `dart run flutter_launcher_icons`.
