// Ortak alan geliri payım (FAZ 7.6, 2026-10-04).
//
// Ortak yer kira geliri kat maliklerinindir; her malik kendi payını yıllık
// beyannamesinde değerlendirir. Ekran, sakinin MALİKİ olduğu bölümlerin payını gösterir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

/// Kuruştan TL metni.
String kurusText(Object? v) => formatTry(toNum(v) / 100);

class CommonIncomeScreen extends StatefulWidget {
  const CommonIncomeScreen({super.key});

  @override
  State<CommonIncomeScreen> createState() => _CommonIncomeScreenState();
}

class _CommonIncomeScreenState extends State<CommonIncomeScreen> {
  int _year = DateTime.now().year - 1;
  late Future<Map<String, dynamic>> _future = apiClient.getMyCommonIncome(_year);

  void _setYear(int y) => setState(() {
        _year = y;
        _future = apiClient.getMyCommonIncome(y);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ortak alan geliri payım')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: () => _setYear(_year));
          final d = snap.data!;
          final rows = ApiClient.listOf(d['data']).whereType<Map>().toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              IconButton(onPressed: () => _setYear(_year - 1), icon: const Icon(Icons.chevron_left)),
              Text('$_year', style: Theme.of(context).textTheme.titleMedium),
              IconButton(onPressed: () => _setYear(_year + 1), icon: const Icon(Icons.chevron_right)),
            ]),
            if (rows.isEmpty) const EmptyStateView(message: 'Bu yıl için payınıza düşen ortak alan geliri yok', icon: Icons.savings_outlined),
            for (final r in rows)
              ListTile(
                title: Text('${r['unit']}'),
                subtitle: Text('Brüt ${kurusText(r['gross_kurus'])} · stopaj ${kurusText(r['withholding_kurus'])}'),
                trailing: Text(kurusText(toNum(r['gross_kurus']) - toNum(r['withholding_kurus']))),
              ),
            const SizedBox(height: 12),
            Text('${d['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
          ]);
        },
      ),
    );
  }
}