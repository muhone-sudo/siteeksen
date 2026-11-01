// İşletmelerim (FAZ M3, K16/K17): birden çok işletme/şube; adres, haritadan konum, hizmet alanı, kategoriler,
// hizmet/ürün kalemleri. Harita karoları geliştirmede OpenStreetMap'ten (yayında karo sağlayıcısı: M0.6).

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/data_state.dart';
import '../../core/widgets/future_list.dart';

const businessStatus = {'DRAFT': 'Taslak', 'REVIEW': 'İncelemede', 'PUBLISHED': 'Yayında', 'REJECTED': 'Reddedildi', 'CLOSED': 'Kapalı'};
const _photoStatus = {'PENDING': 'denetimde', 'REVIEW': 'incelemede', 'APPROVED': 'yayında', 'REJECTED': 'reddedildi'};
const serviceAreas = {'KM': 'Yarıçap (km)', 'CITY': 'Tüm il', 'COUNTRY': 'Türkiye geneli'};

class BusinessesScreen extends StatelessWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<FutureListState>();
    return Scaffold(
      appBar: AppBar(title: const Text('İşletmelerim')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/isletmeler/yeni');
          key.currentState?.reload();
        },
        icon: const Icon(Icons.add_business),
        label: const Text('İşletme ekle'),
      ),
      body: FutureList(
        key: key,
        load: apiClient.businesses,
        empty: 'Henüz işletme yok. Dükkânınızı ya da şubenizi ekleyin; onaydan sonra sakinler sizi görür.',
        itemBuilder: (context, b, reload) => Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ListTile(
            title: Text('${b['name']}'),
            subtitle: Text('${businessStatus['${b['status']}']} · ${b['district']} / ${b['city']} · ${serviceAreas['${b['service_area']}']}'
                '${b['radius_km'] != null ? ' ${b['radius_km']} km' : ''}${b['review_note'] != null ? '\nNot: ${b['review_note']}' : ''}'),
            onTap: () async {
              await context.push('/isletmeler/${b['id']}');
              reload();
            },
          ),
        ),
      ),
    );
  }
}

class BusinessScreen extends StatefulWidget {
  final String id;
  const BusinessScreen({super.key, required this.id});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  final _name = TextEditingController(), _desc = TextEditingController(), _phone = TextEditingController();
  final _address = TextEditingController(), _city = TextEditingController(), _district = TextEditingController(), _radius = TextEditingController(text: '10');
  String _area = 'KM';
  LatLng _pin = const LatLng(41.0082, 28.9784);
  bool _pinSet = false, _busy = false;
  Set<String> _cats = {};
  Map<String, dynamic>? _b;
  late Future<Map<String, dynamic>> _meta;
  String? get _id => widget.id == 'yeni' ? (_b?['id'] as String?) : widget.id;

  @override
  void initState() {
    super.initState();
    _meta = apiClient.meta();
    if (widget.id != 'yeni') _loadBusiness(widget.id);
  }

  Future<void> _loadBusiness(String id) async {
    try {
      final b = await apiClient.business(id);
      setState(() {
        _b = b;
        _name.text = '${b['name']}';
        _desc.text = '${b['description'] ?? ''}';
        _phone.text = '${b['phone'] ?? ''}';
        _address.text = '${b['address']}';
        _city.text = '${b['city']}';
        _district.text = '${b['district']}';
        _area = '${b['service_area']}';
        _radius.text = '${b['radius_km'] ?? 10}';
        _pin = LatLng(toNum(b['latitude']).toDouble(), toNum(b['longitude']).toDouble());
        _pinSet = true;
        _cats = ((b['category_ids'] as List?) ?? const []).map((e) => '$e').toSet();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await runSnack(context, () async {
      final b = await apiClient.saveBusiness(_id, {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'district': _district.text.trim(),
        'latitude': _pin.latitude,
        'longitude': _pin.longitude,
        'service_area': _area,
        'radius_km': _area == 'KM' ? int.tryParse(_radius.text) : null,
        'category_ids': _cats.toList(),
      });
      _b = b;
    }, 'İşletme kaydedildi');
    if (mounted) setState(() => _busy = false);
    if (ok && _id != null) await _loadBusiness(_id!);
  }

  @override
  Widget build(BuildContext context) {
    final status = '${_b?['status'] ?? 'DRAFT'}';
    final editable = status != 'CLOSED';
    return Scaffold(
      appBar: AppBar(title: Text(_b == null ? 'Yeni işletme' : '${_b!['name']}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _meta,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!));
          final cats = (snap.data!['categories'] as List? ?? const []).whereType<Map>().toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            children: [
              if (_b != null) Text('Durum: ${businessStatus[status]}${_b!['review_note'] != null ? ' — ${_b!['review_note']}' : ''}'),
              TextField(controller: _name, enabled: editable, decoration: const InputDecoration(labelText: 'İşletme adı')),
              TextField(controller: _desc, enabled: editable, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Tanıtım')),
              TextField(controller: _phone, enabled: editable, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'İşletme telefonu')),
              TextField(controller: _address, enabled: editable, decoration: const InputDecoration(labelText: 'Adres')),
              Row(children: [
                Expanded(child: TextField(controller: _city, enabled: editable, decoration: const InputDecoration(labelText: 'İl'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _district, enabled: editable, decoration: const InputDecoration(labelText: 'İlçe'))),
              ]),
              const SizedBox(height: 12),
              Text(_pinSet ? 'Konum: ${_pin.latitude.toStringAsFixed(5)}, ${_pin.longitude.toStringAsFixed(5)}' : 'Haritada işletmenin yerine dokunun'),
              SizedBox(
                height: 240,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _pin,
                    initialZoom: _pinSet ? 14 : 10,
                    onTap: editable ? (_, p) => setState(() { _pin = p; _pinSet = true; }) : null,
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.siteeksen.supplier'),
                    if (_pinSet) MarkerLayer(markers: [Marker(point: _pin, child: const Icon(Icons.location_pin, color: Colors.red, size: 36))]),
                  ],
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _area,
                decoration: const InputDecoration(labelText: 'Hizmet alanı'),
                items: [for (final e in serviceAreas.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: editable ? (v) => setState(() => _area = v ?? 'KM') : null,
              ),
              if (_area == 'KM') TextField(controller: _radius, enabled: editable, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yarıçap (km)')),
              const SizedBox(height: 12),
              const Text('Kategoriler'),
              Wrap(spacing: 8, children: [
                for (final c in cats)
                  FilterChip(
                    label: Text('${c['name']}'),
                    selected: _cats.contains('${c['id']}'),
                    onSelected: editable ? (v) => setState(() => v ? _cats.add('${c['id']}') : _cats.remove('${c['id']}')) : null,
                  ),
              ]),
              const SizedBox(height: 12),
              if (editable) FilledButton(onPressed: _busy || !_pinSet ? null : _save, child: const Text('Kaydet')),
              if (_id != null && (status == 'DRAFT' || status == 'REJECTED'))
                OutlinedButton(
                  onPressed: () async {
                    if (await runSnack(context, () => apiClient.businessAction(_id!, 'submit'), 'İşletme incelemeye gönderildi')) await _loadBusiness(_id!);
                  },
                  child: const Text('Yayına almak için incelemeye gönder'),
                ),
              if (_id != null) _Services(businessId: _id!, editable: editable),
            ],
          );
        },
      ),
    );
  }
}

class _Services extends StatefulWidget {
  final String businessId;
  final bool editable;
  const _Services({required this.businessId, required this.editable});

  @override
  State<_Services> createState() => _ServicesState();
}

class _ServicesState extends State<_Services> {
  late Future<List<dynamic>> _future = apiClient.services(widget.businessId);

  String _price(Map s) => s['price_min_kurus'] == null
      ? 'Teklifle'
      : '${formatTry(toNum(s['price_min_kurus']) / 100)} – ${formatTry(toNum(s['price_max_kurus']) / 100)}${'${s['unit'] ?? ''}'.isEmpty ? '' : ' / ${s['unit']}'}';

  Future<void> _edit([Map? s]) async {
    final name = TextEditingController(text: '${s?['name'] ?? ''}'), desc = TextEditingController(text: '${s?['description'] ?? ''}');
    final min = TextEditingController(text: s?['price_min_kurus'] == null ? '' : (toNum(s!['price_min_kurus']) / 100).toStringAsFixed(0));
    final max = TextEditingController(text: s?['price_max_kurus'] == null ? '' : (toNum(s!['price_max_kurus']) / 100).toStringAsFixed(0));
    final unit = TextEditingController(text: '${s?['unit'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s == null ? 'Hizmet/ürün ekle' : 'Kalemi düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad')),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Açıklama')),
            TextField(controller: min, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'En düşük fiyat (TL, boşsa teklifle)')),
            TextField(controller: max, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'En yüksek fiyat (TL)')),
            TextField(controller: unit, decoration: const InputDecoration(labelText: 'Birim (adet, m², saat…)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    int? k(TextEditingController c) => c.text.trim().isEmpty ? null : ((double.tryParse(c.text.replaceAll(',', '.')) ?? 0) * 100).round();
    if (await runSnack(context, () => apiClient.saveService(widget.businessId, s?['id'] as String?, {
          'name': name.text.trim(),
          'description': desc.text.trim(),
          'price_min_kurus': k(min),
          'price_max_kurus': k(max),
          'unit': unit.text.trim(),
        }), 'Kaydedildi')) {
      setState(() { _future = apiClient.services(widget.businessId); });
    }
  }

  Future<void> _photo(Map s) async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'], withData: true);
    final f = picked?.files.single;
    if (f == null || f.bytes == null || !mounted) return;
    if (await runSnack(context, () => apiClient.uploadServicePhoto('${s['id']}', f.bytes!, f.name),
        'Fotoğraf yüklendi; platform denetiminden geçince vitrinde görünür')) {
      setState(() { _future = apiClient.services(widget.businessId); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(16), child: LoadingView());
        if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!));
        final items = snap.data!.whereType<Map>().toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 16),
          Text('Hizmetler ve ürünler', style: Theme.of(context).textTheme.titleMedium),
          if (items.isEmpty) const Text('Henüz kalem yok.'),
          for (final s in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${s['name']}'),
              subtitle: Text('${_price(s)}${s['has_photo'] == true ? ' · fotoğraf: ${_photoStatus['${s['photo_status']}'] ?? 'yüklendi'}' : ''}'
                  '${s['photo_status'] == 'REJECTED' && s['photo_reason'] != null ? '\n${s['photo_reason']}' : ''}'),
              trailing: widget.editable
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(tooltip: 'Fotoğraf', onPressed: () => _photo(s), icon: const Icon(Icons.add_a_photo_outlined)),
                      IconButton(tooltip: 'Düzenle', onPressed: () => _edit(s), icon: const Icon(Icons.edit_outlined)),
                    ])
                  : null,
            ),
          if (widget.editable) OutlinedButton.icon(onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Hizmet/ürün ekle')),
        ]);
      },
    );
  }
}
