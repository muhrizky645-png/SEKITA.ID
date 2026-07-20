SEKITA — Update: Katalog / Daftar Harga di aplikasi (Flutter)
=============================================================

Fitur ini menambahkan "Katalog / Daftar Harga" mitra ke APLIKASI,
menyamai yang sudah ada di web (tabel mitra_item). Sudah termasuk:

- Mitra bisa TAMBAH / EDIT / HAPUS item katalog dari aplikasi.
  (Detail Toko  ->  kartu "Katalog / Daftar Harga"  ->  Kelola Katalog)
  Tiap item: jenis (Jasa/Barang/Paket), judul, tipe harga
  (pasti / mulai dari / nego), harga, satuan, stok (khusus barang),
  foto, deskripsi, dan tombol aktif/nonaktif.
- Katalog tampil di halaman profil mitra yang dilihat pembeli,
  lengkap dengan tombol "Pilih" -> chat WhatsApp berisi nama item.

Sisi WEB TIDAK diubah: endpoint sudah ada
(api/mitra-item-list.php, mitra-item-save.php, mitra-item-hapus.php,
item-lib.php). Jadi tidak perlu upload apa pun ke cPanel untuk fitur ini.

File aplikasi yang berubah / baru (letakkan menimpa yang lama):
  lib/models.dart      (+ class MitraItem)
  lib/api.dart         (+ Api.fetchMitraItems)
  lib/mitra_api.dart   (+ ambilItemSaya / simpanItem / hapusItem)
  lib/toko.dart        (+ kartu & tombol Kelola Katalog)
  lib/detail.dart      (+ tampilan katalog di profil mitra)
  lib/katalog.dart     (BARU — layar kelola katalog + form item)

Cara commit (repo aplikasi saja):
  cd C:\Users\USER\SEKITA.ID
  git add lib/models.dart lib/api.dart lib/mitra_api.dart lib/toko.dart lib/detail.dart lib/katalog.dart
  git commit -m "Tambah katalog layanan (daftar harga) di aplikasi"
  git push

Uji dulu sebelum commit (opsional):
  flutter run
