import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period selector
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Dönem: Ocak 2026'),
              trailing: const Icon(Icons.keyboard_arrow_down),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),

          // Financial Reports
          const Text('Finansal Raporlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.receipt_long,
            title: 'Aidat Raporu',
            description: 'Aylık tahakkuk ve tahsilat detayları',
            formats: ['PDF', 'Excel'],
            onTap: () => _showFormatDialog(context, 'Aidat Raporu'),
          ),
          _ReportCard(
            icon: Icons.payments,
            title: 'Tahsilat Raporu',
            description: 'Ödeme listesi ve yöntem dağılımı',
            formats: ['PDF', 'Excel'],
            onTap: () => _showFormatDialog(context, 'Tahsilat Raporu'),
          ),
          _ReportCard(
            icon: Icons.trending_down,
            title: 'Borç Raporu',
            description: 'Gecikmiş ödemeler ve borçlu listesi',
            formats: ['PDF', 'Excel'],
            onTap: () => _showFormatDialog(context, 'Borç Raporu'),
          ),
          const SizedBox(height: 24),

          // Consumption Reports
          const Text('Tüketim Raporları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.whatshot,
            title: 'Isı Tüketimi',
            description: 'Daire bazlı ısı tüketim raporu',
            formats: ['PDF', 'Excel'],
            onTap: () => _showFormatDialog(context, 'Isı Tüketimi'),
          ),
          _ReportCard(
            icon: Icons.water_drop,
            title: 'Su Tüketimi',
            description: 'Soğuk ve sıcak su tüketim detayları',
            formats: ['PDF', 'Excel'],
            onTap: () => _showFormatDialog(context, 'Su Tüketimi'),
          ),
          const SizedBox(height: 24),

          // Other Reports
          const Text('Diğer Raporlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.people,
            title: 'Sakin Listesi',
            description: 'Tüm sakin ve iletişim bilgileri',
            formats: ['PDF', 'Excel'],
            onTap: () => _showFormatDialog(context, 'Sakin Listesi'),
          ),
          _ReportCard(
            icon: Icons.support_agent,
            title: 'Talep Raporu',
            description: 'Talep istatistikleri ve çözüm süreleri',
            formats: ['PDF'],
            onTap: () => _showFormatDialog(context, 'Talep Raporu'),
          ),
        ],
      ),
    );
  }

  void _showFormatDialog(BuildContext context, String reportName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reportName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF olarak indir'),
              onTap: () {
                Navigator.pop(context);
                _downloadReport(context, 'PDF');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel olarak indir'),
              onTap: () {
                Navigator.pop(context);
                _downloadReport(context, 'Excel');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _downloadReport(BuildContext context, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('$format raporu hazırlanıyor...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rapor indirildi'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Aç',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> formats;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.formats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: formats.map((f) => Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: f == 'PDF' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(fontSize: 10, color: f == 'PDF' ? Colors.red : Colors.green),
                  ),
                )).toList(),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.download, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
