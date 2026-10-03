// Site davetleri (S-20, 2026-10-03).
//
// Başka bir sitenin yönetimi kişiyi sakin olarak eklemek istediğinde daire bağı
// KURULMAZ; davet açılır. Kişi burada kabul ederse daireye bağlanır, reddederse
// hiçbir şey olmaz. Davet 14 gün geçerlidir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/data_state.dart';

const _roleLabels = {'OWNER': 'Kat maliki', 'TENANT': 'Kiracı', 'PROXY': 'Vekil'};

/// "Güneş Sitesi · A-3 (Kat maliki)"
String invitationTitle(Map<dynamic, dynamic> inv) {
  final site = '${inv['property_name'] ?? 'Site'}';
  final unit = '${inv['unit'] ?? ''}';
  final role = _roleLabels['${inv['role']}'] ?? '${inv['role'] ?? ''}';
  return [site, if (unit.isNotEmpty) unit].join(' · ') + (role.isEmpty ? '' : ' ($role)');
}

/// Ana sayfada yanıt bekleyen davetleri gösterir; davet yoksa yer kaplamaz.
class InvitationsBanner extends StatefulWidget {
  const InvitationsBanner({super.key});

  @override
  State<InvitationsBanner> createState() => _InvitationsBannerState();
}

class _InvitationsBannerState extends State<InvitationsBanner> {
  List<Map<dynamic, dynamic>> _items = const [];
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await apiClient.getMyInvitations();
      if (!mounted) return;
      setState(() {
        _items = list.whereType<Map>().toList();
        _error = null;
      });
    } catch (e) {
      // Ana sayfayı engellemez ama sessizce de geçmez: kısa bir uyarı gösterilir.
      if (mounted) setState(() => _error = toUserMessage(e));
    }
  }

  Future<void> _respond(Map<dynamic, dynamic> inv, bool accept) async {
    final id = '${inv['id']}';
    setState(() => _busyId = id);
    try {
      final res = await apiClient.respondInvitation(id, accept: accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${res['message'] ?? (accept ? 'Davet kabul edildi' : 'Davet reddedildi')}'),
      ));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ListTile(
        dense: true,
        leading: const Icon(Icons.mail_outline, color: AppleTheme.tertiaryLabel),
        title: const Text('Site davetleri alınamadı'),
        trailing: TextButton(onPressed: _load, child: const Text('Yeniden dene')),
      );
    }
    if (_items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final inv in _items)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: AppleTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Site daveti', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(invitationTitle(inv)),
                const SizedBox(height: 4),
                const Text(
                  'Kabul ederseniz bu siteye sakin olarak eklenirsiniz; site yönetimi ad ve '
                  'iletişim bilgilerinizi görebilir.',
                  style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _busyId == null ? () => _respond(inv, false) : null,
                      child: const Text('Reddet'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busyId == null ? () => _respond(inv, true) : null,
                      child: const Text('Kabul et'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
