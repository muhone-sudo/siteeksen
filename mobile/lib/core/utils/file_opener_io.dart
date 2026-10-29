import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// [subdir] verilirse önce o dizin temizlenir: kişisel veri içerebilecek
/// dosyalar cihazda birikmez.
Future<String?> openBytes(List<int> bytes, String name, {String? type, String? subdir}) async {
  var dir = await getTemporaryDirectory();
  if (subdir != null) {
    final sub = Directory('${dir.path}/$subdir');
    if (await sub.exists()) await sub.delete(recursive: true);
    dir = await sub.create(recursive: true);
  }
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  final r = await OpenFilex.open(file.path, type: type);
  switch (r.type) {
    case ResultType.done:
      return null;
    case ResultType.noAppToOpen:
      return 'Bu dosya türünü açabilecek bir uygulama cihazda yok.';
    case ResultType.permissionDenied:
      return 'Dosyayı açmak için izin verilmedi.';
    default:
      return 'Dosya indirildi ama açılamadı: ${r.message}';
  }
}
