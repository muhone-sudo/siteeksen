import 'package:flutter/material.dart';
import '../../core/theme/apple_theme.dart';
import '../../core/widgets/apple_widgets.dart';

/// Banka Entegrasyonu Yönetim Ekranı - Apple Tarzı
class BankIntegrationScreen extends StatefulWidget {
  const BankIntegrationScreen({super.key});

  @override
  State<BankIntegrationScreen> createState() => _BankIntegrationScreenState();
}

class _BankIntegrationScreenState extends State<BankIntegrationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedAccount = 0;
  bool _isSyncing = false;

  final List<Map<String, dynamic>> _bankAccounts = [
    {
      'id': '1',
      'bank': 'Ziraat Bankası',
      'bankCode': 'ziraat',
      'accountNo': '1234567890',
      'iban': 'TR12 0001 0012 3456 7890 1234 56',
      'balance': 125750.00,
      'lastSync': '10 dakika önce',
      'logo': 'assets/banks/ziraat.png',
      'color': Color(0xFF00843D),
    },
    {
      'id': '2',
      'bank': 'Garanti BBVA',
      'bankCode': 'garanti',
      'accountNo': '9876543210',
      'iban': 'TR34 0006 2012 3456 7890 1234 56',
      'balance': 45320.50,
      'lastSync': '1 saat önce',
      'logo': 'assets/banks/garanti.png',
      'color': Color(0xFF00A94F),
    },
  ];

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '1',
      'date': '01.02.2026',
      'time': '14:30',
      'type': 'incoming',
      'amount': 1150.00,
      'description': 'MEHMET YILMAZ D.105 AIDAT',
      'senderName': 'MEHMET YILMAZ',
      'senderIban': 'TR12 0001 0098 7654 3210 1234 56',
      'matchStatus': 'matched',
      'matchedResident': 'Mehmet Yılmaz - D.105',
      'confidence': 0.99,
    },
    {
      'id': '2',
      'date': '01.02.2026',
      'time': '11:45',
      'type': 'incoming',
      'amount': 1100.00,
      'description': 'HAVALE - AHMET',
      'senderName': 'AHMET KAYA',
      'senderIban': 'TR34 0006 2098 7654 3210 9876 54',
      'matchStatus': 'pending',
      'suggestedMatches': [
        {'name': 'Ahmet Kaya - A.201', 'amount': 1100.00, 'confidence': 0.85},
        {'name': 'Ahmet Özkan - B.305', 'amount': 1100.00, 'confidence': 0.60},
      ],
    },
    {
      'id': '3',
      'date': '31.01.2026',
      'time': '16:20',
      'type': 'outgoing',
      'amount': -5500.00,
      'description': 'ELEKTRİK FATURASI ÖDEMESİ',
      'receiverName': 'AYEDAŞ',
      'matchStatus': 'expense',
    },
    {
      'id': '4',
      'date': '31.01.2026',
      'time': '09:15',
      'type': 'incoming',
      'amount': 2300.00,
      'description': 'TOPLANTI SALONU REZERVASYON',
      'senderName': 'ALİ VURAL',
      'senderIban': 'TR56 0012 3098 7654 3210 5678 90',
      'matchStatus': 'manual',
      'matchedResident': 'Ali Vural - C.402',
    },
  ];

  final Map<String, dynamic> _stats = {
    'todayIncoming': 12450.00,
    'todayTransactions': 8,
    'pendingMatch': 3,
    'monthlyTotal': 245680.00,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                        Text('Banka Entegrasyonu', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                        Text('Havale/EFT otomatik eşleştirme', style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                      ],
                    ),
                    Row(
                      children: [
                        _buildSyncButton(),
                        const SizedBox(width: 12),
                        _buildAddAccountButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildStatCard('Bugün Gelen', '₺${_formatMoney(_stats['todayIncoming'])}', Icons.arrow_downward_rounded, AppleTheme.systemGreen),
                    _buildStatCard('İşlem Sayısı', '${_stats['todayTransactions']}', Icons.receipt_long_rounded, AppleTheme.systemBlue),
                    _buildStatCard('Eşleşme Bekleyen', '${_stats['pendingMatch']}', Icons.link_off_rounded, AppleTheme.systemOrange),
                    _buildStatCard('Aylık Toplam', '₺${_formatMoney(_stats['monthlyTotal'])}', Icons.calendar_month_rounded, AppleTheme.systemPurple),
                  ],
                ),
              ),
            ),

            // Bank Accounts
            const SliverToBoxAdapter(child: AppleSectionTitle(title: 'Banka Hesapları')),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _bankAccounts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _bankAccounts.length) {
                      return _buildAddBankCard();
                    }
                    return _buildBankAccountCard(_bankAccounts[index], index);
                  },
                ),
              ),
            ),

            // Tabs
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGray6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: AppleTheme.label,
                  unselectedLabelColor: AppleTheme.secondaryLabel,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Tüm Hareketler'),
                    Tab(text: 'Eşleşme Bekleyen'),
                    Tab(text: 'Giderler'),
                  ],
                ),
              ),
            ),

            // Transactions List
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: AppleTheme.cardDecoration,
                child: Column(
                  children: _transactions.asMap().entries.map((entry) {
                    return _buildTransactionTile(entry.value, isLast: entry.key == _transactions.length - 1);
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return AnimatedContainer(
      duration: AppleTheme.fastAnimation,
      child: OutlinedButton.icon(
        onPressed: _isSyncing ? null : _syncTransactions,
        icon: _isSyncing
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.sync_rounded, size: 18),
        label: Text(_isSyncing ? 'Senkronize ediliyor...' : 'Senkronize Et'),
      ),
    );
  }

  Widget _buildAddAccountButton() {
    return IconButton(
      onPressed: () => _showAddAccountSheet(context),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppleTheme.systemBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                child: Text('Bugün', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text(title, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(Map<String, dynamic> account, int index) {
    final isSelected = _selectedAccount == index;
    final color = account['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _selectedAccount = index),
      child: AnimatedContainer(
        duration: AppleTheme.fastAnimation,
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.account_balance_rounded, color: color, size: 20),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: AppleTheme.systemGreen, shape: BoxShape.circle),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account['bank'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('₺${_formatMoney(account['balance'])}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                Text('Son: ${account['lastSync']}', style: TextStyle(fontSize: 11, color: AppleTheme.tertiaryLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBankCard() {
    return InkWell(
      onTap: () => _showAddAccountSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppleTheme.systemGray6,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppleTheme.systemGray4, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppleTheme.systemBlue, size: 32),
            const SizedBox(height: 4),
            Text('Hesap Ekle', style: TextStyle(fontSize: 12, color: AppleTheme.systemBlue, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction, {bool isLast = false}) {
    final isIncoming = transaction['type'] == 'incoming';
    final matchStatus = transaction['matchStatus'] as String;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (matchStatus) {
      case 'matched':
        statusColor = AppleTheme.systemGreen;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Eşleşti';
        break;
      case 'pending':
        statusColor = AppleTheme.systemOrange;
        statusIcon = Icons.pending_rounded;
        statusText = 'Bekliyor';
        break;
      case 'manual':
        statusColor = AppleTheme.systemBlue;
        statusIcon = Icons.touch_app_rounded;
        statusText = 'Manuel';
        break;
      default:
        statusColor = AppleTheme.systemGray;
        statusIcon = Icons.receipt_rounded;
        statusText = 'Gider';
    }

    return Column(
      children: [
        InkWell(
          onTap: () => _showTransactionDetail(context, transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isIncoming ? AppleTheme.systemGreen : AppleTheme.systemRed).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isIncoming ? AppleTheme.systemGreen : AppleTheme.systemRed,
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction['senderName'] ?? transaction['receiverName'] ?? 'Bilinmeyen',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${isIncoming ? '+' : ''}₺${_formatMoney((transaction['amount'] as double).abs())}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isIncoming ? AppleTheme.systemGreen : AppleTheme.systemRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction['description'],
                        style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${transaction['date']} ${transaction['time']}',
                            style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (matchStatus == 'matched' && transaction['matchedResident'] != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppleTheme.systemGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_rounded, size: 14, color: AppleTheme.systemGreen),
                              const SizedBox(width: 4),
                              Text(transaction['matchedResident'], style: TextStyle(fontSize: 12, color: AppleTheme.systemGreen)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
          ),
      ],
    );
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _syncTransactions() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSyncing = false);
  }

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Banka Hesabı Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildBankOption('Ziraat Bankası', Color(0xFF00843D)),
                  _buildBankOption('Garanti BBVA', Color(0xFF00A94F)),
                  _buildBankOption('İş Bankası', Color(0xFF0A4D87)),
                  _buildBankOption('Yapı Kredi', Color(0xFF00529B)),
                  _buildBankOption('Akbank', Color(0xFFE30A17)),
                  _buildBankOption('Vakıfbank', Color(0xFF0066B3)),
                  _buildBankOption('Halkbank', Color(0xFF003366)),
                  _buildBankOption('QNB Finansbank', Color(0xFF660066)),
                  _buildBankOption('ING', Color(0xFFFF6200)),
                  _buildBankOption('Denizbank', Color(0xFF003B5C)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankOption(String name, Color color) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.account_balance_rounded, color: color),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppleTheme.systemGray3),
      onTap: () {
        Navigator.pop(context);
        // Show bank credentials form
      },
    );
  }

  void _showTransactionDetail(BuildContext context, Map<String, dynamic> transaction) {
    final matchStatus = transaction['matchStatus'] as String;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Amount
                  Center(
                    child: Text(
                      '${transaction['type'] == 'incoming' ? '+' : ''}₺${_formatMoney((transaction['amount'] as double).abs())}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: transaction['type'] == 'incoming' ? AppleTheme.systemGreen : AppleTheme.systemRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${transaction['date']} ${transaction['time']}',
                      style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow('Gönderen', transaction['senderName'] ?? '-'),
                  _buildDetailRow('IBAN', transaction['senderIban'] ?? '-'),
                  _buildDetailRow('Açıklama', transaction['description']),

                  const SizedBox(height: 24),

                  // Match Actions
                  if (matchStatus == 'pending' && transaction['suggestedMatches'] != null) ...[
                    const Text('Önerilen Eşleşmeler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...List.generate(
                      (transaction['suggestedMatches'] as List).length,
                      (index) {
                        final match = transaction['suggestedMatches'][index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppleTheme.systemGray6,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(match['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('₺${match['amount']} • %${(match['confidence'] * 100).toInt()} güven', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Match transaction
                                },
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                child: const Text('Eşleştir'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  if (matchStatus == 'matched') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppleTheme.systemGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppleTheme.systemGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Eşleştirildi', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text(transaction['matchedResident'], style: TextStyle(color: AppleTheme.secondaryLabel)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: AppleTheme.secondaryLabel)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
