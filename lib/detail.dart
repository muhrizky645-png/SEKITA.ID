import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'widgets.dart';

class MitraDetailScreen extends StatefulWidget {
  final Mitra mitra;
  const MitraDetailScreen({super.key, required this.mitra});
  @override
  State<MitraDetailScreen> createState() => _MitraDetailScreenState();
}

class _MitraDetailScreenState extends State<MitraDetailScreen> {
  late Future<List<String>> _porto;
  late Future<List<Ulasan>> _ulasan;

  @override
  void initState() {
    super.initState();
    _porto = Api.fetchPortfolio(widget.mitra.id);
    _ulasan = Api.fetchUlasan(widget.mitra.id);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mitra;
    return Scaffold(
      appBar: AppBar(title: Text(m.displayName, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _head(m),
          if (m.deskripsi.isNotEmpty) ...[
            _title('Tentang'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(m.deskripsi, style: const TextStyle(height: 1.5, color: Color(0xFF374151))),
            ),
          ],
          _title('Portofolio'),
          _portoView(),
          _title('Ulasan'),
          _ulasanView(),
        ],
      ),
      bottomNavigationBar: _waButton(m),
    );
  }

  Widget _head(Mitra m) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: 80, height: 80, child: MitraAvatar(m: m)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(m.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                    if (m.verified > 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Icon(Icons.verified, size: 18, color: kBrand),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(m.kategori,
                      style: const TextStyle(fontSize: 12, color: kBrand, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(m.lokasi.isEmpty ? '-' : m.lokasi,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ),
                  ],
                ),
                if (m.rating > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 15, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(m.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      );

  Widget _portoView() {
    return FutureBuilder<List<String>>(
      future: _porto,
      builder: (context, snap) {
        final imgs = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        if (imgs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Belum ada foto portofolio.', style: TextStyle(color: Colors.grey[600])),
          );
        }
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: imgs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 120, height: 120, child: SekitaImage(imgs[i])),
            ),
          ),
        );
      },
    );
  }

  Widget _ulasanView() {
    return FutureBuilder<List<Ulasan>>(
      future: _ulasan,
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text('Belum ada ulasan.', style: TextStyle(color: Colors.grey[600])),
          );
        }
        return Column(
          children: list.map((u) {
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(u.pembeliNama, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < u.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (u.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(u.text, style: const TextStyle(color: Color(0xFF374151), height: 1.4)),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _waButton(Mitra m) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: m.wa.isEmpty
                ? null
                : () => openWa(m.wa,
                    text: 'Halo ${m.displayName}, saya menemukan Anda di aplikasi Sekita. '
                        'Saya tertarik dengan jasa ${m.kategori}.'),
            icon: const Icon(Icons.chat),
            label: const Text('Hubungi via WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
