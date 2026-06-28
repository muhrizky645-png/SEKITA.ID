import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'widgets.dart';
import 'verif_mitra.dart';
import 'lupa_password.dart';
import 'riwayat_kontak.dart';

const String _adminWa = '089607620368';
const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);
const Color _green = Color(0xFF16A34A);
const int _kMaxMitra = 7;

/// Normalisasi kategori "Lainnya (xxx)" -> "lainnya" untuk pencocokan.
String _catBase(String c) => c.split('(').first.trim().toLowerCase();

/// true jika kebutuhan kategori [cat] di luar bidang mitra yang sedang login.
/// Mitra tanpa kategori dianggap umum (boleh menghubungi semua lead).
bool _outOfCategory(String cat) {
  final mine = Api.currentMitra?.kategori ?? '';
  if (mine.trim().isEmpty || cat.trim().isEmpty) return false;
  return _catBase(cat) != _catBase(mine);
}

/// Popup konfirmasi bergaya web: kartu putih, ikon besar, tombol hijau.
/// Mengembalikan true bila tombol utama ditekan.
Future<bool> _waModal(
  BuildContext context, {
  required Widget icon,
  required String title,
  required String body,
  required String go,
  String sec = '',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: kInk)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 14.5, height: 1.55)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text(go, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            if (sec.isNotEmpty) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(sec, style: const TextStyle(color: _muted, fontSize: 13.5)),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  return r == true;
}

/// Ikon WhatsApp besar untuk header popup (pakai aset, fallback ikon hijau).
Widget _waBigIcon() => Image.asset(
      'assets/img/wa.png',
      width: 54,
      height: 54,
      errorBuilder: (_, __, ___) => const Icon(Icons.chat, size: 54, color: _green),
    );

/// Kartu putih membungkus daftar baris menu (dengan pemisah tipis).
Widget _menuCard(List<Widget> rows) {
  final children = <Widget>[];
  for (var i = 0; i < rows.length; i++) {
    if (i > 0) {
      children.add(const Divider(height: 1, thickness: 1, indent: 60, color: _line));
    }
    children.add(rows[i]);
  }
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
    ),
    child: Column(children: children),
  );
}

class _MitraRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _MitraRow(this.icon, this.color, this.title, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kInk)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted),
          ],
        ),
      ),
    );
  }
}

// =================== LEAD ===================

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});
  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  late Future<List<Kebutuhan>> _future;
  bool _onlyMine = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Kebutuhan>> _load() {
    return Api.fetchLeads(
      kategori: Api.currentMitra?.kategori,
      onlyMyCategory: _onlyMine,
    );
  }

  Future<void> _refresh() async {
    await Api.me();
    if (mounted) setState(() => _future = _load());
  }

  void _reload() => setState(() => _future = _load());

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _openDetail(Kebutuhan k) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LeadDetailSheet(k: k, onHubungi: () => _hubungi(k)),
    );
  }

  Future<void> _hubungi(Kebutuhan k) async {
    // Lead di luar kategori mitra tidak boleh dihubungi (samakan dengan web).
    if (_outOfCategory(k.cat)) {
      await _waModal(
        context,
        icon: const Text('\u{1F64F}', style: TextStyle(fontSize: 46)),
        title: 'Di luar bidang keahlianmu',
        body: 'Kebutuhan ini di luar kategori keahlianmu. Tambah kategori di profil mitra kalau kamu memang melayani ini.',
        go: 'Mengerti',
      );
      return;
    }

    // Saldo Kontak habis -> popup isi ulang (teks & gaya seperti web).
    final saldo = Api.currentMitra?.kuota ?? 0;
    if (saldo <= 0) {
      final go = await _waModal(
        context,
        icon: const Text('\u{1F4ED}', style: TextStyle(fontSize: 46)),
        title: 'Kontak Tersedia habis',
        body: 'Isi ulang dulu biar bisa buka WhatsApp pelanggan.',
        go: 'Lihat Paket Kontak',
        sec: 'Nanti dulu',
      );
      if (go) _isiUlang();
      return;
    }

    final ok = await _waModal(
      context,
      icon: _waBigIcon(),
      title: 'Lanjut chat WhatsApp?',
      body: 'Kalau lanjut, 1 Kontak Tersedia kepakai ya.',
      go: 'Lanjut buka WhatsApp',
      sec: 'Batal',
    );
    if (!ok) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final r = await Api.kontakLead(k.id);
    if (mounted) Navigator.pop(context);

    if (!r.ok) {
      if (r.reason == 'no_quota') {
        _isiUlang();
      } else if (r.reason == 'full') {
        _snack('Lead ini sudah penuh penawar.');
        _reload();
      } else {
        _snack(r.error);
      }
      return;
    }

    Api.setMitraKuota(r.kuota);
    if (mounted) setState(() {});
    final loc = k.loc.isNotEmpty ? ' di ${k.loc}' : '';
    await openWa(
      k.wa,
      text: 'Halo, saya mitra Sekita. Saya tertarik membantu kebutuhan \"${k.title}\"$loc. Apakah masih dibutuhkan?',
    );
    if (r.deducted) {
      _snack('WhatsApp kebuka. 1 Kontak Tersedia kepakai. Sisa: ${r.kuota} Kontak.');
    } else {
      _snack('WhatsApp kebuka. Tidak ada Kontak terpakai (sudah dihubungi <24 jam).');
    }
  }

  Future<void> _isiUlang() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saldo Kontak habis'),
        content: const Text('Hubungi admin untuk isi ulang saldo Kontak kamu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nanti')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hubungi Admin')),
        ],
      ),
    );
    if (go == true) {
      await openWa(_adminWa, text: 'Halo admin Sekita, saya mau isi ulang saldo Kontak untuk akun mitra saya.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = Api.currentMitra;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Lead'),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kBrand.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, size: 16, color: kBrand),
                  const SizedBox(width: 4),
                  Text('${m?.kuota ?? 0} Kontak', style: const TextStyle(color: kBrand, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Kebutuhan pelanggan yang sedang mencari penyedia jasa.', style: TextStyle(color: _muted, fontSize: 13)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Sesuai kategoriku'),
                  selected: _onlyMine,
                  onSelected: (_) {
                    setState(() => _onlyMine = true);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: !_onlyMine,
                  onSelected: (_) {
                    setState(() => _onlyMine = false);
                    _reload();
                  },
                ),
              ],
            ),
          ),
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
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Gagal memuat lead. Tarik untuk coba lagi.')),
                      ],
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.inbox_outlined, size: 48, color: _muted),
                        SizedBox(height: 8),
                        Center(child: Text('Belum ada lead untuk saat ini.', style: TextStyle(color: _muted))),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _LeadCard(k: items[i], onHubungi: () => _hubungi(items[i]), onTap: () => _openDetail(items[i])),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Kebutuhan k;
  final VoidCallback onHubungi;
  final VoidCallback onTap;
  const _LeadCard({required this.k, required this.onHubungi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final out = _outOfCategory(k.cat);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 44, height: 44, child: KebutuhanAvatar(k: k)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(k.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kInk)),
                        const SizedBox(height: 2),
                        Text('${k.cat}${k.loc.isNotEmpty ? ' \u00b7 ${k.loc}' : ''}', style: const TextStyle(color: _muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              if (k.budget.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 16, color: _muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(k.budget, style: const TextStyle(color: kInk, fontSize: 13))),
                  ],
                ),
              ],
              if (k.deskripsi.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(k.deskripsi, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 13)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: _muted),
                  const SizedBox(width: 6),
                  Text('${k.contactedCount}/$_kMaxMitra penawar', style: const TextStyle(color: _muted, fontSize: 12.5)),
                  const Spacer(),
                  if (out)
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Di luar bidang'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: onHubungi,
                      style: FilledButton.styleFrom(backgroundColor: _green),
                      icon: Image.asset('assets/img/wa.png', width: 18, height: 18, errorBuilder: (_, __, ___) => const Icon(Icons.chat_outlined, size: 18)),
                      label: const Text('WhatsApp'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadDetailSheet extends StatelessWidget {
  final Kebutuhan k;
  final VoidCallback onHubungi;
  const _LeadDetailSheet({required this.k, required this.onHubungi});

  Widget _row(IconData ic, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(ic, size: 16, color: _muted),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 14, color: kInk))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cc = k.contactedCount;
    final pct = (cc / _kMaxMitra).clamp(0.0, 1.0);
    final out = _outOfCategory(k.cat);
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(width: 44, height: 44, child: KebutuhanAvatar(k: k)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(k.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: kInk)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _row(Icons.category_outlined, k.cat.isEmpty ? 'Umum' : k.cat),
                _row(Icons.location_on_outlined, k.loc.isEmpty ? '-' : k.loc),
                if (k.budget.isNotEmpty) _row(Icons.payments_outlined, k.budget),
                _row(Icons.person_outline, k.pembeliNama.isEmpty ? 'Pengguna' : k.pembeliNama),
                if (k.waktu.isNotEmpty) _row(Icons.schedule, 'Dibutuhkan: ${k.waktu}'),
                if (k.deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                  const SizedBox(height: 4),
                  Text(k.deskripsi, style: const TextStyle(height: 1.5, color: Color(0xFF374151))),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('\ud83e\udd1d', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sudah ditawar $cc dari $_kMaxMitra mitra', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kInk)),
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
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (out) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.block, size: 20),
                      label: const Text('Di luar bidang keahlianmu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Text(
                      'Kebutuhan ini di luar kategori keahlianmu. Sekita bantu pelanggan menemukan penyedia paling sesuai. Tambah kategori di profil mitra kalau kamu memang melayani ini.',
                      style: TextStyle(color: Color(0xFF9A3412), fontSize: 12.5, height: 1.5),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onHubungi();
                      },
                      style: FilledButton.styleFrom(backgroundColor: _green),
                      icon: Image.asset('assets/img/wa.png', width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.chat_outlined, size: 20)),
                      label: const Text('Hubungi via WhatsApp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================== AKUN MITRA ===================

class AkunMitraScreen extends StatefulWidget {
  const AkunMitraScreen({super.key});
  @override
  State<AkunMitraScreen> createState() => _AkunMitraScreenState();
}

class _AkunMitraScreenState extends State<AkunMitraScreen> {
  bool _busy = false;

  Future<void> _refresh() async {
    await Api.me();
    if (mounted) setState(() {});
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _keMitraPembeli() async {
    setState(() => _busy = true);
    final r = await Api.switchRole('pembeli');
    if (mounted) setState(() => _busy = false);
    if (r.ok) return;
    if (r.reason == 'no_account') {
      _snack('Akun pembeli belum ada untuk nomor ini.');
    } else {
      _snack(r.error);
    }
  }

  Future<void> _klaimPerdana() async {
    setState(() => _busy = true);
    final r = await Api.claimPerdana();
    if (mounted) setState(() => _busy = false);
    if (r.ok) {
      _snack('Berhasil! +${r.bonus} Kontak. Saldo: ${r.kuota} Kontak.');
    } else {
      _snack(r.error);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu akan keluar dari akun mitra.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true) await Api.logout();
  }

  /// Kartu saldo Kontak bergaya dashboard web (Kontak Tersedia + paket).
  Widget _kontakCard(BuildContext context, MitraAkun m) {
    final firstName = m.nama.trim().isNotEmpty ? m.nama.trim().split(' ').first : m.displayName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hai, $firstName! \u{1F44B}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              GestureDetector(
                onTap: () => _infoKontak(context),
                child: const Icon(Icons.info_outline, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Kontak Tersedia', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 2),
          Text('${m.kuota}', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w800, fontSize: 40, height: 1.1)),
          const SizedBox(height: 4),
          const Text('Semakin banyak kontak, semakin banyak peluang!', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : _lihatPaket,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lihat Paket Kontak', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  void _infoKontak(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tentang Kontak'),
        content: const Text('1 Kontak terpakai setiap kamu menghubungi pelanggan dari daftar Lead. Menghubungi lead yang sama lagi dalam 24 jam gratis. Isi ulang Kontak lewat admin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
        ],
      ),
    );
  }

  Future<void> _lihatPaket() async {
    await openWa(_adminWa, text: 'Halo admin Sekita, saya mau lihat paket dan isi ulang saldo Kontak untuk akun mitra ${Api.currentMitra?.displayName ?? ''}.');
  }

  /// Kartu ringkas status verifikasi (tier) + tombol ke halaman tingkatkan.
  Widget _verifCard(BuildContext context, MitraAkun m) {
    final tier = verifTierFor(m.verified);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: tier.color, size: 20),
              const SizedBox(width: 8),
              const Text('Status Verifikasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kInk)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: tier.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(tier.label, style: TextStyle(color: tier.color, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(tier.desc, style: const TextStyle(color: _muted, fontSize: 12.5)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifikasiMitraScreen()));
                _refresh();
              },
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: Text(m.verified >= 3 ? 'Lihat Verifikasi' : 'Tingkatkan Verifikasi'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = Api.currentMitra;
    if (m == null) {
      return const Scaffold(backgroundColor: kBg, body: Center(child: Text('Belum login sebagai mitra.')));
    }
    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kBrand, kBrandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Icon(Icons.storefront, color: kBrand)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(m.kategori.isNotEmpty ? m.kategori : 'Mitra', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _kontakCard(context, m),
                  const SizedBox(height: 14),
                  if (m.bisaKlaimPerdana) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard, color: Color(0xFFEA580C)),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Klaim 20 Kontak gratis untuk mitra perdana!', style: TextStyle(fontWeight: FontWeight.w600, color: kInk)),
                          ),
                          FilledButton(
                            onPressed: _busy ? null : _klaimPerdana,
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                            child: const Text('Klaim'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _verifCard(context, m),
                  const SizedBox(height: 14),
                  _menuCard([
                    _MitraRow(Icons.history, kBrand, 'Riwayat Kontak', 'Lead yang sudah kamu hubungi', () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatKontakScreen()));
                    }),
                    _MitraRow(Icons.swap_horiz, kBrand, 'Beralih ke Mode Pembeli', 'Cari & posting kebutuhan sebagai pelanggan', _busy ? null : _keMitraPembeli),
                  ]),
                  const SizedBox(height: 14),
                  _menuCard([
                    _MitraRow(Icons.help_outline, kBrand, 'Hubungi Admin', 'Bantuan, isi ulang Kontak, atau verifikasi', () => openWa(_adminWa, text: 'Halo admin Sekita, saya mitra ${m.displayName}.')),
                    _MitraRow(Icons.logout, _muted, 'Keluar', 'Keluar dari akun mitra', _logout),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Sekita Mitra \u00b7 Terhubung dengan pelanggan di sekitarmu', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== JADI MITRA (daftar/upgrade) ===================

class JadiMitraScreen extends StatefulWidget {
  const JadiMitraScreen({super.key});
  @override
  State<JadiMitraScreen> createState() => _JadiMitraScreenState();
}

class _JadiMitraScreenState extends State<JadiMitraScreen> {
  late final bool _upgrade = Api.currentUser != null;
  final _namaUsaha = TextEditingController();
  final _nama = TextEditingController();
  final _wa = TextEditingController();
  final _email = TextEditingController();
  final _lokasi = TextEditingController();
  final _deskripsi = TextEditingController();
  final _pass = TextEditingController();
  String _kategori = Api.kategoriDasar.first;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final u = Api.currentUser;
    if (_upgrade && u != null) {
      _nama.text = u.nama;
      _wa.text = u.wa;
      _email.text = u.email;
    }
  }

  @override
  void dispose() {
    _namaUsaha.dispose();
    _nama.dispose();
    _wa.dispose();
    _email.dispose();
    _lokasi.dispose();
    _deskripsi.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final namaUsaha = _namaUsaha.text.trim();
    final wa = _wa.text.trim();
    if (namaUsaha.isEmpty) {
      setState(() => _error = 'Nama usaha wajib diisi.');
      return;
    }
    if (wa.isEmpty) {
      setState(() => _error = 'Nomor WhatsApp wajib diisi.');
      return;
    }
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Email wajib diisi dengan benar.');
      return;
    }
    if (!_upgrade && _pass.text.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }

    setState(() {
      _busy = true;
      _error = '';
    });
    final d = await Api.daftarMitra(
      namaUsaha: namaUsaha,
      nama: _nama.text.trim(),
      kategori: _kategori,
      lokasi: _lokasi.text.trim(),
      deskripsi: _deskripsi.text.trim(),
      wa: wa,
      email: _email.text.trim(),
      password: _pass.text,
      upgrade: _upgrade,
    );
    if (!d.ok) {
      setState(() {
        _busy = false;
        _error = d.error;
      });
      return;
    }
    if (_upgrade) {
      await Api.switchRole('mitra');
    } else {
      await Api.login(wa, _pass.text, tipe: 'mitra');
    }
    if (d.eligible && Api.isMitra) {
      await Api.claimPerdana();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selamat datang di Sekita Mitra!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Jadi Mitra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kBrand.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: const Text('Daftarkan usahamu untuk menerima lead dari pelanggan di sekitarmu. Mitra perdana dapat 20 Kontak gratis.', style: TextStyle(color: kInk, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          _field(_namaUsaha, 'Nama usaha', Icons.storefront_outlined),
          const SizedBox(height: 12),
          _field(_nama, 'Nama kamu', Icons.person_outline),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _kategori,
            decoration: InputDecoration(
              labelText: 'Kategori',
              prefixIcon: const Icon(Icons.category_outlined, size: 20),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              floatingLabelStyle: const TextStyle(color: kBrand),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrand, width: 1.5)),
            ),
            items: Api.kategoriDasar.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _kategori = v ?? _kategori),
          ),
          const SizedBox(height: 12),
          _field(_lokasi, 'Lokasi (kota/kecamatan)', Icons.place_outlined),
          const SizedBox(height: 12),
          _field(_wa, 'Nomor WhatsApp', Icons.call_outlined, keyboard: TextInputType.phone, enabled: !_upgrade),
          if (_upgrade) ...[
            const SizedBox(height: 4),
            const Text('Nomor mengikuti akun yang sedang login.', style: TextStyle(color: _muted, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          _field(_email, 'Email', Icons.mail_outline, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_deskripsi, 'Deskripsi layanan', Icons.notes_outlined, maxLines: 3),
          if (!_upgrade) ...[
            const SizedBox(height: 12),
            _field(_pass, 'Password', Icons.lock_outline, obscure: true),
          ],
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFDC2626).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: kBrand, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Daftar Jadi Mitra', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData ic, {bool obscure = false, TextInputType? keyboard, int maxLines = 1, bool enabled = true}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      maxLines: obscure ? 1 : maxLines,
      enabled: enabled,
      style: const TextStyle(fontSize: 15, color: kInk),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ic, size: 20),
        filled: true,
        fillColor: enabled ? const Color(0xFFF7F8FA) : const Color(0xFFEEF1F5),
        floatingLabelStyle: const TextStyle(color: kBrand),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrand, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
      ),
    );
  }
}

// =================== MASUK MITRA ===================

class MitraLoginScreen extends StatefulWidget {
  const MitraLoginScreen({super.key});
  @override
  State<MitraLoginScreen> createState() => _MitraLoginScreenState();
}

class _MitraLoginScreenState extends State<MitraLoginScreen> {
  final _idf = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _idf.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _lupaPassword() => showLupaPasswordDialog(context, tipe: 'mitra');

  Future<void> _submit() async {
    if (_idf.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Isi nomor WhatsApp dan password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final r = await Api.login(_idf.text.trim(), _pass.text, tipe: 'mitra');
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = r.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kInk,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kBrand, kBrandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: kBrand.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 38),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Masuk Mitra', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: kInk))),
          const SizedBox(height: 4),
          const Center(
            child: Text('Masuk untuk kelola lead & usahamu', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 13.5)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
            child: Column(
              children: [
                _field(_idf, 'Nomor WhatsApp', Icons.call_outlined, keyboard: TextInputType.phone),
                const SizedBox(height: 14),
                _field(_pass, 'Password', Icons.lock_outline, obscure: true),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _lupaPassword,
                    style: TextButton.styleFrom(foregroundColor: kBrand, padding: const EdgeInsets.symmetric(horizontal: 4)),
                    child: const Text('Lupa kata sandi?'),
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFDC2626).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(backgroundColor: kBrand, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Masuk', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const JadiMitraScreen())),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(color: _muted, fontSize: 13.5),
                  children: const [
                    TextSpan(text: 'Belum punya akun mitra? '),
                    TextSpan(text: 'Daftar', style: TextStyle(color: kBrand, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData ic, {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 15, color: kInk),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ic, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        floatingLabelStyle: const TextStyle(color: kBrand),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBrand, width: 1.5)),
      ),
    );
  }
}
