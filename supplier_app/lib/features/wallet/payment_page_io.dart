import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Ödeme sayfası uygulamanın içinde açılır (tarayıcıya çıkılmaz; oturum, sekme kapanması ve dönüş yönlendirmesi
/// sorunu olmaz). iyzico işlemi bitirip sunucunun dönüş adresine, sunucu da sonuç adresine yönlendirdiğinde sayfa
/// kapanır ve sonuç adresi döner. Sonuç istemciye güvenilerek işlenmez: bakiye sunucudan yeniden okunur.
Future<Uri?> openPayment(BuildContext context, String url, String resultUrl) => Navigator.of(context).push<Uri>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _PaymentPage(url: url, resultUrl: resultUrl),
  ),
);

class _PaymentPage extends StatefulWidget {
  final String url, resultUrl;
  const _PaymentPage({required this.url, required this.resultUrl});

  @override
  State<_PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<_PaymentPage> {
  late final WebViewController _web;
  bool _loading = true, _done = false;

  bool _isResult(String url) => widget.resultUrl.isNotEmpty && url.startsWith(widget.resultUrl);

  void _finish(String url) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(Uri.parse(url));
  }

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) {
            if (_isResult(r.url)) {
              _finish(r.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (c) {
            if (c.url != null && _isResult(c.url!)) _finish(c.url!);
          },
          onPageStarted: (u) {
            if (_isResult(u)) _finish(u);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _close() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ödemeden çıkılsın mı?'),
        content: const Text(
          'Ödemeyi tamamladıysanız sonuç birkaç dakika içinde bakiyenize kendiliğinden yansır. '
          'Tamamlamadıysanız kartınızdan tutar çekilmez.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ödemeye dön')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Çık')),
        ],
      ),
    );
    if (leave == true && mounted && !_done) {
      _done = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kartla ödeme'),
          leading: IconButton(tooltip: 'Kapat', icon: const Icon(Icons.close), onPressed: _close),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _web),
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
