import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String?> openBytes(List<int> bytes, String name, {String? type, String? subdir}) async {
  final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: type ?? 'application/octet-stream'));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body?.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
  return null;
}
