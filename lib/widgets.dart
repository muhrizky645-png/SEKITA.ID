import 'dart:convert';
import 'package:flutter/material.dart';
import 'core.dart';
import 'models.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        SizedBox(width: 64, height: 64, child: MitraAvatar(m: m)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                            if (m.verified > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified,
                                    size: 16,
                                    color: verifTierFor(m.verified).color),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(m.kategori,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 13)),
                        const SizedBox(height: 5),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
