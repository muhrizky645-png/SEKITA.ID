import 'package:flutter/material.dart';
import 'core.dart';
import 'models.dart';

class MitraCard extends StatelessWidget {
  final Mitra m;
  final VoidCallback onTap;
  const MitraCard({super.key, required this.m, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 64, height: 64, child: MitraAvatar(m: m)),
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
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child:
                                Icon(Icons.verified, size: 16, color: kBrand),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(m.kategori,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13)),
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
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (m.promoted > 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Sponsor',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MitraAvatar extends StatelessWidget {
  final Mitra m;
  const MitraAvatar({super.key, required this.m});

  @override
  Widget build(BuildContext context) {
    final src = m.avatar.isNotEmpty
        ? m.avatar
        : (m.portfolioThumb.isNotEmpty ? m.portfolioThumb.first : '');
    if (src.isNotEmpty) return SekitaImage(src, fit: BoxFit.cover);

    // Placeholder: gradient + icon orang
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFBFD4FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // lingkaran latar belakang
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kBrand.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(Icons.person_rounded, color: kBrand, size: 28),
        ],
      ),
    );
  }
}
