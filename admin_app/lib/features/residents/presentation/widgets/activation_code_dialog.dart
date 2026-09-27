// Etkinleştirme / şifre sıfırlama kodu penceresi.
//
// Kod YALNIZCA BİR KEZ gösterilir: sunucu kodun kendisini değil özetini saklar;
// bu pencere kapandıktan sonra kod bir daha görüntülenemez (gerekirse yeni kod
// üretilir, eskisi geçersizleşir). SMS sağlayıcısı bağlı olmadığı için kodu
// sakine yönetici iletir.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/formatters.dart';

Future<void> showActivationCodeDialog(
  BuildContext context, {
  required String who,
  required Map<String, dynamic> activation,
}) {
  final code = '${activation['activation_code'] ?? ''}';
  final reset = activation['purpose'] == 'RESET';
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(reset ? 'Şifre sıfırlama kodu' : 'Hesap etkinleştirme kodu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$who için kod:'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: const TextStyle(fontSize: 26, letterSpacing: 4, fontFamily: 'monospace', fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Kopyala',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Kod kopyalandı')));
                  }
                },
              ),
            ],
          ),
          Text('Son geçerlilik: ${formatDateTime(activation['expires_at'])}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('Bu kod bir daha gösterilmez.\n${activation['note'] ?? ''}'),
          ),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kodu ilettim, kapat')),
      ],
    ),
  );
}
