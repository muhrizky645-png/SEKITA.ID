import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'verif_mitra.dart';
import 'lupa_password.dart';
import 'riwayat_kontak.dart';

const String _adminWa = '089607620368';
const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);
const Color _green = Color(0xFF16A34A);

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

  Future<void> _hubungi(Kebutuhan k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hubungi pelanggan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biaya 1 Kontak. Gratis bila kamu menghubungi lead ini lagi dalam 24 jam.'),
            const SizedBox(height: 8),
            Text('Saldo kamu: ${Api.currentMitra?.kuota ?? 0} Kontak', style: const TextStyle(color: _muted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjut')),
        ],
      ),
    );
    if (ok != true) return;

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
    if (r.deducted) _snack('1 Kontak terpakai. Sisa saldo: ${r.kuota} Kontak.');
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
                    itemBuilder: (_, i) => _LeadCard(k: items[i], onHubungi: () => _hubungi(items[i])),
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
  const _LeadCard({required this.k, required this.onHubungi});

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
                child: Text(k.ic.isNotEmpty ? k.ic : '\u{1F4DD}', style: const TextStyle(fontSize: 20)),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text('${k.contactedCount}/7 penawar', style: const TextStyle(color: _muted, fontSize: 12.5)),
              const Spacer(),
              FilledButton.icon(
                onPressed: onHubungi,
                style: FilledButton.styleFrom(backgroundColor: _green),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Hubungi'),
              ),
            ],
          ),
        ],
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
