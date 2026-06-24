import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'core.dart';
import 'models.dart';
import 'widgets.dart';

// Logo WhatsApp resmi (putih) tertanam sebagai PNG base64 — tanpa paket eksternal.
final _waLogoBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAFQAAABgCAYAAACDgFV6AAANx0lEQVR42u2deZBdRRXGf+9NVhISyAKEhAQIMYFEIBVQCUEFgQCyCIgoUKCyI2JpoWi5gIqAIFCKRi0kpWwiBSi7QMQiIGAMhARShBAIYctCQvbJTGbmfv5x+vGaybt9733LvBdqvqqpSWXu7T79dffp033O6Qvd6EY3utGNbjQIcvUWwIekgky9gN5AH6An0OQe6QDagBagFdgMKJdrnGbURRJHHBhRg4BRwBj3syswzP1/f4zUAqHtGJEbgNXAUuANYCHwKrAEeB/okEQ+n+/ytnUZoVEU4UZSX2APYDIwBdgH2AUYAJTLQASsA94C5gFPAU9jJG8C6KpRXPNa3GhswkbeVOBoYBIwtIb1C1gJPAc8CDwCvA501JrYmpTuTeleGHmnAp8HRlL+KCxbHGzkPgjcBswGWmulEqpOqCOzJ/AJ4FyMyEG14ysTVgMPAX8EngXaGmlB+xAkEUVRTtI4Sb+VtFKNi1WSpknaU1LOm1EVo+Lu8YTZFjgN+A626FSCCDOJWtzvDvf/TZga6eN+VzpnXwOuA24B1kPli1dFb3tkjgcuA47DpntW8t7HFo0FwCuYKbQMWIOt0u3u2R6YlbAdsCNmbo0FxgGjgcFkJ7kNuA+4FJhfDVLLJlNSD0knSlqQccq1S3pd0i2SviZpb0kDJeWzTD8nQ17SAEkTJJ0h6c+SFrk6smCBa0uPaqqALA3pJ+n7ktZkEHqDpEcknSVpt4LwURRVU64mSaNcRz0kaV0G+VZLukTSNl1CqhMYSYMk3SCpNaWg6yTdKWmq6whqKbAn5zaSDpX0V0lrU8raKunXkravZmdvgSiKCkLuIOlmSR0phNss6VFJR0rqU2siA8T2lnS4pIedTEnokKmOITWR2RNsqKTbU/b0G5K+KWm7riYyIP9ASRfI9HcSIpmOH1x1+T1hpruKknr3AUkTVWUbr0rtyEnaR9J9KWZZJOlG2aJXVSH6SLomhQAbJF0l07G10z+Vt6ewDlzpZA6hXdIvZWqjKpXnJF0oaVNCxe9JOldSr0YalQlt6yXpPCXv6jY5DsqfcV5PHiZpeUKF70o6SRntyHpDRTv2ZElLE9q4QtIRKlefuhdHSZqVUNFSScdX1Hv1JzUnM+qXJbT1eUmjM5PqTYffJVTwvqRTtlYyS5B6msy4D+EmSX1Tt9eb6sdLWh8ouEXSt7e2aZ7Q7ibXppZAu5sd8elGqXtwR0lPJ/TUtEw9tRVARYvmhoS2z5W0a2LbvdF5scL25pOShn+UyOzEwU6SHk8g9apSszPXuTBgd+xUe2xMnSuBLwP/gvBRl4r+pInAkcBO2NlmKzDT1VNzP09WQh2mAHdiHthSWAocAzynUu4Ub3T+KKFnrkyjNz2ddKZKmyQrJB2cWhd1MamyReoHCm9m/qC44z5XyEhJ8xN0x6iUZCKz71YFyrtFUs9GI9Rrw1BJMwPyL5M0aQv5PQLOC+jOdknnJ40o71RqkpIPIZbK9tX15i+OUGT2aXOgDdeqs9noXtxW0ozAi7NkR3dpBOkrO/9Mg58kdVKdSe0n6d6A/K/KDsu3ePEgxR/CRrKjuGDDvV49TGEb1sccmZlWb/5C7TlG0sYAN+cUnvUXl6lYOEwpLALuh9QOrOOwuKQ0GA8cUmhAI8Fr6xPAM3GPYat9Hyh6CAcCBwfKfgQLxEqD7YFPZpC7J/ClgkANinWYCRXX4/tjgW4fEPoxYM+YhzcBDwQK64wdgBEZBf40Zqs2HLxROgNzb5fCjsABUCR0EjaySmEhMKdT4SFsD/TLKPcg4CSgkQ9ZlmBRfXE4CGjKYzpgv8CD/wXey1BxD4rxnFlQ2Ek1Kjqw3WGcG2IfYIc8pj/3inlImDLOMmyasfCZrGjPWE+XwZuZs4kfXCOAMXlsrxqn89YCL3UqNAkrsdCaLBBwKxZ+08h4E7N4SmEAMD6PxWzG6c9lwNsZK12BRQ5nwQxgOtQprig91gMvx/ytCZiQxwKu+sY89BYWsJUFLdhJUlrMBy4hm56uJxYE/rZHHhhO/CLyNnbUlgre6HoUm/pJeBP4BtmsiLrAk20JxfDKzhiRx2yoOCynvIXiRdx5aQIewHYhDU1mCU7iBtngPBZrGYfVZTa2FdOJ6xOe2xsYUm+GMmIdptZKYds88foTzATKhE7733sTHp8MnAGNt48PoAUL0i2F3nnMEI9DG+WjFbge05NxyAPfwvbCWwupHcTr0KY88ZY/lLfj8Ufp88C1hDtmF+CnbD1TP0982HmUJ14fQFgdBOGROh24K+HxI4DvAZUHZNUevYif1W15bDcUh4FQ/lR0720AfobbccUgB1yI5TU1NTip/bHE3lLYmCdsLw6tpGbPtboA+CHhLWlfjPgzaWxSBxN/drsmD7xLvB4dTvY0mQ/Bm/oPAFcRPjgZCFyNLVR9spDq+cWOkDRZUv8a+apCnCxD0nEBr94cueDZSqFiEsE0JUdBb5KFwwxLQ4qKMQCXypIO1smyTU5VlUK6Pf/S1QG5b0MWuh0Xxrdc0vhq9bITaIiku1I47yJZyM+hCuQO6cPu3tWdytgsi9E6W85jW8l6IItIvC8g848LWR1zYh5ok3RClQktBFQ8koJUyQIlrpO0hzr5v73y9pO0MFBGm6TZsoSFncoh1r0zXNIrMXU0Szq+kA13R0CYqyrp2QCpo5UckOVjoSyIbWevDGRRcE+mLKNdFjR7oTKOWPfs5xTvTl4iac/Cg5cEhHhCpuyrQmgnUveQ5TGlRYekFxwhuzgy787wfgGRbOpun6ZdnryXBcqcIal/4cFDAsyvkrR/NQntJORIR0rSQuWjXRaxsVDpEtBKYbksvTutrAMUjnP6haQPtlDzgcUx5Q0CDi8UXC3kcrlCeW9iBv3vSe+LasJSyMdQfor3ZjKc9QL7Yo64UmjBeUQLwqwA/hMo7GhqcCtDPp8v2Kkrge/StSf3y3DHkyGoePXRFwhH1swBPgjFEfBP4kfIROCzXgVVhSO1GfgN8BXs+opab5XmEd52+9gdODbw98dxDsa8tz18mngHVG/gdGCbWrXOkRphJ/0nAtcAq2pUXRvwGOGTNn/wnIRdcFAKG7ALDIrPewvEzwNKd72ko1Sb7dwWDZGZcwe5BSspfTAr7leKFd7JsZuklwNlzVApK8i9vK/CGWUPqpqJpMmNKWxXj5Ltrt6vApmPSxqbNDBUDAu/PFBWu6SvlyzLGxU3BgpojS2g9sT2kfQpSb9yI6YtI5HrZOcII1KSiavv3UCZ/1NcbKtXyGRZImwcXpIZ5F1CaAkZ87It4CmSbpXZo6FErdWyCOQjlTKjWMV09lDkcskQ+VJpNT2AG4DzAnWeDfypXq5frwE9sFCivbDA3V2xI8AIM4kWA7Mwt3YzJHtwVTSTLgauIP50/ingBOC92DK9hIPDFJ/OvV7SZ+oxQkOIoogoinLeT+Z8fW+WTlU4A3ujpC8mqj6vwHMChc1TiuSFrQ1e28fL0odC+IvcHSppCm2S5Q/FYbo+IgmzBXgzc6TCmTCSnR+MV5obK1TMc4xL/orUxat8reGNzGGS/p5A5kZJp6duv5LP/FbIbgGrNw/VJnOXFGRKdp9TOle3V3go13Omqnw22gBk7ql0Z7IPK0s+lYrG80OBQq/+KEx3FXdBhyje/eNjjpzezEroGElvxRS6WeYhrTcflRKJzMV8kZIvbpFs43Bg5oHkXjhJ8Vu6xeqc0+jBWymbZFm8U2SJsQ0RtOCNyn1leahp7u1bLLPJU5PZo1CZwxTidwZzgXc6C4kdUg/Ajrf2w0IUJwK7YbGUNwI3SXoLuj6w1mvbMOCrwPlYgFoSXnPPPpZZbtcD20l6NtBbF0sfXAvc3+mU02QHDrNkJ0Gl/EKRbDNwkWwP3iXJXd6I3Em2535e6f1Pc90My7xe5Lxe3A+LjS+VEdIMXIAlMEzBcjnHYiGIaX06EXaAfScWiLsA59Op1qj1Gt8LS7c8FjgZ2+enDc18DLv2OGs6UVEI93NBoMfaZTZomqsi02C5zO47V9LH3Ygva+R6I7GfmzVnyc5O0yw4Pppl91SVFQhRQKERTcDNwCmVjJAyULjAfwHwAubnWcSH719uwyKGhc2Gnlik3kBML47GYvUnYncxDyW7J3QxcDlwO9BSyYwpELoz5ssZ18WEliK4BXOercUWtY2Y8zByZPZzZG7nfvel/Mu5WzD1c4WkF3O5XMUfaims6HthCWDVJIYyGppzBPWltom0Eeb2vR74B7Axl8tVRZcXCJ1MBeHfDmuxq9NnYwm3QzAzZRxd/7mKOESYepmOTe+lUF1TrgfmGj6gjHebsayyOZgLejaW47nGCZ4D7sBcwqdieq5XPVjEVMZcjMS7sQzBmnyHKSdpAvAwybcwtGKG/TxsBM7Censl7uL+zgJ6K+UQLFDiBCxRf2dqP2ojJ+9M4B4sb2pVKTmrTehZwDS2DHNux9Lw5mORHM+6fy/DRZikFcz7llJPbAd1IHZxyyQsGzrrDRBx2IDNmueAf2PhRW/g0nq6YpeWk/Q37BKVCOvBV7DR9ww2Td6mih958kZtE2bijAEmuJ/R2OgdhJHc2z1XGM0R1tGbKX716x3M1JqPOeMWYbOmLnfq5STd4wR4CkvUWuKE7bJvvanoaeyFfaRloPvZFlssC4tnG9a56ymaVetppG/TqYxvcHSjG93oRje60Y2tAP8HGJvIU9DidWMAAAAASUVORK5CYII=');

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
            icon: Image.memory(_waLogoBytes, width: 22, height: 22),
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
