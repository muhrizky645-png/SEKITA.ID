import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'widgets.dart';

const int kMaxMitra = 7;

String timeAgo(int ms) {
  if (ms <= 0) return '';
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inMinutes < 1) return 'Baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  if (d.inDays < 30) return '${d.inDays} hari lalu';
  final months = (d.inDays / 30).floor();
  if (months < 12) return '$months bln lalu';
  return '${(d.inDays / 365).floor()} thn lalu';
}

/// Buka detail sebuah kebutuhan dari layar mana pun (mis. Beranda).
void openKebutuhanDetail(
  BuildContext context,
  Kebutuhan k, {
  bool mine = false,
  VoidCallback? onChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _DetailSheet(k: k, mine: mine, onChanged: onChanged ?? () {}),
  );
}

class KebutuhanScreen extends StatefulWidget {
  const KebutuhanScreen({super.key});
  @override
  State<KebutuhanScreen> createState() => _KebutuhanScreenState();
}

class _KebutuhanScreenState extends State<KebutuhanScreen> {
  late Future<List<Kebutuhan>> _future;
  bool _mine = false;

  @override
  void initState() {
    super.initState();
    _future = Api.fetchKebutuhan();
  }

  void _load() {
    setState(() {
      _future = _mine ? Api.fetchKebutuhanMine() : Api.fetchKebutuhan();
    });
  }

  Future<void> _refresh() async {
    _load();
    await _future;
  }

  void _setMine(bool v) {
    _mine = v;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebutuhan'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Semua'), icon: Icon(Icons.public, size: 18)),
                ButtonSegment(value: true, label: Text('Postingan Saya'), icon: Icon(Icons.person_outline, size: 18)),
              ],
              selected: {_mine},
              onSelectionChanged: (s) => _setMine(s.first),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Kebutuhan>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ListView(children: const [
                      SizedBox(height: 140),
                      Center(child: Text('Gagal memuat kebutuhan.')),
                    ]);
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return ListView(children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(_mine
                            ? 'Kamu belum punya postingan.'
                            : 'Belum ada kebutuhan yang diposting.'),
                      ),
                    ]);
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: list.map((k) => _card(k)).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isMine(Kebutuhan k) {
    if (_mine) return true;
    final u = Api.currentUser;
    return u != null && k.pembeliId.isNotEmpty && k.pembeliId == '${u.id}';
  }

  void _openDetail(Kebutuhan k) {
    openKebutuhanDetail(context, k, mine: _isMine(k), onChanged: _load);
  }

  Widget _statusChip(String t, Color bg, Color fg) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _card(Kebutuhan k) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openDetail(k),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(k.ic, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(k.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        if (k.isDone)
                          _statusChip('Selesai', const Color(0xFFDCFCE7), const Color(0xFF166534))
                        else
                          _statusChip('Terbuka', const Color(0xFFEFF4FF), kBrand),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${k.cat.isEmpty ? 'Umum' : k.cat} \u00b7 ${k.loc.isEmpty ? '-' : k.loc}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    if (k.budget.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Budget: ${k.budget}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(k.pembeliNama.isEmpty ? 'Pengguna' : k.pembeliNama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ),
                        const SizedBox(width: 8),
                        Text('\u00b7 ${timeAgo(k.ts)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                    if (k.contactedCount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${k.contactedCount} mitra menghubungi',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  final Kebutuhan k;
  final bool mine;
  final VoidCallback onChanged;
  const _DetailSheet({required this.k, required this.mine, required this.onChanged});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  late String _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _status = widget.k.status;
  }

  bool get _done => _status == 'done';

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _reopen() async {
    setState(() => _busy = true);
    final r = await Api.setKebutuhanStatus(widget.k.id, false);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      setState(() => _status = 'open');
      widget.onChanged();
      _snack('Kebutuhan dibuka lagi.');
    } else {
      _snack(r.error);
    }
  }

  Future<void> _openReview({required bool alreadyDone}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewFlowSheet(k: widget.k, alreadyDone: alreadyDone),
    );
    if (changed == true && mounted) {
      setState(() => _status = 'done');
      widget.onChanged();
      _snack(alreadyDone ? 'Ulasan terkirim. Makasih!' : 'Kebutuhan ditandai selesai.');
    }
  }

  Future<void> _openEdit() async {
    final messenger = ScaffoldMessenger.of(context);
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditSheet(k: widget.k),
    );
    if (changed == true && mounted) {
      widget.onChanged();
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Postingan diperbarui.')));
    }
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus postingan?'),
        content: const Text('Postingan ini akan dihapus permanen dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final r = await Api.hapusKebutuhan(widget.k.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      widget.onChanged();
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Postingan dihapus.')));
    } else {
      _snack(r.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.k;
    final cc = k.contactedCount;
    final pct = (cc / kMaxMitra).clamp(0.0, 1.0);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.ic, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(k.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                    if (_done)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _row(Icons.category_outlined, k.cat.isEmpty ? 'Umum' : k.cat),
                _row(Icons.location_on_outlined, k.loc.isEmpty ? '-' : k.loc),
                if (k.budget.isNotEmpty) _row(Icons.payments_outlined, k.budget),
                _row(Icons.person_outline, k.pembeliNama.isEmpty ? 'Pengguna' : k.pembeliNama),
                _row(Icons.schedule, timeAgo(k.ts)),
                if (k.deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(k.deskripsi, style: const TextStyle(height: 1.5, color: Color(0xFF374151))),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _done ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECF3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_done ? '\u2705' : '\ud83e\udd1d', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _done ? 'Kebutuhan ini sudah selesai' : 'Sudah ditawar $cc dari $kMaxMitra mitra',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            if (!_done) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  color: kBrand,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.mine) ...[
                  const SizedBox(height: 16),
                  if (!_done)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _openReview(alreadyDone: false),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Tandai kebutuhan ini selesai'),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _openReview(alreadyDone: true),
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Beri ulasan'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _reopen,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Buka lagi kebutuhan ini'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _openEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit postingan'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        backgroundColor: const Color(0xFFFEE2E2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus postingan ini'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData ic, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(ic, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
}

class _EditSheet extends StatefulWidget {
  final Kebutuhan k;
  const _EditSheet({required this.k});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _lokasi;
  late final TextEditingController _budget;
  late final TextEditingController _wa;
  late final TextEditingController _deskripsi;
  late String _kategori;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final k = widget.k;
    _title = TextEditingController(text: k.title);
    _lokasi = TextEditingController(text: k.loc);
    _budget = TextEditingController(text: k.budget);
    _wa = TextEditingController(text: k.wa);
    _deskripsi = TextEditingController(text: k.deskripsi);
    _kategori = k.cat.isEmpty ? Api.kategoriDasar.first : k.cat;
  }

  @override
  void dispose() {
    _title.dispose();
    _lokasi.dispose();
    _budget.dispose();
    _wa.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final lokasi = _lokasi.text.trim();
    if (title.isEmpty || lokasi.isEmpty) {
      _snack('Judul dan lokasi wajib diisi.');
      return;
    }
    setState(() => _busy = true);
    final r = await Api.editKebutuhan(
      id: widget.k.id,
      title: title,
      kategori: _kategori,
      lokasi: lokasi,
      deskripsi: _deskripsi.text.trim(),
      budget: _budget.text.trim(),
      wa: _wa.text.trim(),
      ic: widget.k.ic,
      bg: widget.k.bg,
      waktu: widget.k.waktu,
    );
    if (!mounted) return;
    if (r.ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _busy = false);
      _snack(r.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = Api.kategoriDasar.contains(_kategori)
        ? Api.kategoriDasar
        : <String>[_kategori, ...Api.kategoriDasar];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Edit postingan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 14),
                _label('Judul kebutuhan'),
                TextField(controller: _title, decoration: _dec('Mis. Butuh tukang servis AC')),
                const SizedBox(height: 12),
                _label('Kategori'),
                DropdownButtonFormField<String>(
                  initialValue: _kategori,
                  isExpanded: true,
                  decoration: _dec('Pilih kategori'),
                  items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: _busy ? null : (v) => setState(() => _kategori = v ?? _kategori),
                ),
                const SizedBox(height: 12),
                _label('Lokasi'),
                TextField(controller: _lokasi, decoration: _dec('Mis. Sleman, Yogyakarta')),
                const SizedBox(height: 12),
                _label('Perkiraan budget (opsional)'),
                TextField(controller: _budget, decoration: _dec('Mis. Rp100.000 (nego)')),
                const SizedBox(height: 12),
                _label('Nomor WhatsApp'),
                TextField(controller: _wa, keyboardType: TextInputType.phone, decoration: _dec('08xxxxxxxxxx')),
                const SizedBox(height: 12),
                _label('Deskripsi (opsional)'),
                TextField(controller: _deskripsi, maxLines: 4, decoration: _dec('Jelaskan detail kebutuhanmu\u2026')),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan perubahan'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Batal')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class _ReviewFlowSheet extends StatefulWidget {
  final Kebutuhan k;
  final bool alreadyDone;
  const _ReviewFlowSheet({required this.k, required this.alreadyDone});

  @override
  State<_ReviewFlowSheet> createState() => _ReviewFlowSheetState();
}

class _ReviewFlowSheetState extends State<_ReviewFlowSheet> {
  int _step = 0;
  String _mitraId = '';
  String _mitraNama = '';
  int _rating = 5;
  final _komentar = TextEditingController();
  final _search = TextEditingController();
  List<Mitra> _all = [];
  List<Mitra> _results = [];
  bool _loadingMitra = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _preloadMitra();
  }

  @override
  void dispose() {
    _komentar.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Pra-muat daftar mitra (diam-diam) supaya tile "mitra yang menghubungi"
  /// bisa langsung tampil dengan foto profil / ikon kategori yang benar.
  Future<void> _preloadMitra() async {
    try {
      final list = await Api.fetchMitra();
      if (!mounted) return;
      setState(() => _all = list);
    } catch (_) {}
  }

  Future<void> _ensureMitra() async {
    if (_all.isNotEmpty || _loadingMitra) return;
    setState(() => _loadingMitra = true);
    try {
      _all = await Api.fetchMitra();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loadingMitra = false);
  }

  Mitra? _findMitra(String id) {
    for (final m in _all) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _onSearch(String q) {
    final s = q.trim().toLowerCase();
    setState(() {
      _results = s.isEmpty
          ? <Mitra>[]
          : _all.where((m) => m.displayName.toLowerCase().contains(s) || m.kategori.toLowerCase().contains(s)).take(8).toList();
    });
  }

  void _pick(String id, String nama) {
    setState(() {
      _mitraId = id;
      _mitraNama = nama;
      _step = 1;
    });
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _skip() async {
    setState(() => _busy = true);
    final r = await Api.setKebutuhanStatus(widget.k.id, true);
    if (!mounted) return;
    if (r.ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _busy = false);
      _snack(r.error);
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final r = await Api.tambahUlasan(
      mitraId: _mitraId,
      mitraNama: _mitraNama,
      kebutuhanId: widget.k.id,
      rating: _rating,
      komentar: _komentar.text.trim(),
      postTitle: widget.k.title,
    );
    if (!mounted) return;
    if (!r.ok) {
      setState(() => _busy = false);
      _snack(r.error);
      return;
    }
    if (!widget.alreadyDone) {
      final s = await Api.setKebutuhanStatus(widget.k.id, true);
      if (!mounted) return;
      if (!s.ok) {
        setState(() => _busy = false);
        _snack(s.error);
        return;
      }
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(child: _step == 0 ? _pickStep() : _rateStep()),
        ),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
        ),
      );

  Widget _pickStep() {
    final contacted = widget.k.contactedBy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const Text('Pilih mitra yang mengerjakan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 4),
        const Text('Pilih mitra untuk diberi ulasan, lalu kasih bintang & komentar.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 14),
        if (contacted.isNotEmpty) ...[
          const Text('Mitra yang menghubungi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          ...contacted.map((c) {
            final m = _findMitra(c.id);
            return _mitraTile(c.id, m?.displayName ?? c.nama, mitra: m);
          }),
          const SizedBox(height: 12),
        ],
        const Text('Cari mitra lain', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _search,
          onTap: _ensureMitra,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Ketik nama mitra / usaha\u2026',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_loadingMitra)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
        ..._results.map((m) => _mitraTile(m.id, m.displayName, mitra: m)),
        const SizedBox(height: 16),
        if (!widget.alreadyDone)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _busy ? null : _skip,
              child: const Text('Tandai selesai tanpa ulasan'),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Batal')),
        ),
      ],
    );
  }

  Widget _mitraTile(String id, String nama, {Mitra? mitra}) {
    final cat = mitra?.kategori ?? '';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: mitra != null
                ? MitraAvatar(m: mitra)
                : Container(
                    color: const Color(0xFFEFF4FF),
                    alignment: Alignment.center,
                    child: const Text('\ud83e\uddf0'),
                  ),
          ),
        ),
        title: Text(nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: cat.isNotEmpty
            ? Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pick(id, nama),
      ),
    );
  }

  Widget _rateStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const Text('Beri ulasan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Text('Mitra: ', style: TextStyle(color: Color(0xFF64748B))),
              Expanded(child: Text(_mitraNama, style: const TextStyle(fontWeight: FontWeight.w700))),
              TextButton(onPressed: _busy ? null : () => setState(() => _step = 0), child: const Text('ganti')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final on = i < _rating;
              return IconButton(
                onPressed: _busy ? null : () => setState(() => _rating = i + 1),
                icon: Icon(on ? Icons.star : Icons.star_border, size: 36, color: on ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1)),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _komentar,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tulis pengalamanmu dengan mitra ini\u2026',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.alreadyDone ? 'Kirim ulasan' : 'Kirim ulasan & tandai selesai'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Batal')),
        ),
      ],
    );
  }
}
