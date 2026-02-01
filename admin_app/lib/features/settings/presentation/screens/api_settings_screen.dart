import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/apple_theme.dart';
import '../../core/widgets/apple_widgets.dart';

/// API Ayarları Ekranı - Güvenli API Anahtar Yönetimi
class APISettingsScreen extends StatefulWidget {
  const APISettingsScreen({super.key});

  @override
  State<APISettingsScreen> createState() => _APISettingsScreenState();
}

class _APISettingsScreenState extends State<APISettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSecurityWarning = true;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'messaging', 'name': 'Mesajlaşma', 'icon': Icons.chat_bubble_rounded},
    {'id': 'banking', 'name': 'Banka', 'icon': Icons.account_balance_rounded},
    {'id': 'payment', 'name': 'Ödeme', 'icon': Icons.payment_rounded},
    {'id': 'ai', 'name': 'Yapay Zeka', 'icon': Icons.psychology_rounded},
    {'id': 'push', 'name': 'Bildirim', 'icon': Icons.notifications_rounded},
  ];

  final List<Map<String, dynamic>> _credentials = [
    {
      'id': '1',
      'serviceName': 'whatsapp',
      'displayName': 'WhatsApp Business API',
      'category': 'messaging',
      'apiKeyMasked': '••••••••abc123',
      'hasSecret': true,
      'isActive': true,
      'testStatus': 'success',
      'lastModified': '2 saat önce',
      'modifiedBy': 'admin',
      'fields': ['access_token', 'phone_number_id', 'business_account_id'],
    },
    {
      'id': '2',
      'serviceName': 'netgsm',
      'displayName': 'Netgsm SMS',
      'category': 'messaging',
      'apiKeyMasked': '••••••••xyz789',
      'hasSecret': true,
      'isActive': true,
      'testStatus': 'success',
      'lastModified': '1 gün önce',
      'modifiedBy': 'admin',
      'fields': ['username', 'password', 'header'],
    },
    {
      'id': '3',
      'serviceName': 'ziraat_bank',
      'displayName': 'Ziraat Bankası',
      'category': 'banking',
      'apiKeyMasked': '••••••••bnk456',
      'hasSecret': true,
      'isActive': true,
      'testStatus': 'success',
      'lastModified': '3 gün önce',
      'modifiedBy': 'admin',
      'fields': ['client_id', 'client_secret', 'iban'],
    },
    {
      'id': '4',
      'serviceName': 'garanti_bank',
      'displayName': 'Garanti BBVA',
      'category': 'banking',
      'apiKeyMasked': '••••••••grn789',
      'hasSecret': true,
      'isActive': false,
      'testStatus': 'pending',
      'lastModified': '1 hafta önce',
      'modifiedBy': 'admin',
      'fields': ['api_key', 'api_secret', 'merchant_id'],
    },
    {
      'id': '5',
      'serviceName': 'iyzico',
      'displayName': 'Iyzico Ödeme',
      'category': 'payment',
      'apiKeyMasked': '••••••••pay123',
      'hasSecret': true,
      'isActive': true,
      'testStatus': 'success',
      'lastModified': '5 gün önce',
      'modifiedBy': 'admin',
      'fields': ['api_key', 'secret_key', 'base_url'],
    },
    {
      'id': '6',
      'serviceName': 'openai',
      'displayName': 'OpenAI API',
      'category': 'ai',
      'apiKeyMasked': '••••••••sk-abc',
      'hasSecret': false,
      'isActive': true,
      'testStatus': 'success',
      'lastModified': '1 hafta önce',
      'modifiedBy': 'admin',
      'fields': ['api_key'],
    },
    {
      'id': '7',
      'serviceName': 'firebase_fcm',
      'displayName': 'Firebase Cloud Messaging',
      'category': 'push',
      'apiKeyMasked': '••••••••fcm789',
      'hasSecret': false,
      'isActive': true,
      'testStatus': 'failed',
      'lastModified': '2 hafta önce',
      'modifiedBy': 'admin',
      'fields': ['server_key', 'project_id'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security_rounded, color: AppleTheme.systemOrange, size: 28),
                            SizedBox(width: 10),
                            Text('API Ayarları', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text('Dış servis entegrasyonlarını yönetin', style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddCredentialSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Yeni API'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemBlue),
                    ),
                  ],
                ),
              ),
            ),

            // Security Warning Banner
            if (_showSecurityWarning)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppleTheme.systemOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppleTheme.systemOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppleTheme.systemOrange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hassas Bilgi Alanı', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Bu sayfadaki bilgiler şifrelenmiş olarak saklanır. Her değişiklik kayıt altındadır.', 
                              style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showSecurityWarning = false),
                        icon: Icon(Icons.close_rounded, color: AppleTheme.systemGray2, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

            // Category Tabs
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGray6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: AppleTheme.label,
                  unselectedLabelColor: AppleTheme.secondaryLabel,
                  dividerColor: Colors.transparent,
                  tabs: _categories.map((cat) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'], size: 16),
                        const SizedBox(width: 6),
                        Text(cat['name']),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),

            // Credentials List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Tab'a göre filtrele
                    final categoryId = _categories[_tabController.index]['id'];
                    final filtered = _credentials.where((c) => c['category'] == categoryId).toList();
                    if (index >= filtered.length) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCredentialCard(filtered[index]),
                    );
                  },
                  childCount: _credentials.where((c) => c['category'] == _categories[_tabController.index]['id']).length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialCard(Map<String, dynamic> credential) {
    final isActive = credential['isActive'] == true;
    final testStatus = credential['testStatus'] as String;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (testStatus) {
      case 'success':
        statusColor = AppleTheme.systemGreen;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Bağlı';
        break;
      case 'failed':
        statusColor = AppleTheme.systemRed;
        statusIcon = Icons.error_rounded;
        statusText = 'Hata';
        break;
      default:
        statusColor = AppleTheme.systemGray;
        statusIcon = Icons.pending_rounded;
        statusText = 'Test edilmedi';
    }

    return Container(
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppleTheme.systemBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getServiceIcon(credential['serviceName']), color: AppleTheme.systemBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(credential['displayName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(credential['serviceName'], style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (value) => _toggleActive(credential, value),
                      activeColor: AppleTheme.systemGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // API Key Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppleTheme.systemGray6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, size: 16, color: AppleTheme.secondaryLabel),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          credential['apiKeyMasked'],
                          style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: AppleTheme.secondaryLabel),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showKeyTemporarily(credential),
                        icon: Icon(Icons.visibility_rounded, size: 18, color: AppleTheme.systemBlue),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Göster (30 sn)',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _copyKey(credential),
                        icon: Icon(Icons.copy_rounded, size: 18, color: AppleTheme.systemBlue),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Kopyala',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Status & Info Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('${credential['modifiedBy']} • ${credential['lastModified']}', 
                      style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppleTheme.systemGray6.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _testConnection(credential),
                  icon: Icon(Icons.speed_rounded, size: 16, color: AppleTheme.systemBlue),
                  label: Text('Test Et', style: TextStyle(color: AppleTheme.systemBlue)),
                ),
                TextButton.icon(
                  onPressed: () => _showEditSheet(context, credential),
                  icon: Icon(Icons.edit_rounded, size: 16, color: AppleTheme.systemOrange),
                  label: Text('Düzenle', style: TextStyle(color: AppleTheme.systemOrange)),
                ),
                TextButton.icon(
                  onPressed: () => _showAuditLog(context, credential),
                  icon: Icon(Icons.history_rounded, size: 16, color: AppleTheme.secondaryLabel),
                  label: Text('Geçmiş', style: TextStyle(color: AppleTheme.secondaryLabel)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'whatsapp':
        return Icons.chat_bubble_rounded;
      case 'netgsm':
      case 'ileti_merkezi':
        return Icons.sms_rounded;
      case 'ziraat_bank':
      case 'garanti_bank':
      case 'akbank':
      case 'is_bankasi':
      case 'yapi_kredi':
        return Icons.account_balance_rounded;
      case 'iyzico':
        return Icons.payment_rounded;
      case 'openai':
      case 'gemini':
      case 'whisper':
        return Icons.psychology_rounded;
      case 'firebase_fcm':
        return Icons.notifications_rounded;
      default:
        return Icons.api_rounded;
    }
  }

  void _toggleActive(Map<String, dynamic> credential, bool value) {
    _showConfirmDialog(
      title: value ? 'API\'yi Etkinleştir' : 'API\'yi Devre Dışı Bırak',
      message: value 
        ? '${credential['displayName']} API\'si etkinleştirilecek.'
        : '${credential['displayName']} API\'si devre dışı bırakılacak. Bu, ilgili servisleri etkileyebilir.',
      confirmText: value ? 'Etkinleştir' : 'Devre Dışı Bırak',
      isDestructive: !value,
      onConfirm: () {
        setState(() => credential['isActive'] = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'API etkinleştirildi' : 'API devre dışı bırakıldı')),
        );
      },
    );
  }

  void _showKeyTemporarily(Map<String, dynamic> credential) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.visibility_rounded, color: AppleTheme.systemOrange),
            const SizedBox(width: 8),
            const Text('API Anahtarı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppleTheme.systemGray6, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'sk-1234567890abcdefghijklmnopqrstuvwxyz', // Demo key
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'sk-1234567890abcdefghijklmnopqrstuvwxyz'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Anahtar kopyalandı')),
                      );
                    },
                    icon: Icon(Icons.copy_rounded, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Bu pencere 30 saniye sonra otomatik kapanacak.', 
              style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
        ],
      ),
    );
    
    // 30 saniye sonra kapat
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void _copyKey(Map<String, dynamic> credential) {
    Clipboard.setData(ClipboardData(text: credential['apiKeyMasked']));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maskelenmiş anahtar kopyalandı')),
    );
  }

  void _testConnection(Map<String, dynamic> credential) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('${credential['displayName']} test ediliyor...'),
          ],
        ),
      ),
    );

    // Simulated test
    await Future.delayed(const Duration(seconds: 2));
    
    Navigator.pop(context);
    
    setState(() => credential['testStatus'] = 'success');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Bağlantı başarılı (245ms)'),
          ],
        ),
        backgroundColor: AppleTheme.systemGreen,
      ),
    );
  }

  void _showAddCredentialSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CredentialFormSheet(isNew: true),
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> credential) {
    _showConfirmDialog(
      title: 'API Düzenleme',
      message: 'Bu API anahtarını düzenlemek istediğinizden emin misiniz? Değişiklikler kayıt altına alınacaktır.',
      confirmText: 'Düzenle',
      onConfirm: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _CredentialFormSheet(isNew: false, credential: credential),
        );
      },
    );
  }

  void _showAuditLog(BuildContext context, Map<String, dynamic> credential) {
    final auditLog = [
      {'action': 'Güncelleme', 'field': 'api_key', 'user': 'admin', 'date': '2 saat önce', 'ip': '192.168.1.100'},
      {'action': 'Test', 'field': '-', 'user': 'admin', 'date': '3 saat önce', 'ip': '192.168.1.100'},
      {'action': 'Oluşturma', 'field': '-', 'user': 'super_admin', 'date': '1 hafta önce', 'ip': '192.168.1.50'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: AppleTheme.systemBlue),
                  const SizedBox(width: 8),
                  Text('${credential['displayName']} - Değişiklik Geçmişi', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: auditLog.length,
                itemBuilder: (context, index) {
                  final entry = auditLog[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppleTheme.systemBlue.withOpacity(0.12),
                      child: Icon(
                        entry['action'] == 'Güncelleme' ? Icons.edit_rounded :
                        entry['action'] == 'Test' ? Icons.speed_rounded : Icons.add_rounded,
                        size: 18,
                        color: AppleTheme.systemBlue,
                      ),
                    ),
                    title: Text(entry['action']!),
                    subtitle: Text('${entry['user']} • ${entry['ip']}'),
                    trailing: Text(entry['date']!, style: TextStyle(color: AppleTheme.tertiaryLabel, fontSize: 12)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? AppleTheme.systemRed : AppleTheme.systemBlue,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Credential Form Sheet
class _CredentialFormSheet extends StatefulWidget {
  final bool isNew;
  final Map<String, dynamic>? credential;

  const _CredentialFormSheet({required this.isNew, this.credential});

  @override
  State<_CredentialFormSheet> createState() => _CredentialFormSheetState();
}

class _CredentialFormSheetState extends State<_CredentialFormSheet> {
  String? _selectedService;
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  bool _obscureKey = true;
  bool _obscureSecret = true;

  final List<Map<String, dynamic>> _availableServices = [
    {'name': 'whatsapp', 'displayName': 'WhatsApp Business API', 'category': 'messaging'},
    {'name': 'netgsm', 'displayName': 'Netgsm SMS', 'category': 'messaging'},
    {'name': 'ileti_merkezi', 'displayName': 'İleti Merkezi SMS', 'category': 'messaging'},
    {'name': 'ziraat_bank', 'displayName': 'Ziraat Bankası', 'category': 'banking'},
    {'name': 'garanti_bank', 'displayName': 'Garanti BBVA', 'category': 'banking'},
    {'name': 'akbank', 'displayName': 'Akbank', 'category': 'banking'},
    {'name': 'is_bankasi', 'displayName': 'İş Bankası', 'category': 'banking'},
    {'name': 'yapi_kredi', 'displayName': 'Yapı Kredi', 'category': 'banking'},
    {'name': 'iyzico', 'displayName': 'Iyzico Ödeme', 'category': 'payment'},
    {'name': 'openai', 'displayName': 'OpenAI API', 'category': 'ai'},
    {'name': 'gemini', 'displayName': 'Google Gemini', 'category': 'ai'},
    {'name': 'firebase_fcm', 'displayName': 'Firebase Cloud Messaging', 'category': 'push'},
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isNew && widget.credential != null) {
      _selectedService = widget.credential!['serviceName'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                Text(widget.isNew ? 'Yeni API Ekle' : 'API Düzenle', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                TextButton(onPressed: _save, child: const Text('Kaydet')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Security Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppleTheme.systemBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, color: AppleTheme.systemBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Girdiğiniz bilgiler AES-256 ile şifrelenerek saklanır.', 
                          style: TextStyle(fontSize: 13, color: AppleTheme.systemBlue)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Service Selector
                if (widget.isNew) ...[
                  const Text('Servis Seçin', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedService,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'Servis seçin...',
                    ),
                    items: _availableServices.map((s) => DropdownMenuItem(
                      value: s['name'] as String,
                      child: Text(s['displayName'] as String),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedService = value),
                  ),
                  const SizedBox(height: 20),
                ],

                // API Key
                const Text('API Anahtarı', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'API anahtarını girin...',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // API Secret
                const Text('API Secret (Opsiyonel)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiSecretController,
                  obscureText: _obscureSecret,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'API secret girin...',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureSecret ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_selectedService == null || _apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurun'), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isNew ? 'API başarıyla eklendi' : 'API başarıyla güncellendi'),
        backgroundColor: AppleTheme.systemGreen,
      ),
    );
  }
}
