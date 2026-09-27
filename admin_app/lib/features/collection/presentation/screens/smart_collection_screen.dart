// Tahsilat riski.
//
// DÜZELTME (2026-09-27): ekran var olmayan `/smart-collection/*` uçlarına
// gidiyor ve "YZ tahmini", "ödeme olasılığı" gibi sunucunun ÜRETMEDİĞİ
// değerleri bekliyordu; "işlem başlat" düğmesi de var olmayan bir uca
// bağlıydı. Sunucu (`GET /collection/risk`) açıklanabilir bir skor döner:
// her bölüm için skor, kategori, skorun GEREKÇELERİ (`factors`) ve bir
// öneri. Yapay zekâ kullanılmaz; öneri yalnızca öneridir, hukuki adımı
// yönetim kararı başlatır. Skorların kaydı: `POST /collection/risk/snapshot`.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

(String, Color) riskCategory(Object? c) {
  switch ('${c ?? ''}') {
    case 'CRITICAL':
      return ('Kritik', Colors.red);
    case 'HIGH':
      return ('Yüksek', Colors.deepOrange);
    case 'MEDIUM':
      return ('Orta', Colors.orange);
    case 'LOW':
      return ('Düşük', Colors.green);
    default:
      return ('${c ?? '—'}', Colors.blueGrey);
  }
}

const suggestedActions = {
  'NONE': 'İşlem gerekmiyor',
  'EARLY_REMINDER': 'Erken hatırlatma',
  'INSTALLMENT': 'Taksitlendirme görüşmesi',
  'PERSONAL_CONTACT': 'Yüz yüze görüşme',
  'LEGAL_REVIEW': 'Hukuki yolların değerlendirilmesi',
};

class SmartCollectionScreen extends StatefulWidget {
  const SmartCollectionScreen({super.key});

  @override
  State<SmartCollectionScreen> createState() => _SmartCollectionScreenState();
}

class _SmartCollectionScreenState extends State<SmartCollectionScreen> {
  bool _canWrite = false;
  bool _debtOnly = true;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _snapshot() async {
    final ok = await confirm(context, 'Skorları kaydet',
        'Bugünkü skorlar gerekçeleriyle birlikte kaydedilir (dönemsel karşılaştırma için).', ok: 'Kaydet');
    if (ok && mounted) await runAction(context, () => apiClient.post('/collection/risk/snapshot'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahsilat Riski'),
        actions: [
          FilterChip(label: const Text('Borçlular'), selected: _debtOnly, onSelected: (v) => setState(() => _debtOnly = v)),
          if (_canWrite) IconButton(tooltip: 'Skorları kaydet', icon: const Icon(Icons.save_outlined), onPressed: _snapshot),
        ],
      ),
      body: ApiObject(
        load: () => apiClient.getMap('/collection/risk'),
        builder: (context, res, reload) {
          final all = ApiClient.listOf(res).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
          final items = _debtOnly ? all.where((a) => toNum(a['current_debt']) > 0).toList() : all;
          final totals = res['totals'] is Map ? res['totals'] as Map : const {};
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              StatRow([
                ('Kritik', '${totals['CRITICAL'] ?? 0}'),
                ('Yüksek', '${totals['HIGH'] ?? 0}'),
                ('Orta', '${totals['MEDIUM'] ?? 0}'),
                ('Düşük', '${totals['LOW'] ?? 0}'),
              ]),
              for (final key in const ['note', 'method', 'short_history_note', 'data_limitation'])
                if (res[key] is String)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text('${res[key]}', style: Theme.of(context).textTheme.bodySmall),
                  ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Gösterilecek bölüm yok'))),
              for (final a in items) _RiskTile(a),
            ],
          );
        },
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  final Map<String, dynamic> a;
  const _RiskTile(this.a);

  @override
  Widget build(BuildContext context) {
    final (label, color) = riskCategory(a['risk_category']);
    final factors = a['factors'] is List ? (a['factors'] as List).whereType<Map>().toList() : const <Map>[];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text('${a['risk_score'] ?? 0}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ),
        title: Text('${a['unit_name'] ?? ''}'),
        subtitle: Text('Borç: ${formatTry(toNum(a['current_debt']))} · $label'
            '${a['reliable'] == false ? ' · kısa geçmiş' : ''}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tahakkuk: ${a['total_assessments'] ?? 0} · zamanında: ${a['paid_on_time'] ?? 0} · '
              'geç: ${a['paid_late'] ?? 0} · ödenmemiş: ${a['unpaid'] ?? 0}'),
          Text('Ortalama gecikme: ${a['average_delay_days'] ?? '0'} gün · en uzun: ${a['longest_overdue_days'] ?? 0} gün'),
          const SizedBox(height: 8),
          for (final f in factors) Text('• ${f['detail'] ?? f['code']} (+${f['points'] ?? 0})'),
          const SizedBox(height: 8),
          Text('Öneri: ${suggestedActions[a['suggested_action']] ?? a['suggested_action'] ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if ((a['suggested_action_reason'] ?? '').toString().isNotEmpty) Text('${a['suggested_action_reason']}'),
          if ((a['note'] ?? '').toString().isNotEmpty)
            Text('${a['note']}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
