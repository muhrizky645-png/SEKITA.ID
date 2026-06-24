# Sekita App

Aplikasi Android resmi **Sekita** — marketplace jasa lokal Yogyakarta.

Aplikasi ini adalah **pembungkus WebView** dari situs https://sekita.id (PWA), dibangun dengan Flutter dan di-build di Codemagic (alur sama seperti SALDOKU).

## Ringkas

| | |
|---|---|
| Package / applicationId | `id.sekita.app` |
| Nama aplikasi | Sekita |
| Versi | 1.0.0+1 |
| URL dimuat | https://sekita.id/?src=app |
| Build | Codemagic (Flutter Workflow) |
| Signing | `android/key.properties` (dibuat otomatis oleh Codemagic) |

## Build

Lihat **PETUNJUK_BUILD_SEKITA.md** untuk langkah lengkap (Codemagic + keystore + Play Console).

## Catatan ikon

Ikon default berupa vektor brand (kaca pembesar putih di latar biru `#2563EB`). Untuk memakai logo asli, ganti file vektor di `android/app/src/main/res/` atau pakai paket `flutter_launcher_icons`.
