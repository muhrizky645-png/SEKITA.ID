import 'dart:convert';
import 'package:flutter/material.dart';
import 'core.dart';
import 'models.dart';

/// Kartu mitra bergaya web sekita.id (grid 2 kolom): foto profil/ikon kategori
/// di atas (kotak), lalu nama + centang tier, chip kategori, lokasi & rating.
class MitraCard extends StatelessWidget {
  final Mitra m;
  final VoidCallback onTap;
  /// Permukaan tempat kartu tampil: 'beranda' / 'kategori'. Menentukan apakah
  /// badge "Sponsor" muncul sesuai paket sponsor mitra. Bila null -> pakai
  /// status promoted apa adanya.
  final String? surface;
  const MitraCard({super.key, required this.m, required this.onTap, this.surface});

  @override
  Widget build(BuildContext context) {
    final spon = surface == null ? m.promoted > 0 : sponsorOn(m, surface!);
    final tier = verifTierFor(m.verified);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto profil / ikon kategori (kotak, seperti web)
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _cover()),
                    if (m.perdanaNo != null)
                      Positioned(top: 8, right: 8, child: _perdanaPill()),
                    if (spon)
                      Positioned(bottom: 6, right: 8, child: _sponsorTag()),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                        if (m.verified > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Icon(Icons.verified,
                                size: 14, color: tier.color),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _catChip(),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            m.lokasi.isEmpty ? '-' : m.lokasi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: Colors.grey[600], fontSize: 11),
                          ),
                        ),
                        if (m.rating > 0) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star,
                              size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(m.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Gambar kartu: foto profil mitra (avatar). Kalau kosong -> kotak biru muda
  // + ikon kategori (tidak memakai foto portofolio).
  Widget _cover() {
    if (m.avatar.isNotEmpty) {
      return MitraAvatar(m: m);
    }
    return Container(
      color: const Color(0xFFEEF2F7),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: SekitaImage(catIconPath(m.kategori), fit: BoxFit.contain),
    );
  }

  Widget _catChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: SekitaImage(catIconPath(m.kategori), fit: BoxFit.contain),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              m.kategori,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10.5, color: kBrand, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perdanaPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE9C8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF5CE93)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.workspace_premium, size: 11, color: Color(0xFFB45309)),
            SizedBox(width: 3),
            Text('Perdana',
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309))),
          ],
        ),
      );

  Widget _sponsorTag() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Sponsor',
          style: TextStyle(
            fontSize: 9,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: Colors.grey.withOpacity(0.9),
          ),
        ),
      );
}

class MitraAvatar extends StatelessWidget {
  final Mitra m;
  const MitraAvatar({super.key, required this.m});

  Widget _catIcon() => Container(
        color: const Color(0xFFEFF4FF),
        padding: const EdgeInsets.all(10),
        child: SekitaImage(catIconPath(m.kategori), fit: BoxFit.contain),
      );

  @override
  Widget build(BuildContext context) {
    final src = m.avatar.isNotEmpty
        ? m.avatar
        : (m.portfolioThumb.isNotEmpty ? m.portfolioThumb.first : '');

    // Tidak ada foto -> langsung icon kategori
    if (src.isEmpty) return _catIcon();

    // Base64 inline
    if (src.startsWith('data:image')) {
      try {
        final b64 = src.substring(src.indexOf(',') + 1);
        return Image.memory(base64Decode(b64),
            fit: BoxFit.cover, gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _catIcon());
      } catch (_) {
        return _catIcon();
      }
    }

    // URL biasa/relatif -> normalize lalu load, fallback ke icon kategori
    var url = src;
    if (!url.startsWith('http')) {
      final host = 'https://' + 'sekita.id/';
      url = host + url.replaceFirst(RegExp(r'^/'), '');
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _catIcon(),
      loadingBuilder: (c, child, progress) =>
          progress == null ? child : Container(color: const Color(0xFFE5E7EB)),
    );
  }
}

/// Avatar untuk sebuah Kebutuhan/Lead: pakai foto pelanggan bila ada, jika
/// tidak tampilkan ikon kategori (selaras dengan MitraAvatar & web).
class KebutuhanAvatar extends StatelessWidget {
  final Kebutuhan k;
  const KebutuhanAvatar({super.key, required this.k});

  Widget _catIcon() => Container(
        color: const Color(0xFFEFF4FF),
        padding: const EdgeInsets.all(9),
        child: SekitaImage(catIconPath(k.cat), fit: BoxFit.contain),
      );

  @override
  Widget build(BuildContext context) {
    final src = k.pembeliAvatar.trim();

    // Tidak ada foto pelanggan -> ikon kategori
    if (src.isEmpty) return _catIcon();

    // Base64 inline
    if (src.startsWith('data:image')) {
      try {
        final b64 = src.substring(src.indexOf(',') + 1);
        return Image.memory(base64Decode(b64),
            fit: BoxFit.cover, gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _catIcon());
      } catch (_) {
        return _catIcon();
      }
    }

    // URL biasa/relatif -> normalize lalu load, fallback ke ikon kategori
    var url = src;
    if (!url.startsWith('http')) {
      final host = 'https://' + 'sekita.id/';
      url = host + url.replaceFirst(RegExp(r'^/'), '');
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _catIcon(),
      loadingBuilder: (c, child, progress) =>
          progress == null ? child : Container(color: const Color(0xFFE5E7EB)),
    );
  }
}
