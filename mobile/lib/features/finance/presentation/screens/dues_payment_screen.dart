import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Aidat Ödeme Ekranı - Apple Tarzı
class DuesPaymentScreen extends StatefulWidget {
  const DuesPaymentScreen({super.key});

  @override
  State<DuesPaymentScreen> createState() => _DuesPaymentScreenState();
}

class _DuesPaymentScreenState extends State<DuesPaymentScreen> {
  int _selectedPaymentMethod = 0;
  
  final Map<String, dynamic> _duesInfo = {
    'currentDebt': 1250.00,
    'dueDate': '15 Şubat 2026',
    'lastPayment': '₺1,100 - 15 Ocak 2026',
  };

  final List<Map<String, dynamic>> _pendingDues = [
    {'month': 'Ocak 2026', 'amount': 1100.00, 'status': 'paid'},
    {'month': 'Şubat 2026', 'amount': 1150.00, 'status': 'pending'},
    {'month': 'Gecikme Faizi', 'amount': 100.00, 'status': 'late'},
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Kredi/Banka Kartı', 'icon': Icons.credit_card_rounded, 'color': AppleTheme.systemBlue},
    {'name': 'Havale/EFT', 'icon': Icons.account_balance_rounded, 'color': AppleTheme.systemGreen},
    {'name': 'Sanal POS', 'icon': Icons.phone_iphone_rounded, 'color': AppleTheme.systemPurple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Aidat Ödeme'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          // Total Debt Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppleTheme.systemRed.withOpacity(0.12), AppleTheme.systemOrange.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppleTheme.systemRed.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Toplam Borç', style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppleTheme.systemRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Ödenmemiş', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.systemRed)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺${_duesInfo['currentDebt'].toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppleTheme.systemRed, letterSpacing: -1),
                  ),
                  const SizedBox(height: 4),
                  Text('Son ödeme tarihi: ${_duesInfo['dueDate']}', style: TextStyle(fontSize: 14, color: AppleTheme.tertiaryLabel)),
                ],
              ),
            ),
          ),

          // Dues Breakdown
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Borç Detayları'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                children: _pendingDues.asMap().entries.map((entry) {
                  final due = entry.value;
                  final isPaid = due['status'] == 'paid';
                  final isLate = due['status'] == 'late';
                  
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isPaid 
                                    ? AppleTheme.systemGreen.withOpacity(0.12)
                                    : isLate 
                                        ? AppleTheme.systemRed.withOpacity(0.12)
                                        : AppleTheme.systemOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isPaid ? Icons.check_circle_rounded : isLate ? Icons.warning_rounded : Icons.schedule_rounded,
                                color: isPaid ? AppleTheme.systemGreen : isLate ? AppleTheme.systemRed : AppleTheme.systemOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(due['month'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  Text(
                                    isPaid ? 'Ödendi' : isLate ? 'Gecikme' : 'Bekliyor',
                                    style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₺${(due['amount'] as double).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isPaid ? AppleTheme.systemGreen : AppleTheme.label,
                                decoration: isPaid ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entry.key < _pendingDues.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 68),
                          child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // Payment Methods
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Ödeme Yöntemi'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                children: _paymentMethods.asMap().entries.map((entry) {
                  final method = entry.value;
                  final isSelected = _selectedPaymentMethod == entry.key;
                  
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _selectedPaymentMethod = entry.key),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (method['color'] as Color).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(method['icon'] as IconData, color: method['color'] as Color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(method['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                              AnimatedContainer(
                                duration: AppleTheme.fastAnimation,
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppleTheme.systemBlue : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppleTheme.systemBlue : AppleTheme.systemGray3,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (entry.key < _paymentMethods.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 72),
                          child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // Payment History Link
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.history_rounded),
                label: const Text('Ödeme Geçmişini Görüntüle'),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showPaymentConfirmation(context),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text('₺${_duesInfo['currentDebt'].toStringAsFixed(2)} Öde'),
          ),
        ),
      ),
    );
  }

  void _showPaymentConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppleTheme.systemGray4,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.credit_card_rounded, size: 48, color: AppleTheme.systemGreen),
                  ),
                  const SizedBox(height: 24),
                  const Text('Ödeme Onayı', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'Toplam ₺${_duesInfo['currentDebt'].toStringAsFixed(2)} ödeme yapılacak',
                    style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showPaymentSuccess(context);
                          },
                          child: const Text('Onayla'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showPaymentSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.systemGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 64, color: AppleTheme.systemGreen),
            ),
            const SizedBox(height: 24),
            const Text('Ödeme Başarılı!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Ödemeniz başarıyla gerçekleştirildi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }
}
