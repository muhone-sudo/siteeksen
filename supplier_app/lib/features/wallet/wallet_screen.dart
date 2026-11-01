// Bakiye ve paket (FAZ M5, K5/K6): kartla yükleme iyzico ödeme sayfasında, tarayıcıda yapılır; uygulamaya dönünce
// bakiye yenilenir. Paket yükseltme hemen (aidat bakiyeden), düşürme dönem sonunda.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/data_state.dart';

const ledgerKinds = {
  'TOPUP': 'Bakiye yükleme',
  'PACKAGE_FEE': 'Paket aidatı',
  'REQUEST_FEE': 'Talep kabul ücreti',
  'INCLUDED_REQUEST': 'Paketten talep hakkı',
  'REFUND': 'İade',
  'CLOSURE_REFUND': 'Kapanış iadesi',
};

String _kurus(Object? v) => formatTry(toNum(v) / 100);

String _idempotencyKey() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _future;
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amount.dispose();
    super.dispose();
  }

  /// Ödeme sayfasından uygulamaya dönülünce bakiye yeniden okunur.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<List<Map<String, dynamic>>> _load() async => [await apiClient.wallet(), await apiClient.meta(), (await apiClient.me()) ?? {}];

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _pay() async {
    final k = ((double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0) * 100).round();
    if (k <= 0) return;
    try {
      final r = await apiClient.startTopup(k, _idempotencyKey());
      final url = r['checkout_url'] as String?;
      if (url == null) throw StateError('Ödeme sayfası adresi gelmedi');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication, webOnlyWindowName: '_self');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is StateError ? e.message : toUserMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bakiye ve paket'), actions: [IconButton(tooltip: 'Yenile', onPressed: _reload, icon: const Icon(Icons.refresh))]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final w = snap.data![0], meta = snap.data![1], me = snap.data![2];
          final pkg = w['package'] as Map;
          final closed = me['status'] == 'CLOSED';
          final frozen = closed || me['status'] == 'SUSPENDED';
          final ledger = (w['data'] as List? ?? const []).whereType<Map>().toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              children: [
                Text('Bakiye: ${_kurus(w['balance_kurus'])}', style: Theme.of(context).textTheme.headlineSmall),
                Text('Paket: ${pkg['name']}${w['package_renews_at'] != null ? ' · yenileme ${formatDate(w['package_renews_at'])}' : ''}'),
                Text('Bu dönem kalan: ${w['period_included_left']} dahil talep, ${w['period_sms_left']} SMS'),
                const SizedBox(height: 16),
                if (closed)
                  const Text('Üyeliğiniz kapatıldı; bakiye yüklenemez ve paket değiştirilemez.')
                else if (w['card_ready'] == true) ...[
                  TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yüklenecek tutar (TL)')),
                  const SizedBox(height: 8),
                  FilledButton.icon(onPressed: _pay, icon: const Icon(Icons.credit_card), label: const Text('Kartla öde')),
                  const Text('Ödeme iyzico sayfasında 3D Secure ile alınır; kart bilgileriniz SiteEksen\'e gelmez. Bakiye çekilemez.'),
                ] else
                  const Text('Kartla ödeme bu kurulumda yapılandırılmamış.'),
                const SizedBox(height: 16),
                Text('Paketler', style: Theme.of(context).textTheme.titleMedium),
                for (final p in (meta['packages'] as List? ?? const []).whereType<Map>())
                  Card(
                    child: ListTile(
                      title: Text('${p['name']} · ${toNum(p['monthly_fee_kurus']) > 0 ? '${_kurus(p['monthly_fee_kurus'])} / ay' : 'Ücretsiz'}'),
                      subtitle: Text('%${p['fee_discount_pct']} talep indirimi · ayda ${p['included_requests']} talep, ${p['monthly_sms']} SMS'
                          '${p['priority_access'] == true ? ' · yeni talepleri önce görür' : ''}${p['phone_in_showcase'] == true ? ' · telefon vitrinde' : ''}'),
                      trailing: p['id'] == pkg['id']
                          ? const Text('Mevcut')
                          : frozen
                              ? null
                              : TextButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      final r = await apiClient.changePackage('${p['id']}');
                                      messenger.showSnackBar(SnackBar(content: Text('${r['message']}')));
                                      await _reload();
                                    } catch (e) {
                                      messenger.showSnackBar(SnackBar(content: Text(toUserMessage(e))));
                                    }
                                  },
                                  child: Text(p['id'] == w['next_package_id'] ? 'Dönem sonunda' : 'Bu pakete geç'),
                                ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Hareketler', style: Theme.of(context).textTheme.titleMedium),
                if (ledger.isEmpty) const Text('Henüz hareket yok. Bakiye yüklediğinizde burada görünür.'),
                for (final l in ledger)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${ledgerKinds['${l['kind']}'] ?? l['kind']} · ${_kurus(l['amount_kurus'])}'),
                    subtitle: Text('${formatDateTime(l['created_at'])} · ${l['note']}'),
                    trailing: Text(_kurus(l['balance_after'])),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
