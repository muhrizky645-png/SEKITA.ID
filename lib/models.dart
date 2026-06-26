class Mitra {
  final String id;
  final String nama;
  final String usaha;
  final String kategori;
  final String lokasi;
  final String deskripsi;
  final String wa;
  final String avatar;
  final int verified;
  final int kontak;
  final double rating;
  final int promoted;
  final String sponsorPlan;
  final int? perdanaNo;
  final List<String> portfolioThumb;

  Mitra({
    required this.id,
    required this.nama,
    required this.usaha,
    required this.kategori,
    required this.lokasi,
    required this.deskripsi,
    required this.wa,
    required this.avatar,
    required this.verified,
    required this.kontak,
    required this.rating,
    required this.promoted,
    required this.sponsorPlan,
    required this.perdanaNo,
    required this.portfolioThumb,
  });

  String get displayName => usaha.isNotEmpty ? usaha : nama;

  factory Mitra.fromJson(Map<String, dynamic> j) {
    double toD(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
    int toI(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
    final pt = j['portfolioThumb'];
    final thumbs = pt is List ? pt.map((e) => '$e').toList() : <String>[];
    return Mitra(
      id: '${j['id'] ?? ''}',
      nama: '${j['nama'] ?? ''}',
      usaha: '${j['usaha'] ?? ''}',
      kategori: '${j['kategori'] ?? ''}',
      lokasi: '${j['lokasi'] ?? ''}',
      deskripsi: '${j['deskripsi'] ?? ''}',
      wa: '${j['wa'] ?? ''}',
      avatar: '${j['avatar'] ?? ''}',
      verified: toI(j['verified']),
      kontak: toI(j['kontak']),
      rating: toD(j['rating']),
      promoted: toI(j['promoted']),
      sponsorPlan: j['sponsorPlan'] == null ? '' : '${j['sponsorPlan']}',
      perdanaNo: j['perdanaNo'] == null ? null : toI(j['perdanaNo']),
      portfolioThumb: thumbs,
    );
  }
}

class Ulasan {
  final String id;
  final String mitraId;
  final String pembeliNama;
  final int rating;
  final String text;

  Ulasan({
    required this.id,
    required this.mitraId,
    required this.pembeliNama,
    required this.rating,
    required this.text,
  });

  factory Ulasan.fromJson(Map<String, dynamic> j) {
    int toI(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
    return Ulasan(
      id: '${j['id'] ?? ''}',
      mitraId: '${j['mitraId'] ?? ''}',
      pembeliNama: '${j['pembeliNama'] ?? 'Pembeli'}',
      rating: toI(j['rating']),
      text: '${j['text'] ?? ''}',
    );
  }
}

class KontakMitra {
  final String id;
  final String nama;

  KontakMitra({required this.id, required this.nama});

  factory KontakMitra.fromJson(Map<String, dynamic> j) => KontakMitra(
        id: '${j['mitraId'] ?? ''}',
        nama: '${j['nama'] ?? 'Mitra'}',
      );
}

class Kebutuhan {
  final String id;
  final String title;
  final String loc;
  final String cat;
  final String ic;
  final String budget;
  final String deskripsi;
  final String status;
  final int ts;
  final String pembeliNama;
  final String pembeliId;
  final String wa;
  final List<KontakMitra> contactedBy;
  final int contactedCount;

  Kebutuhan({
    required this.id,
    required this.title,
    required this.loc,
    required this.cat,
    required this.ic,
    required this.budget,
    required this.deskripsi,
    required this.status,
    required this.ts,
    required this.pembeliNama,
    required this.pembeliId,
    required this.wa,
    required this.contactedBy,
    required this.contactedCount,
  });

  bool get isDone => status == 'done';

  factory Kebutuhan.fromJson(Map<String, dynamic> j) {
    int toI(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
    final p = j['pembeli'];
    final nama = (p is Map && p['nama'] != null) ? '${p['nama']}' : '';
    final pid = (p is Map && p['id'] != null) ? '${p['id']}' : '';
    final cb = j['contactedBy'];
    final contacts = cb is List
        ? cb.map((e) => KontakMitra.fromJson(e as Map<String, dynamic>)).toList()
        : <KontakMitra>[];
    return Kebutuhan(
      id: '${j['id'] ?? ''}',
      title: '${j['title'] ?? ''}',
      loc: '${j['loc'] ?? ''}',
      cat: '${j['cat'] ?? ''}',
      ic: '${j['ic'] ?? '\ud83d\udcdd'}',
      budget: '${j['budget'] ?? ''}',
      deskripsi: '${j['deskripsi'] ?? ''}',
      status: '${j['status'] ?? 'open'}',
      ts: toI(j['ts']),
      pembeliNama: nama,
      pembeliId: pid,
      wa: '${j['wa'] ?? ''}',
      contactedBy: contacts,
      contactedCount: contacts.length,
    );
  }
}

class Pembeli {
  final int id;
  final String nama;
  final String wa;
  final String email;
  final String avatar;
  final int verified;

  Pembeli({
    required this.id,
    required this.nama,
    required this.wa,
    required this.email,
    required this.avatar,
    required this.verified,
  });

  factory Pembeli.fromJson(Map<String, dynamic> j) {
    int toI(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
    return Pembeli(
      id: toI(j['id']),
      nama: '${j['nama'] ?? ''}',
      wa: '${j['wa'] ?? ''}',
      email: j['email'] == null ? '' : '${j['email']}',
      avatar: '${j['avatar'] ?? ''}',
      verified: toI(j['verified']),
    );
  }
}
