// Devriye yürütme (075, FAZ H.5): görevli turu başlatır, noktaların yanında QR okutur; okutma anındaki
// konum sunucuda noktanın konumuyla karşılaştırılır. Ekran açıkken 30 sn'de bir konum izi gönderilir
// (yalnız açık tur boyunca). Uygulama arka plana düşerse iz durur ve raporda kesinti olarak görünür.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/location.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/data_state.dart';

class PatrolRunScreen extends StatefulWidget {
  const PatrolRunScreen({super.key});

  @override
  State<PatrolRunScreen> createState() => _PatrolRunScreenState();
}

class _PatrolRunScreenState extends State<PatrolRunScreen> with WidgetsBindingObserver {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _routes = [];
  Map<String, Map<String, dynamic>> _points = {};
  Map<String, dynamic>? _patrol;
  final Set<String> _scanned = {};
  Position? _pos;
  Timer? _trackTimer;
  final List<Map<String, dynamic>> _trackBuffer = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackTimer?.cancel();
    _flushTrack();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _flushTrack();
    } else if (state == AppLifecycleState.resumed && _patrol != null) {
      _sample();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routes = await apiClient.getList('/patrol-routes');
      final cps = await apiClient.getList('/patrol-checkpoints');
      final open = await apiClient.getList('/patrols', query: {'status': 'IN_PROGRESS', 'limit': 1});
      final me = await apiClient.getCurrentUserId();
      Map<String, dynamic>? mine;
      for (final p in open.whereType<Map>()) {
        if ('${p['guard_id']}' == me) mine = Map<String, dynamic>.from(p);
      }
      setState(() {
        _routes = routes.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).where((r) => r['is_active'] != false).toList();
        _points = {for (final c in cps.whereType<Map>()) '${c['id']}': Map<String, dynamic>.from(c)};
        _patrol = mine;
        _scanned
          ..clear()
          ..addAll(((mine?['scans'] as List?) ?? []).whereType<Map>().map((s) => '${s['checkpoint_id']}'));
        _loading = false;
      });
      if (mine != null) _startTracking();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = errorText(e);
      });
    }
  }

  List<Map<String, dynamic>> get _routePoints {
    final route = _routes.firstWhere((r) => '${r['id']}' == '${_patrol?['route_id']}', orElse: () => {});
    final list = ((route['checkpoints'] as List?) ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    list.sort((a, b) => toNum(a['order']).compareTo(toNum(b['order'])));
    return list;
  }

  void _startTracking() {
    _trackTimer?.cancel();
    _sample();
    _trackTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sample());
  }

  Future<void> _sample() async {
    try {
      final p = await currentPosition(timeout: const Duration(seconds: 15));
      if (!mounted) return;
      setState(() => _pos = p);
      _trackBuffer.add({
        ...positionBody(p),
        'speed_mps': p.speed,
        'recorded_at': p.timestamp.toUtc().toIso8601String(),
      });
      if (_trackBuffer.length >= 2) await _flushTrack();
    } catch (_) {
      // Konum alınamadıysa iz boşluğu raporda kesinti olarak görünür.
    }
  }

  Future<void> _flushTrack() async {
    if (_patrol == null || _trackBuffer.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_trackBuffer);
    _trackBuffer.clear();
    try {
      await apiClient.post('/patrols/${_patrol!['id']}/track', {'points': batch});
    } catch (_) {}
  }

  Future<void> _start(Map<String, dynamic> route) async {
    try {
      await ensureLocationReady();
    } catch (e) {
      _snack('$e');
      return;
    }
    if (!mounted) return;
    if (!await runAction(context, () => apiClient.post('/patrols', {'route_id': route['id']}), success: 'Tur başladı')) return;
    await _load();
  }

  Future<void> _scan({String? qr, String? checkpointId}) async {
    if (_patrol == null || _busy) return;
    setState(() => _busy = true);
    try {
      Map<String, dynamic> loc = {};
      try {
        loc = positionBody(await currentPosition());
      } catch (e) {
        // Konum alınamazsa sunucu "konum muaf" değilse reddeder; nedeni oradan gösterilir.
        _snack('$e');
      }
      final res = await apiClient.post('/patrols/${_patrol!['id']}/scan', {
        if (qr != null) 'qr': qr,
        if (checkpointId != null) 'checkpoint_id': checkpointId,
        ...loc,
      });
      final scan = Map<String, dynamic>.from((res['scan'] as Map?) ?? {});
      final parts = <String>[
        '${scan['checkpoint_name'] ?? 'Nokta'} okutuldu (${toNum(scan['checkpoints_visited']).toInt()}/${toNum(scan['checkpoints_expected']).toInt()})',
        if (res['distance_m'] != null) 'mesafe ${toNum(res['distance_m']).toInt()} m',
        if (res['warning'] != null) '${res['warning']}',
        if (res['note'] != null) '${res['note']}',
      ];
      _snack(parts.join(' · '));
      await _load();
    } catch (e) {
      _snack(errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openScanner() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const _QrScanPage()));
    if (code != null && code.isNotEmpty) await _scan(qr: code);
  }

  Future<void> _manual() async {
    final pending = _routePoints.where((rp) => !_scanned.contains('${rp['checkpoint_id']}')).toList();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('QR okunmuyorsa noktayı seçin'),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Seçim de konumla doğrulanır; noktanın yanında olmalısınız.', style: TextStyle(fontSize: 12)),
          ),
          for (final rp in pending)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, '${rp['checkpoint_id']}'),
              child: Text('${_points['${rp['checkpoint_id']}']?['name'] ?? rp['name'] ?? 'Nokta'}'),
            ),
        ],
      ),
    );
    if (id != null) await _scan(checkpointId: id);
  }

  Future<void> _issue() async {
    final text = await askText(context, 'Sorun bildir', 'Ne gördünüz?');
    if (text == null || !mounted) return;
    if (await runAction(context, () => apiClient.post('/patrols/${_patrol!['id']}/issues', {'description': text, 'severity': 'MEDIUM'}),
        success: 'Sorun tur kaydına işlendi')) {
      await _load();
    }
  }

  Future<void> _complete() async {
    final note = await askText(context, 'Turu bitir', 'Not (isteğe bağlı)', required: false);
    if (note == null || !mounted) return;
    await _flushTrack();
    if (!mounted) return;
    if (await runAction(context, () => apiClient.post('/patrols/${_patrol!['id']}/complete', {'notes': note}), success: 'Tur kapatıldı')) {
      _trackTimer?.cancel();
      await _load();
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }

  String _distanceTo(Map<String, dynamic>? cp) {
    if (_pos == null || cp == null || cp['latitude'] == null) return '';
    final d = distanceMeters(_pos!.latitude, _pos!.longitude, toNum(cp['latitude']).toDouble(), toNum(cp['longitude']).toDouble());
    return ' · ${d.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devriye yürüt')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : _patrol == null
                  ? _routeList()
                  : _running(),
      bottomNavigationBar: _patrol == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _openScanner,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('QR okut'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(tooltip: 'Listeden seç', onPressed: _busy ? null : _manual, icon: const Icon(Icons.list)),
                  IconButton.outlined(tooltip: 'Sorun bildir', onPressed: _issue, icon: const Icon(Icons.report_problem_outlined)),
                  IconButton.outlined(tooltip: 'Turu bitir', onPressed: _complete, icon: const Icon(Icons.flag_outlined)),
                ]),
              ),
            ),
    );
  }

  Widget _routeList() {
    if (_routes.isEmpty) return const EmptyStateView(message: 'Tanımlı güzergâh yok', icon: Icons.route);
    return ListView(children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Güzergâh seçip turu başlatın. Tur boyunca konumunuz yalnız bu ekran açıkken kaydedilir.'),
      ),
      for (final r in _routes)
        ListTile(
          leading: const Icon(Icons.route),
          title: Text('${r['name']}'),
          subtitle: Text('${((r['checkpoints'] as List?) ?? []).length} nokta · ${toNum(r['expected_duration_minutes']).toInt()} dk'),
          trailing: FilledButton(onPressed: () => _start(r), child: const Text('Başlat')),
        ),
    ]);
  }

  Widget _running() {
    final rps = _routePoints;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(children: [
        ListTile(
          title: Text('${_patrol!['route_name'] ?? 'Tur'}'),
          subtitle: Text('Başlangıç ${formatDateTime(_patrol!['started_at'])} · ${_scanned.length}/${toNum(_patrol!['checkpoints_expected']).toInt()} nokta'
              '${_pos != null ? '\nKonum doğruluğu ${_pos!.accuracy.round()} m${_pos!.isMocked ? ' · SAHTE KONUM' : ''}' : '\nKonum bekleniyor…'}'),
          isThreeLine: true,
        ),
        const Divider(),
        for (final rp in rps)
          Builder(builder: (context) {
            final id = '${rp['checkpoint_id']}';
            final cp = _points[id];
            final done = _scanned.contains(id);
            final exempt = cp?['location_check'] == 'EXEMPT';
            return ListTile(
              leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.green : null),
              title: Text('${cp?['name'] ?? rp['name'] ?? 'Nokta'}${rp['optional'] == true ? ' (isteğe bağlı)' : ''}'),
              subtitle: Text([
                if ((cp?['location'] ?? '').toString().isNotEmpty) '${cp!['location']}',
                if (exempt) 'konum muaf',
                if (!exempt && cp?['latitude'] == null) 'konumu tanımlı değil',
              ].join(' · ') + _distanceTo(cp)),
            );
          }),
      ]),
    );
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nokta QR kodunu okutun')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final v = capture.barcodes.map((b) => b.rawValue ?? '').firstWhere((s) => s.isNotEmpty, orElse: () => '');
          if (v.isEmpty) return;
          _done = true;
          Navigator.of(context).pop(v);
        },
      ),
    );
  }
}
