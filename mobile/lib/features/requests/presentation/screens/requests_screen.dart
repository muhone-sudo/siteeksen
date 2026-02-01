import 'package:flutter/material.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Taleplerim'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Güncel'),
              Tab(text: 'Tamamlanmış'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestList(isActive: true),
            _RequestList(isActive: false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showNewRequestSheet(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Yeni Talep'),
        ),
      ),
    );
  }

  void _showNewRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Yeni Talep Oluştur',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              const Text('Kategori Seçin'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CategoryChip(icon: Icons.elevator, label: 'Asansör'),
                  _CategoryChip(icon: Icons.cleaning_services, label: 'Temizlik'),
                  _CategoryChip(icon: Icons.security, label: 'Güvenlik'),
                  _CategoryChip(icon: Icons.park, label: 'Bahçe'),
                  _CategoryChip(icon: Icons.more_horiz, label: 'Diğer'),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Sorunu kısaca açıklayın',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Detaylı bilgi verin...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotoğraf Ekle'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final bool isActive;

  const _RequestList({required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      // Tamamlanmış talepler örnek
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _RequestItem(
            ticketNo: 'TLP-2025-0089',
            title: 'Merdiven temizlik sorunu',
            category: 'Temizlik',
            status: 'RESOLVED',
            date: '15 Ara 2025',
          ),
        ],
      );
    }

    // Aktif talep yok durumu
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aktif talebiniz bulunmamaktadır',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yönetiminiz ile iletişime geçmek için\nyeni talep oluşturabilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  final String ticketNo;
  final String title;
  final String category;
  final String status;
  final String date;

  const _RequestItem({
    required this.ticketNo,
    required this.title,
    required this.category,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('$category • $date'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
        onTap: () {},
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {},
    );
  }
}
