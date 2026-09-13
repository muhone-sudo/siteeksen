// Veri durumu bileşenleri — yükleniyor / hata / boş / uygulanmadı.
//
// NEDEN VAR:
// 2026-09-09 denetiminde mobil ekranların büyük kısmının ya uydurma veri gösterdiği
// ya da hata durumunda sessizce boş listeye düştüğü tespit edildi. İkisi de kullanıcıya
// yalan söyler: "veri yok" ile "veri alınamadı" farklı şeylerdir ve özellikle para
// ekranlarında bu fark kritiktir.
//
// Bu dosya, panelin `admin/src/components/ui/data-state.tsx` bileşenlerinin mobil
// karşılığıdır; her ekran aynı dili konuşsun diye tek yerde toplanmıştır.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Yükleniyor göstergesi.
class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Hata durumu — nedenini gösterir ve yeniden denemeyi teklif eder.
/// Sessizce boş liste göstermek yerine bu kullanılır.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Veri alınamadı',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yeniden dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gerçekten veri olmadığı durum. Hata ile KARIŞTIRILMAMALIDIR.
class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Henüz uygulanmamış özellik bildirimi.
///
/// Sunucu 501 döndüğünde veya ekran gerçek bir veri kaynağına bağlı olmadığında
/// kullanılır. Uydurma veri göstermek yerine durumu açıkça söyler.
class NotImplementedNotice extends StatelessWidget {
  final String title;
  final String? detail;

  const NotImplementedNotice({
    super.key,
    this.title = 'Bu özellik henüz hazır değil',
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.construction_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(detail!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sunucu yanıtının "henüz uygulanmadı" (501) olup olmadığını söyler.
bool isNotImplemented(Object error) {
  if (error is DioException) {
    return error.response?.statusCode == 501;
  }
  return false;
}

/// Bir hatayı kullanıcıya gösterilebilir Türkçe mesaja çevirir.
///
/// Ham `DioException.toString()` çıktısı kullanıcıya gösterilmez: hem anlaşılmaz
/// hem de sunucu iç ayrıntılarını sızdırabilir.
String toUserMessage(Object error) {
  if (error is DioException) {
    final code = error.response?.statusCode;
    if (code == 501) {
      return 'Bu özellik henüz sunucu tarafında hazır değil.';
    }
    if (code == 401) {
      return 'Oturumunuzun süresi dolmuş. Lütfen yeniden giriş yapın.';
    }
    if (code == 403) {
      return 'Bu işlem için yetkiniz yok.';
    }
    if (code != null && code >= 500) {
      return 'Sunucu şu an yanıt veremiyor. Lütfen daha sonra deneyin.';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Bağlantı zaman aşımına uğradı.';
      case DioExceptionType.connectionError:
        return 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
      default:
        final serverMsg = error.response?.data;
        if (serverMsg is Map && serverMsg['error'] is String) {
          return serverMsg['error'] as String;
        }
        return 'Beklenmeyen bir hata oluştu.';
    }
  }
  return 'Beklenmeyen bir hata oluştu.';
}
