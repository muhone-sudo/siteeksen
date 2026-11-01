// Bakiye ve paket (FAZ M5, K5/K6): kartla yükleme iyzico ödeme sayfasında yapılır; mobilde sayfa uygulamanın içinde açılır
// (M13.1), dönüşte bakiye sunucudan yeniden okunur. İlk yüklemeden önce bakiye ve iade koşulları ayrıca kabul edilir
// (M13.3). Paket yükseltme hemen (aidat bakiyeden), düşürme dönem sonunda.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/data_state.dart';
import 'payment_page.dart';

const ledgerKinds = {
  'TOPUP': 'Bakiye yükleme',
  'PACKAGE_FEE': 'Paket aidatı',
  'REQUEST_FEE': 'Talep kabul ücreti',
  'INCLUDED_REQUEST': 'Paketten talep hakkı',
  'REFUND': 'İade',
  'CLOSURE_REFUND': 'Kapanış iadesi',
  'CARD_REFUND': 'Karta iade',
  'EXPIRED_BALANCE': 'Süresi dolan bakiye',
};

const refundStatus = {'PENDING': 'İşleniyor', 'SUCCEEDED': 'Karta iletildi', 'FAILED': 'Gecikti (platform elle yapacak)', 'MANUAL': 'Havaleyle ödendi'};

String _kurus(Object? v) => formatTry(toNum(v) / 100);

String _idempotencyKey() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

class WalletScreen extends StatefulWidget {
  /// Web derlemesinde ödeme dönüşünün sonucu (`topup_id`, `status`, `message`); yalnız bilgi içindir.
  final Map<String, String> returned;
  const WalletScreen({super.key, this.returned = const {}});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _future;
  final _amount = TextEditingController();
  bool _termsChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _load();
    final id = widget.returned['topup_id'];
    if (id != null && id.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _showResult(id));
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

  Future<List<Map<String, dynamic>>> _load() async => [
        await apiClient.wallet(),
        await apiClient.meta(),
        (await apiClient.me()) ?? {},
        await apiClient.balanceTerms(),
        {'refunds': await apiClient.cardRefunds()},
      ];

  Future<void> _reload() async {
    setState(() { _future = _load(); });
    await _future;
  }

  Future<void> _pay() async {
    final k = ((double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0) * 100).round();
    if (k <= 0) return;
    try {
      final r = await apiClient.startTopup(k, _idempotencyKey());
      final url = r['checkout_url'] as String?;
      if (url == null) throw StateError('Ödeme sayfası adresi gelmedi');
      if (!mounted) return;
      await openPayment(context, url, '${r['result_url'] ?? ''}');
      final id = (r['topup'] as Map?)?['id'];
      if (id != null && mounted) await _showResult('$id');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is StateError ? e.message : toUserMessage(e))));
    }
  }

  /// Yüklemenin sonucu sunucudan okunur (dönüş adresindeki değerlere güvenilmez) ve bakiye yenilenir.
  Future<void> _showResult(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final t = await apiClient.topup(id);
      final msg = switch ('${t['status']}') {
        'SUCCEEDED' => 'Ödeme alındı; bakiye güncellendi.',
        'FAILED' => 'Ödeme tamamlanmadı: ${t['error_message'] ?? 'tutar kartınızdan çekilmedi'}',
        _ => 'Ödeme sonucu bekleniyor; birkaç dakika içinde bakiyenize kendiliğinden yansır.',
      };
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
    if (mounted) await _reload();
  }

  Future<void> _acceptTerms(String version) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await apiClient.acceptBalanceTerms(version);
      messenger.showSnackBar(const SnackBar(content: Text('Bakiye ve iade koşullarını kabul ettiniz')));
      await _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  Widget _termsCard(Map<String, dynamic> terms) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${terms['title']}', style: Theme.of(context).textTheme.titleMedium),
          Text('Sürüm ${terms['version']}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(child: Text('${terms['text']}')),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _termsChecked,
            onChanged: (v) => setState(() => _termsChecked = v ?? false),
            title: const Text('Bakiye ve iade koşullarını okudum, kabul ediyorum'),
          ),
          FilledButton(onPressed: _termsChecked ? () => _acceptTerms('${terms['version']}') : null, child: const Text('Koşulları kabul et')),
        ]),
      ),
    );
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
          final w = snap.data![0], meta = snap.data![1], me = snap.data![2], terms = snap.data![3];
          final refunds = (snap.data![4]['refunds'] as List? ?? const []).whereType<Map>().toList();
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
                else if (w['card_ready'] == true && terms['accepted'] == null)
                  _termsCard(terms)
                else if (w['card_ready'] == true) ...[
                  TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yüklenecek tutar (TL)')),
                  const SizedBox(height: 8),
                  FilledButton.icon(onPressed: _pay, icon: const Icon(Icons.credit_card), label: const Text('Kartla öde')),
                  Text('Ödeme iyzico sayfasında 3D Secure ile alınır; kart bilgileriniz SiteEksen\'e gelmez. Bakiye çekilemez; '
                      'üyelik sona erince son 365 günde yüklenen kısmı karta iade edilir (koşullar sürüm ${terms['version']}, '
                      'kabul ${formatDate((terms['accepted'] as Map?)?['accepted_at'])}).'),
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
                if (refunds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Karta iadeler', style: Theme.of(context).textTheme.titleMedium),
                  for (final r in refunds)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${_kurus(r['amount_kurus'])} · ${refundStatus['${r['status']}'] ?? r['status']}'),
                      subtitle: Text('${formatDateTime(r['created_at'])} · yükleme ${formatDate(r['topup_at'])}'
                          '${r['manual_reference'] != null ? ' · dekont ${r['manual_reference']}' : ''}'),
                    ),
                ],
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
