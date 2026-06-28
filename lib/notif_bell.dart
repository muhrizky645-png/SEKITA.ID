import 'package:flutter/material.dart';
import 'core.dart';
import 'mitra_api.dart';

/// Tab mitra aktif (0=Lead, 1=Riwayat, 2=Toko, 3=Akun). Lonceng memakai ini
/// untuk melompat ke tab Lead saat sebuah notifikasi dibuka.
final ValueNotifier<int> mitraTab = ValueNotifier<int>(0);

/// Ikon lonceng + badge jumlah lead belum dibaca. Tap membuka daftar lead.
class MitraBell extends StatefulWidget {
  const MitraBell({super.key});
  @override
  State<MitraBell> createState() => _MitraBellState();
}

class _MitraBellState extends State<MitraBell> {
  List<LeadNotif> _items = [];
  Set<String> _read = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    final items = await MitraApi.leadNotifs();
    final read = await MitraApi.notifTerbaca();
    if (!mounted) return;
    setState(() {
      _items = items;
      _read = read;
      _loading = false;
    });
  }

  int get _unread => _items.where((e) => !_read.contains(e.nid)).length;

  Future<void> _markAll() async {
    final ids = _items.map((e) => e.nid).toList();
    setState(() => _read = {..._read, ...ids});
    await MitraApi.tandaiTerbaca(ids);
  }

  Future<void> _openSheet() async {
    await _load();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _BellSheet(
        items: _items,
        read: _read,
        onMarkAll: () async {
          await _markAll();
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onTapItem: (n) async {
          setState(() => _read = {..._read, n.nid});
          await MitraApi.tandaiTerbaca([n.nid]);
          if (ctx.mounted) Navigator.pop(ctx);
          mitraTab.value = 0;
        },
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final n = _unread;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifikasi',
          onPressed: _openSheet,
        ),
        if (n > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                n > 9 ? '9+' : '$n',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ),
          ),
      ],
    );
  }
}

class _BellSheet extends StatelessWidget {
  final List<LeadNotif> items;
  final Set<String> read;
  final Future<void> Function() onMarkAll;
  final Future<void> Function(LeadNotif) onTapItem;
  const _BellSheet({
    required this.items,
    required this.read,
    required this.onMarkAll,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: h * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
            child: Row(
              children: [
                const Text('Lead Kebutuhan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (items.isNotEmpty)
                  TextButton(onPressed: onMarkAll, child: const Text('Tandai semua dibaca')),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: Text('Belum ada lead baru untuk kategori kamu.', style: TextStyle(color: Color(0xFF64748B))),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEFF1F5)),
                itemBuilder: (_, i) {
                  final n = items[i];
                  final unread = !read.contains(n.nid);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEFF4FF),
                      child: Text(n.ic, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(
                      n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600),
                    ),
                    subtitle: Text(
                      [if (n.loc.isNotEmpty) n.loc, if (n.budget.isNotEmpty) n.budget].join(' \u00b7 '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: unread
                        ? Container(width: 9, height: 9, decoration: const BoxDecoration(color: kBrand, shape: BoxShape.circle))
                        : null,
                    onTap: () => onTapItem(n),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
