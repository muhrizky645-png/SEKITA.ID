import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// URL utama aplikasi (situs Sekita). Parameter ?src=app dipakai untuk
/// menandai trafik yang datang dari aplikasi Android di Google Analytics.
const String kHomeUrl = 'https://sekita.id/?src=app';

/// Warna brand Sekita.
const Color kBrand = Color(0xFF2563EB);

/// Host yang tetap dibuka DI DALAM aplikasi (domain Sekita sendiri).
bool _isInternalHost(String host) {
  host = host.toLowerCase();
  return host == 'sekita.id' || host.endsWith('.sekita.id');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SekitaApp());
}

class SekitaApp extends StatelessWidget {
  const SekitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sekita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: kBrand,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const WebShell(),
    );
  }
}

class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() {
            _loading = true;
            _error = false;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (err) {
            if (err.isForMainFrame ?? true) {
              setState(() {
                _loading = false;
                _error = true;
              });
            }
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(kHomeUrl));
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    // Skema non-web (WhatsApp, telepon, email, SMS, peta) -> buka aplikasi luar.
    const externalSchemes = {
      'tel',
      'mailto',
      'sms',
      'whatsapp',
      'intent',
      'geo',
      'market',
    };
    final isWhatsApp = host == 'wa.me' ||
        host == 'api.whatsapp.com' ||
        host.endsWith('whatsapp.com');

    if (externalSchemes.contains(scheme) || isWhatsApp) {
      _openExternal(uri);
      return NavigationDecision.prevent;
    }

    // Tautan http(s) ke domain LAIN (mis. Instagram, Google Maps) -> browser.
    if ((scheme == 'http' || scheme == 'https') && !_isInternalHost(host)) {
      _openExternal(uri);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // diabaikan bila tidak ada aplikasi yang bisa membuka tautan.
    }
  }

  Future<void> _reload() async {
    setState(() {
      _error = false;
      _loading = true;
    });
    await _controller.loadRequest(Uri.parse(kHomeUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (!_error) WebViewWidget(controller: _controller),
              if (_loading && !_error && _progress > 0 && _progress < 100)
                LinearProgressIndicator(
                  value: _progress / 100,
                  color: kBrand,
                  backgroundColor: Colors.transparent,
                ),
              if (_loading && !_error && _progress == 0)
                const Center(child: CircularProgressIndicator()),
              if (_error) _ErrorView(onRetry: _reload),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat halaman.\nPeriksa koneksi internetmu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
