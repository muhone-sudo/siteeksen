// Memnuniyet ölçümü (NPS) — FAZ H.6 S7. Yönetimin açtığı ölçümlere 0-10 puan ve isteğe bağlı yorumla
// yanıt verilir; kimin kaç verdiği kimseye gösterilmez, aynı kişi iki kez yanıtlayamaz.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/future_list.dart';

class NpsScreen extends StatefulWidget {
  const NpsScreen({super.key});

  @override
  State<NpsScreen> createState() => _NpsScreenState();
}

class _NpsScreenState extends State<NpsScreen> {
  Future<void> _answer(Map<String, dynamic> s, Future<void> Function() reload) async {
    final res = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AnswerSheet(title: '${s['title']}'),
    );
    if (res == null || !mounted) return;
    if (await runSnack(context, () => apiClient.respondNps('${s['id']}', res.$1, res.$2), 'Yanıtınız kaydedildi, teşekkürler')) {
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memnuniyet Anketi')),
      body: FutureList(
        load: apiClient.getNps,
        empty: 'Açık memnuniyet ölçümü yok',
        emptyIcon: Icons.sentiment_satisfied_alt,
        itemBuilder: (context, s, reload) {
          final open = s['status'] == 'ACTIVE' || s['status'] == 'OPEN';
          final answered = s['has_answered'] == true;
          return ListTile(
            leading: Icon(answered ? Icons.check_circle : Icons.sentiment_satisfied_alt, color: answered ? Colors.green : null),
            title: Text('${s['title']}'),
            subtitle: Text([
              if ((s['description'] ?? '').toString().isNotEmpty) '${s['description']}',
              if (s['ends_at'] != null) 'Son gün ${formatDate(s['ends_at'])}',
              answered ? 'Yanıtladınız' : (open ? 'Yanıt bekleniyor' : 'Kapandı'),
            ].join('\n')),
            isThreeLine: true,
            trailing: open && !answered ? FilledButton(onPressed: () => _answer(s, reload), child: const Text('Yanıtla')) : null,
          );
        },
      ),
    );
  }
}

class _AnswerSheet extends StatefulWidget {
  final String title;
  const _AnswerSheet({required this.title});

  @override
  State<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<_AnswerSheet> {
  int? _score;
  final _comment = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Site yönetimini bir tanıdığınıza tavsiye etme olasılığınız nedir? (0 = hiç, 10 = kesinlikle)'),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i <= 10; i++)
            ChoiceChip(label: Text('$i'), selected: _score == i, onSelected: (_) => setState(() => _score = i)),
        ]),
        TextField(controller: _comment, maxLines: 3, decoration: const InputDecoration(labelText: 'Yorum (isteğe bağlı)')),
        const SizedBox(height: 8),
        const Text('Puanınız kimseye kimliğinizle gösterilmez. Aynı ölçüme yalnız bir kez yanıt verebilirsiniz.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _score == null ? null : () => Navigator.pop(context, (_score!, _comment.text.trim())),
          child: const Text('Gönder'),
        ),
      ]),
    );
  }
}
