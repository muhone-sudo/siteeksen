import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web derlemesinde ödeme sayfası aynı sekmede açılır; iyzico dönüşü sunucu üzerinden uygulamanın bakiye sayfasına
/// sonuçla yönlenir (`/bakiye?topup_id=…&status=…`). Bu yüzden burada sonuç beklenmez.
Future<Uri?> openPayment(BuildContext context, String url, String resultUrl) async {
  await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
  return null;
}
