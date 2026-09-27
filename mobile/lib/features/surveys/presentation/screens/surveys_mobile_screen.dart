// Anketler (sakin).
//
// DÜZELTME (2026-09-26): ekran var olmayan alanları okuyordu (`options` listede
// yok, `o.text`, `votes`, `end_date`, `is_active`…) ve ilk anket geldiği anda
// tanımsız `totalResidents` ile bölme yaparak ÇÖKÜYORDU; oy da var olmayan
// `/responses` yoluna gidiyordu. Artık liste `GET /surveys`, seçenekler
// `GET /surveys/:id`, oy `POST /surveys/:id/vote` ile çalışır.
//
// Anket genel kurul kararı DEĞİLDİR (KMK m.29-32); sunucunun hukuki notu gösterilir.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

const surveyStatusLabels = {
  'ACTIVE': 'Devam ediyor',
  'CLOSED': 'Sona erdi',
  'CANCELLED': 'İptal edildi',
  'DRAFT': 'Taslak',
};

/// Katılım metni. Sunucu `participation_rate`'i YÜZDE olarak ("45.50") döner.
String participationText(Object? rate, Object? votes, Object? eligible) {
  final v = toNum(votes).toInt();
  final e = toNum(eligible).toInt();
  final r = toNum(rate).toDouble();
  if (e <= 0) return '$v oy';
  return '$v / $e katılım (%${r.toStringAsFixed(0)})';
}

class SurveysMobileScreen extends StatefulWidget {
  const SurveysMobileScreen({super.key});

  @override
  State<SurveysMobileScreen> createState() => _SurveysMobileScreenState();
}

class _SurveysMobileScreenState extends State<SurveysMobileScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getSurveys();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getSurveys());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anketler')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final items = snap.data!.whereType<Map>().toList();
          if (items.isEmpty) return const EmptyStateView(message: 'Şu an anket yok', icon: Icons.poll_outlined);
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = items[i];
                final status = '${s['status'] ?? ''}';
                final voted = s['has_voted'] == true;
                return ListTile(
                  leading: Icon(voted ? Icons.check_circle : Icons.poll_outlined,
                      color: voted ? Colors.green : null),
                  title: Text('${s['title'] ?? 'Anket'}'),
                  subtitle: Text([
                    surveyStatusLabels[status] ?? status,
                    if (parseApiDate(s['ends_at']) != null) 'Bitiş: ${formatDateTime(s['ends_at'])}',
                    participationText(s['participation_rate'], s['total_votes'], s['eligible_voters']),
                    if (voted) 'Oy kullandınız',
                  ].join(' · ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SurveyDetailScreen(surveyId: '${s['id']}'),
                    ));
                    if (mounted) await _reload();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SurveyDetailScreen extends StatefulWidget {
  final String surveyId;
  const SurveyDetailScreen({super.key, required this.surveyId});

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  String? _selected;
  final _comment = TextEditingController();
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getSurvey(widget.surveyId);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _vote() async {
    if (_selected == null) return;
    setState(() => _voting = true);
    try {
      final res = await apiClient.voteSurvey(widget.surveyId, _selected!, comment: _comment.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? 'Oyunuz kaydedildi'}')));
      setState(() {
        _future = apiClient.getSurvey(widget.surveyId);
        _selected = null;
      });
    } catch (e) {
      if (!mounted) return;
      var msg = toUserMessage(e);
      if (e is DioException && e.response?.data is Map && (e.response!.data as Map)['error'] is String) {
        msg = (e.response!.data as Map)['error'] as String;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anket')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            return ErrorStateView(
              message: toUserMessage(snap.error!),
              onRetry: () => setState(() => _future = apiClient.getSurvey(widget.surveyId)),
            );
          }
          final res = snap.data!;
          final survey = res['survey'] is Map ? Map<String, dynamic>.from(res['survey'] as Map) : <String, dynamic>{};
          final options = ApiClient.listOf(survey['options']).whereType<Map>().toList();
          final resultsVisible = res['results_visible'] == true;
          final canVote = survey['status'] == 'ACTIVE' && survey['has_voted'] != true;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${survey['title'] ?? ''}', style: Theme.of(context).textTheme.titleLarge),
              if ((survey['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${survey['description']}'),
              ],
              const SizedBox(height: 8),
              Text(participationText(survey['participation_rate'], survey['total_votes'], survey['eligible_voters']),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: _selected,
                onChanged: (v) {
                  if (canVote) setState(() => _selected = v);
                },
                child: Column(
                  children: [
                    for (final o in options)
                      Card(
                        child: RadioListTile<String>(
                          value: '${o['id']}',
                          enabled: canVote,
                          title: Text('${o['option_text'] ?? ''}'),
                          subtitle: resultsVisible && o['vote_count'] != null
                              ? Text('${toNum(o['vote_count']).toInt()} oy'
                                  '${o['percentage'] != null ? ' · %${toNum(o['percentage']).toStringAsFixed(0)}' : ''}')
                              : ((o['description'] ?? '').toString().isEmpty ? null : Text('${o['description']}')),
                        ),
                      ),
                  ],
                ),
              ),
              if (!resultsVisible && res['results_note'] is String)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('${res['results_note']}')),
              if (canVote && survey['allow_comments'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(controller: _comment, decoration: const InputDecoration(labelText: 'Yorum (isteğe bağlı)')),
                ),
              if (canVote)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _selected == null || _voting ? null : _vote,
                    child: _voting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Oy Ver'),
                  ),
                )
              else if (survey['has_voted'] == true)
                const Padding(padding: EdgeInsets.only(top: 16), child: Text('Bu ankette oy kullandınız.')),
              if (res['anonymity_note'] is String)
                Padding(padding: const EdgeInsets.only(top: 16), child: Text('${res['anonymity_note']}', style: Theme.of(context).textTheme.bodySmall)),
              if (res['legal_notice'] is String)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('${res['legal_notice']}', style: Theme.of(context).textTheme.bodySmall)),
            ],
          );
        },
      ),
    );
  }
}
