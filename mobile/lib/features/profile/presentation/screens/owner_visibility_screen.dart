// Malikim neyi görüyor (altıncı tur D6, migration 071).
//
// Kiracılı dairede malikin neyi göreceğini malik değil site yönetimi belirler; site genelinde tek politika vardır,
// varsayılan en dar ayardır ve değişiklik öneren dışındaki bir kurul üyesinin onayıyla yürürlüğe girer. Kiracı ve
// malik etkin politikayı burada görür.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

String _err(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  return toUserMessage(e);
}

class OwnerVisibilityScreen extends StatefulWidget {
  const OwnerVisibilityScreen({super.key});

  @override
  State<OwnerVisibilityScreen> createState() => _OwnerVisibilityScreenState();
}

class _OwnerVisibilityScreenState extends State<OwnerVisibilityScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await apiClient.getOwnerVisibility();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _err(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = (_data['active'] as Map?) ?? const {};
    final options = (_data['options'] as List? ?? []).whereType<Map>().toList();
    final always = (_data['always_visible'] as List? ?? []).map((e) => '$e').toList();
    final never = (_data['never_visible'] as List? ?? []).map((e) => '$e').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Malikin görebildikleri')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Text('${_data['note'] ?? ''}'),
                    const SizedBox(height: 12),
                    Text(
                      active['status'] == 'ACTIVE'
                          ? 'Yürürlükte${active['decided_at'] != null ? ' · ${formatDate(active['decided_at'])}' : ''}'
                          : 'Varsayılan (en dar) ayar geçerli',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final o in options)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(active['${o['key']}'] == true ? Icons.visibility : Icons.visibility_off,
                            color: active['${o['key']}'] == true ? Colors.orange : Colors.green),
                        title: Text('${o['label']}'),
                        subtitle: Text(active['${o['key']}'] == true ? 'Malik görür' : 'Malik görmez'),
                      ),
                    const Divider(height: 24),
                    Text('Her zaman görür', style: Theme.of(context).textTheme.titleSmall),
                    for (final a in always) Text('• $a'),
                    const SizedBox(height: 12),
                    Text('Hiçbir zaman görmez', style: Theme.of(context).textTheme.titleSmall),
                    for (final n in never) Text('• $n'),
                  ]),
                ),
    );
  }
}
