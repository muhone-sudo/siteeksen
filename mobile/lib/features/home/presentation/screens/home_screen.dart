import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ahmet Yılmaz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Güneş Sitesi - A Blok No:3',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Borç Durumu Kartı
            _DebtStatusCard(),
            const SizedBox(height: 16),

            // İlan Panosu
            _SectionHeader(title: 'İlan Panosu', onSeeAll: () {}),
            const SizedBox(height: 8),
            _PinBoardCard(),
            const SizedBox(height: 16),

            // Tüketim Grafiği
            _SectionHeader(title: 'Tüketim', onSeeAll: () {}),
            const SizedBox(height: 8),
            _ConsumptionCard(),
            const SizedBox(height: 16),

            // Kampanyalar
            _SectionHeader(title: 'Kampanyalar', onSeeAll: () {}),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CampaignCard(
                    title: 'Aidat Ödemelerinde',
                    subtitle: '₺100 Puan Hediye',
                    color: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 12),
                  _CampaignCard(
                    title: 'Sigorta Yenileme',
                    subtitle: '%20 İndirim',
                    color: const Color(0xFF0EA5E9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Gerçek veriyle değiştir
    final hasDebt = false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasDebt
              ? [const Color(0xFFEF4444), const Color(0xFFF87171)]
              : [const Color(0xFF22C55E), const Color(0xFF4ADE80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasDebt ? Colors.red : Colors.green).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDebt ? Icons.warning_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDebt ? 'Ödenmemiş Borcunuz Var' : 'Borcunuz Bulunmamaktadır',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasDebt)
                      const Text(
                        '₺1.250,00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (hasDebt) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Hemen Öde'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Tümü'),
          ),
      ],
    );
  }
}

class _PinBoardCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: const Text('Satılık Bisiklet'),
        subtitle: const Text('Az kullanılmış, 26 jant...'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class _ConsumptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son 6 Ay Isınma Tüketimi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _BarItem(value: 0.4, label: 'Ağu'),
                  _BarItem(value: 0.5, label: 'Eyl'),
                  _BarItem(value: 0.6, label: 'Eki'),
                  _BarItem(value: 0.75, label: 'Kas'),
                  _BarItem(value: 0.9, label: 'Ara'),
                  _BarItem(value: 1.0, label: 'Oca', isHighlighted: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final double value;
  final String label;
  final bool isHighlighted;

  const _BarItem({
    required this.value,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 100 * value,
          decoration: BoxDecoration(
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _CampaignCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
