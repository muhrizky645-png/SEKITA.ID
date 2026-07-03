import 'dart:convert';
import 'package:flutter/material.dart';
import 'core.dart';
import 'models.dart';

/// Kartu mitra bergaya web sekita.id: cover di atas, avatar overlap, nama +
/// badge tier verifikasi, chip kategori, lokasi & rating. Tap -> detail.
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
    final cover = m.portfolioThumb.isNotEmpty ? m.portfolioThumb.first : '';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kLine),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover + avatar overlap (gaya web)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 92,
                      width: double.infinity,
                      child: cover.isEmpty
                          ? const DecoratedBox(
                              decoration: BoxDecoration(gradient: kBrandGradient))
                          : SekitaImage(cover, fit: BoxFit.cover),
                    ),
                    Positioned(
                      left: 12,
                      bottom: -24,
                      child: Container(
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: MitraAvatar(m: m),
                        ),
                      ),
                    ),
                  ],
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 30, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15.5),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m.kategori,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: kBrand,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (m.verified > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tier.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified,
                                      size: 12, color: tier.color),
                                  const SizedBox(width: 3),
                                  Text('Mitra ${tier.label}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: tier.color)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              m.lokasi.isEmpty ? '-' : m.lokasi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                          if (m.rating > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star,
                                size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(m.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (spon)
              Positioned(
                right: 12,
                bottom: 10,
                child: Text(
                  'Sponsor',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
