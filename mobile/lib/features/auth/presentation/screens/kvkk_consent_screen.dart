import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';

class KvkkConsentScreen extends StatefulWidget {
  const KvkkConsentScreen({super.key});

  @override
  State<KvkkConsentScreen> createState() => _KvkkConsentScreenState();
}

class _KvkkConsentScreenState extends State<KvkkConsentScreen> {
  bool _accepted = false;
  bool _isSubmitting = false;

  Future<void> _handleConfirm() async {
    if (!_accepted) return;
    setState(() => _isSubmitting = true);
    try {
      await apiClient.acceptKvkkConsent();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Onay kaydedilemedi, lütfen tekrar deneyin')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kişisel Verilerin Korunması'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'SiteEksen olarak; ad-soyad, telefon, T.C. kimlik numarası, '
                      'taşınmaz ve sakinlik bilgileriniz başta olmak üzere kişisel '
                      'verilerinizi 6698 sayılı Kişisel Verilerin Korunması Kanunu '
                      '(KVKK) kapsamında; site yönetimi hizmetlerinin sunulması, '
                      'aidat/tahsilat süreçlerinin yürütülmesi, talep ve şikayetlerin '
                      'takibi ile yasal yükümlülüklerin yerine getirilmesi amacıyla '
                      'işlemekteyiz.\n\n'
                      'Verileriniz, hizmetin gerektirdiği ölçüde site yönetimi ve '
                      'yetkili kurumlarla paylaşılabilir, KVKK\'da öngörülen süreler '
                      'boyunca saklanır. KVKK\'nın 11. maddesi kapsamındaki '
                      'haklarınızı (bilgi talep etme, düzeltme, silme vb.) '
                      'kullanmak için yönetime başvurabilirsiniz.\n\n'
                      'Uygulamayı kullanmaya devam edebilmeniz için kişisel '
                      'verilerinizin yukarıda açıklanan kapsamda işlenmesine açık '
                      'rıza vermeniz gerekmektedir.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _accepted,
                  onChanged: (value) => setState(() => _accepted = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Yukarıdaki KVKK aydınlatma metnini okudum, anladım ve kişisel '
                    'verilerimin belirtilen kapsamda işlenmesine açık rızamı veriyorum.',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: (_accepted && !_isSubmitting) ? _handleConfirm : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Onaylıyorum ve Devam Ediyorum'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
