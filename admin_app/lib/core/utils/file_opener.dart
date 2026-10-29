// İndirilen dosyayı açar: mobilde geçici dizine yazıp cihazdaki görüntüleyiciyle,
// web derlemesinde tarayıcının indirmesiyle. Başarıda null, aksi hâlde kullanıcıya
// gösterilecek mesaj döner.
export 'file_opener_io.dart' if (dart.library.js_interop) 'file_opener_web.dart';
