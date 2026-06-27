import 'package:flutter/material.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';

const String _adminWa = '089607620368';
const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE8ECF3);
const Color _green = Color(0xFF16A34A);

Widget _menuCard(List<Widget> rows) {
  final children = <Widget>[];
  for (var i = 0; i < rows.length; i++) {
    children.add(rows[i]);
    if (i != rows.length - 1) {
      children.add(const Divider(height: 1, thickness: 1, color: _line, indent: 60));
    }
  }
  return Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
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
            const Icon(Icons.chevron_right, color: Color(0xFFB0B8C4)),
          ],
        ),
      ),
    );
  }
}

// \u2500\u2500\u2500\u2500\u2500 LEAD \u2500\u2500\u2500\u2500\u2500

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
    return Api.fetchLeads(kategori: Api.currentMitra?.kategori, onlyMyCategory: _onlyM