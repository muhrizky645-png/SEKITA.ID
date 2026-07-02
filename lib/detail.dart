import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late Future<String> _cover;

  @override
  void initState() {
    super.initState();
    _porto = Api.fetchPortfolio(widget.mitra.id);
    _ulasan = Api.fetchUlasan(widget.mitra.id);
    _cover = Api.fetchCover(widget.mitra.id);
    Api.catatLihat(widget.mitra.id); // hitung 1 kali dilihat
  }

  void _shareProfile(Mitra m) {
    final link = 'https://' 'sekita.id/profil-mitra.php?id=${m.id}';
    Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link profil mitra disalin — tempel untuk membagikan'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mitra;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Bagikan',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareProfile(m),
          ),
        ],
      ),
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

  // ── Header: foto sampul + avatar overlap + info ──────────────────────
  Widget _head(Mitra m) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 188,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(top: 0, left: 0, right: 0, child: _coverView()),
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: MitraAvatar(m: m),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 19)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
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
                      child: Text(m.kategori,
                          style: const TextStyle(
                              fontSize: 12,
                              color: kBrand,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (m.verified >= 1) _verifBadge(m),
                    if (m.perdanaNo != null) _perdanaBadge(m),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(m.lokasi.isEmpty ? '-' : m.lokasi,
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ),
                    if (m.rating > 0) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.star, size: 15, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(m.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverView() {
    return FutureBuilder<String>(
      future: _cover,
      builder: (context, snap) {
        final cover = snap.data ?? '';
        return Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kBrand, kBrandDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: cover.isEmpty
              ? null
              : SekitaImage(cover, fit: BoxFit.cover),
        );
      },
    );
  }

  // Badge verif berketerangan — tap untuk lihat penjelasan tingkat.
  Widget _verifBadge(Mitra m) {
    final t = verifTierFor(m.verified);
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.verified, color: t.color),
              const SizedBox(width: 8),
              Expanded(child: Text('Mitra ${t.label}')),
            ],
          ),
          content: Text(t.desc, style: const TextStyle(height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: t.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 14, color: t.color),
            const SizedBox(width: 5),
            Text('Mitra ${t.label}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.color)),
            const SizedBox(width: 4),
            Icon(Icons.info_outline,
                size: 13, color: t.color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  // Badge Mitra Perdana — 100 pendaftar pertama (bonus peluncuran).
  Widget _perdanaBadge(Mitra m) {
    const gold = Color(0xFFB45309);
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.workspace_premium, color: gold),
              SizedBox(width: 8),
              Expanded(child: Text('Mitra Perdana')),
            ],
          ),
          content: Text(
            m.perdanaNo != null
                ? 'Salah satu dari 100 mitra pertama yang bergabung di Sekita (mitra ke-${m.perdanaNo}). Terima kasih sudah menjadi pelopor!'
                : 'Salah satu dari 100 mitra pertama yang bergabung di Sekita.',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.workspace_premium, size: 14, color: gold),
            SizedBox(width: 5),
            Text('Mitra Perdana',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: gold)),
          ],
        ),
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
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _PhotoViewer(images: imgs, index: i),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 120, height: 120, child: SekitaImage(imgs[i])),
              ),
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
            icon: const Icon(Icons.chat, color: Colors.white, size: 22),
            label: const Text('WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}

// ── Penampil foto portofolio layar penuh (pinch-zoom + geser) ───────────
class _PhotoViewer extends StatefulWidget {
  final List<String> images;
  final int index;
  const _PhotoViewer({required this.images, required this.index});
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pc;
  late int _cur;

  @override
  void initState() {
    super.initState();
    _cur = widget.index;
    _pc = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_cur + 1} / ${widget.images.length}',
            style: const TextStyle(fontSize: 14, color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pc,
        onPageChanged: (i) => setState(() => _cur = i),
        itemCount: widget.images.length,
        itemBuilder: (_, i) => Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: SekitaImage(widget.images[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
