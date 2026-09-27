import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/api_views.dart';
import '../widgets/activation_code_dialog.dart';

const Map<String, String> _roleLabels = {
  'OWNER': 'Ev Sahibi',
  'TENANT': 'Kiracı',
  'PROXY': 'Vekil',
};

class ResidentDetailScreen extends StatefulWidget {
  final String residentId;

  const ResidentDetailScreen({super.key, required this.residentId});

  @override
  State<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends State<ResidentDetailScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;
  Map<String, dynamic>? _resident;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await apiClient.getResident(widget.residentId);
      if (!mounted) return;
      setState(() {
        _resident = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sakin bilgileri yüklenemedi: ${errorText(e)}')),
      );
    }
  }

  /// Yeni etkinleştirme / şifre sıfırlama kodu (yalnız M/B; eski kod geçersizleşir).
  Future<void> _issueCode() async {
    setState(() => _isUpdating = true);
    try {
      final act = await apiClient.issueActivationCode(widget.residentId);
      if (!mounted) return;
      final name = '${_resident?['first_name'] ?? ''} ${_resident?['last_name'] ?? ''}'.trim();
      await showActivationCodeDialog(context, who: name, activation: act);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kod üretilemedi: ${errorText(e)}')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _setActive(bool active) async {
    setState(() => _isUpdating = true);
    try {
      await apiClient.updateResident(widget.residentId, {'is_active': active});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(active ? 'Sakin aktifleştirildi' : 'Sakin pasifleştirildi')),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem gerçekleştirilemedi, lütfen tekrar deneyin')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resident = _resident;
    final name = resident == null ? '' : '${resident['first_name'] ?? ''} ${resident['last_name'] ?? ''}'.trim();
    final initials = name.isNotEmpty
        ? name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join()
        : '?';
    final isActive = resident?['is_active'] == true;
    final role = _roleLabels[resident?['role']] ?? resident?['role']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sakin Detayı'),
        actions: [
          if (resident != null)
            PopupMenuButton<String>(
              enabled: !_isUpdating,
              onSelected: (value) {
                if (value == 'toggle') _setActive(!isActive);
                if (value == 'code') _issueCode();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'code', child: Text('Etkinleştirme / şifre sıfırlama kodu üret')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    isActive ? 'Pasifleştir' : 'Aktifleştir',
                    style: TextStyle(color: isActive ? Colors.red : AppTheme.successColor),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : resident == null
              ? const Center(child: Text('Sakin bulunamadı'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(initials, style: const TextStyle(fontSize: 24, color: Colors.white)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text('${resident['unit'] ?? ''} • $role', style: const TextStyle(color: AppTheme.textSecondary)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isActive ? AppTheme.successColor : AppTheme.textSecondary).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isActive ? 'Aktif' : 'Pasif',
                                        style: TextStyle(color: isActive ? AppTheme.successColor : AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Info
                      Card(
                        child: Column(
                          children: [
                            _InfoTile(icon: Icons.phone, label: 'Telefon', value: (resident['phone'] ?? '').toString()),
                            const Divider(height: 1),
                            _InfoTile(icon: Icons.email, label: 'E-posta', value: (resident['email'] as String?)?.isNotEmpty == true ? resident['email'] : '—'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
