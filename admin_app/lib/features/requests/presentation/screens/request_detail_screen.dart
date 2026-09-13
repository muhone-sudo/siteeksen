// Talep detay ekranı.
//
// NE DEĞİŞTİ VE NEDEN (2026-09-13):
// Ekranın tamamı sabit metinlerden oluşuyordu: "Asansör Arızası", açıklama,
// "Ahmet Yılmaz - A Blok D.5", "01.02.2026 14:30", "Yüksek" öncelik ve iki uydurma
// yorum ("Yönetici", "Ahmet Yılmaz"). Ayrıca yorum gönder düğmesi HİÇBİR ağ
// çağrısı yapmadan "Yorum eklendi" diyordu — kullanıcıya doğrudan yalan.
//
// Artık:
//  * Talep verisi sunucudan gelir. Önce `GET /requests/{id}` denenir; community
//    servisinde bu uç henüz TANIMLI DEĞİL (yalnızca liste ucu var), bu yüzden
//    çağrı başarısız olursa `GET /requests` listesinden aynı kayıt bulunur.
//    Bu bir "yedek uydurma veri" değildir — her iki durumda da veri sunucudan gelir.
//  * Durum güncelleme `PATCH /requests/{id}/status` ucuna gider; başarı mesajı
//    yalnızca sunucu 2xx döndüğünde gösterilir.
//  * Yorum gönderimi gerçek `POST /requests/{id}/comments` çağrısıdır; sunucu
//    hata dönerse kullanıcıya hata gösterilir, sahte başarı verilmez.
//  * Yorum LİSTESİ için sunucuda bir uç yok → uydurma yorumlar yerine
//    `NotImplementedNotice` gösterilir.
//
// Not: Sunucu talep sahibinin adını döndürmüyor (yalnızca `resident_id`), bu
// nedenle isim uydurmak yerine sakin kimliği gösterilir.
//
// Ayrıca başlıktaki "Görevli Ata / Öncelik Değiştir" menüsü kaldırıldı: menünün
// `onSelected` işleyicisi yoktu, yani seçim yapıldığında sessizce hiçbir şey
// olmuyordu. Yerine veriyi yeniden yükleyen gerçek bir yenile düğmesi kondu.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _loading = true;
  Object? _error;
  Map<String, dynamic>? _request;

  String _status = 'OPEN';
  bool _isSubmitting = false;
  bool _isSendingComment = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    Map<String, dynamic>? request;
    Object? error;
    try {
      final data = await apiClient.getRequest(widget.requestId);
      // Sunucu yanıtı {data: {...}} sarmalayıcısıyla gelebiliyor.
      final inner = data['data'];
      request = inner is Map ? Map<String, dynamic>.from(inner) : data;
    } catch (e) {
      error = e;
      // Detay ucu sunucuda yoksa (404/501) aynı kaydı liste ucundan bulmayı dene.
      try {
        final list = await apiClient.getRequests();
        final match = list.whereType<Map>().cast<Map>().firstWhere(
              (r) => '${r['id']}' == widget.requestId,
              orElse: () => const {},
            );
        if (match.isNotEmpty) {
          request = Map<String, dynamic>.from(match);
          error = null;
        }
      } catch (_) {
        // İlk hatayı koru: kullanıcıya gösterilecek olan asıl neden odur.
      }
    }

    if (!mounted) return;
    setState(() {
      _request = request;
      _error = request == null ? error : null;
      _status = (request?['status'] ?? 'OPEN').toString();
      _loading = false;
    });
  }

  Future<void> _updateStatus() async {
    setState(() => _isSubmitting = true);
    try {
      await apiClient.updateRequestStatus(widget.requestId, _status);
      if (!mounted) return;
      // Başarı mesajı yalnızca sunucu isteği kabul ettiyse gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Talep güncellendi'), backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Talep güncellenemedi: ${toUserMessage(e)}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      await apiClient.addRequestComment(widget.requestId, text);
      if (!mounted) return;
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Yorum eklendi'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum eklenemedi: ${toUserMessage(e)}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talep Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _request == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _updateStatus,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Güncelle'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Talep alınıyor...');
    }
    if (_request == null) {
      final error = _error;
      if (error != null && isNotImplemented(error)) {
        return const NotImplementedNotice(
          title: 'Talep detayı henüz hazır değil',
          detail: 'Sunucu bu kaydı henüz üretmiyor (501).',
        );
      }
      return ErrorStateView(
        message: error == null
            ? 'Talep bulunamadı.'
            : toUserMessage(error),
        onRetry: _load,
      );
    }

    final request = _request!;
    final title = (request['title'] ?? '').toString();
    final description = (request['description'] ?? '').toString();
    final ticket = (request['ticket_number'] ?? '').toString();
    final residentId = (request['resident_id'] ?? '').toString();
    final location = (request['location'] ?? '').toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Başlık kartı
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _statusColor(_status),
                      child: Icon(
                        _priorityIcon((request['priority'] ?? '').toString()),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? '(başlıksız talep)' : title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ticket.isEmpty
                                ? 'Talep #${widget.requestId}'
                                : 'Talep $ticket',
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description.isEmpty ? 'Açıklama girilmemiş.' : description,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bilgi kartı — tüm değerler sunucudan gelir.
        Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.person,
                label: 'Talep Eden (sakin no)',
                value: residentId.isEmpty ? '—' : residentId,
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.calendar_today,
                label: 'Tarih',
                value: formatDateTime(request['created_at']),
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.place,
                label: 'Konum',
                value: location.isEmpty ? '—' : location,
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.flag,
                label: 'Öncelik',
                value: _priorityText((request['priority'] ?? '').toString()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Durum güncelleme
        const Text('Durum Güncelle',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'OPEN', label: Text('Açık')),
            ButtonSegment(value: 'IN_PROGRESS', label: Text('İşlemde')),
            ButtonSegment(value: 'RESOLVED', label: Text('Çözüldü')),
          ],
          selected: {_segmentValue(_status)},
          onSelectionChanged: (v) => setState(() => _status = v.first),
        ),
        if (_status == 'RESOLVED') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_top, color: AppTheme.warningColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Talep "Çözüldü" olarak işaretlendi. Talep, sakin '
                    'onayladıktan sonra otomatik olarak kapatılacaktır.',
                    style: TextStyle(color: AppTheme.warningColor),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Yorumlar — listeleme ucu sunucuda yok, uydurma yorum GÖSTERİLMEZ.
        const Text('Yorumlar', style: TextStyle(fontWeight: FontWeight.w600)),
        const NotImplementedNotice(
          title: 'Yorum geçmişi henüz görüntülenemiyor',
          detail: 'Sunucuda yorumları listeleyen bir uç bulunmuyor. '
              'Aşağıdan gönderdiğiniz yorum sunucuya iletilir.',
        ),
        const SizedBox(height: 8),

        // Yorum ekleme — gerçek ağ çağrısı yapar.
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                enabled: !_isSendingComment,
                decoration: const InputDecoration(hintText: 'Yorum ekle...'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSendingComment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: _isSendingComment ? null : _sendComment,
            ),
          ],
        ),
      ],
    );
  }

  /// SegmentedButton yalnızca tanımlı üç değeri kabul eder; sunucu bunların
  /// dışında bir durum döndürürse (örn. CLOSED) seçim çökmesin diye eşlenir.
  String _segmentValue(String status) {
    const allowed = {'OPEN', 'IN_PROGRESS', 'RESOLVED'};
    return allowed.contains(status) ? status : 'OPEN';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return AppTheme.primaryColor;
      case 'RESOLVED':
        return AppTheme.successColor;
      case 'OPEN':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _priorityText(String priority) {
    switch (priority) {
      case 'URGENT':
        return 'Acil';
      case 'HIGH':
        return 'Yüksek';
      case 'NORMAL':
        return 'Normal';
      case 'LOW':
        return 'Düşük';
      default:
        return priority.isEmpty ? '—' : priority;
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'URGENT':
      case 'HIGH':
        return Icons.priority_high;
      case 'LOW':
        return Icons.low_priority;
      default:
        return Icons.support_agent;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle:
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
