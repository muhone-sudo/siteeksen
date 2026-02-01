import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _nonInvoicedReasonController = TextEditingController();
  
  String? _selectedCategory;
  DateTime _expenseDate = DateTime.now();
  bool _isInvoiced = true;
  bool _reflectsToAssessment = true;
  String _distributionType = 'EQUAL';
  
  List<PlatformFile> _uploadedFiles = [];
  Map<String, dynamic>? _aiScanResult;
  bool _isScanning = false;

  final _categories = [
    {'id': '1', 'name': 'Bina Temizliği', 'type': 'FIXED', 'reflects': false},
    {'id': '2', 'name': 'Güvenlik', 'type': 'FIXED', 'reflects': false},
    {'id': '3', 'name': 'Yönetici Ücreti', 'type': 'FIXED', 'reflects': false},
    {'id': '4', 'name': 'Ortak Elektrik', 'type': 'VARIABLE', 'reflects': true},
    {'id': '5', 'name': 'Ortak Su', 'type': 'VARIABLE', 'reflects': true},
    {'id': '6', 'name': 'Ortak Isınma', 'type': 'VARIABLE', 'reflects': true},
    {'id': '7', 'name': 'Asansör Bakımı', 'type': 'UNPLANNED', 'reflects': true},
    {'id': '8', 'name': 'Bahçe Bakımı', 'type': 'VARIABLE', 'reflects': true},
    {'id': '9', 'name': 'Acil Tamir', 'type': 'UNPLANNED', 'reflects': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider Ekle'),
        actions: [
          TextButton.icon(
            onPressed: _saveExpense,
            icon: const Icon(Icons.save),
            label: const Text('Kaydet'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Invoice Upload Section
            _buildInvoiceUploadSection(),
            const SizedBox(height: 24),
            
            // AI Scan Result
            if (_aiScanResult != null) _buildAiResultCard(),
            
            // Basic Info
            const Text('Gider Bilgileri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategori *'),
              items: _categories.map((c) => DropdownMenuItem(
                value: c['id'] as String,
                child: Row(
                  children: [
                    _getCategoryBadge(c['type'] as String),
                    const SizedBox(width: 8),
                    Text(c['name'] as String),
                  ],
                ),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedCategory = v;
                  // Auto-set reflects based on category
                  final cat = _categories.firstWhere((c) => c['id'] == v);
                  _reflectsToAssessment = cat['reflects'] as bool;
                });
              },
              validator: (v) => v == null ? 'Kategori seçin' : null,
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Açıklama *'),
              maxLines: 2,
              validator: (v) => v?.isEmpty ?? true ? 'Açıklama girin' : null,
            ),
            const SizedBox(height: 16),
            
            // Amount & Date
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Tutar (₺) *', prefixText: '₺ '),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Tutar girin' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Tarih *', suffixIcon: Icon(Icons.calendar_today)),
                    controller: TextEditingController(text: '${_expenseDate.day}.${_expenseDate.month}.${_expenseDate.year}'),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _expenseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _expenseDate = date);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Invoice Status
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Faturalı Gider'),
                    subtitle: Text(_isInvoiced ? 'Bu gider için fatura mevcut' : 'Faturasız gider (açıklama gerekli)'),
                    value: _isInvoiced,
                    onChanged: (v) => setState(() => _isInvoiced = v),
                  ),
                  if (!_isInvoiced) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 20),
                              const SizedBox(width: 8),
                              const Text('Faturasız Gider Uyarısı', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.warningColor)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Faturasız giderler site sakinlerine "Faturasız" olarak gösterilecek ve onay gerektirebilir.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nonInvoicedReasonController,
                            decoration: const InputDecoration(labelText: 'Faturasız olma nedeni *'),
                            maxLines: 2,
                            validator: (v) => !_isInvoiced && (v?.isEmpty ?? true) ? 'Neden belirtin' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Assessment reflection
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Aidata Yansısın'),
                    subtitle: Text(_reflectsToAssessment ? 'Bu gider aylık aidata eklenecek' : 'Sabit gider - aidata eklenmez'),
                    value: _reflectsToAssessment,
                    onChanged: (v) => setState(() => _reflectsToAssessment = v),
                  ),
                  if (_reflectsToAssessment) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dağıtım Şekli'),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'EQUAL', label: Text('Eşit')),
                              ButtonSegment(value: 'AREA', label: Text('m² Bazlı')),
                              ButtonSegment(value: 'PERSON', label: Text('Kişi Sayısı')),
                            ],
                            selected: {_distributionType},
                            onSelectionChanged: (v) => setState(() => _distributionType = v.first),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Vendor info (if invoiced)
            if (_isInvoiced) ...[
              const Text('Firma Bilgileri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(labelText: 'Firma Adı'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(labelText: 'Fatura No'),
              ),
            ],
            
            const SizedBox(height: 100), // FAB space
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('Fatura Yükle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_isScanning)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'PDF, JPG, PNG formatında fatura yükleyebilirsiniz. AI otomatik olarak fatura bilgilerini okuyacak.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            
            // Upload button
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Dosya Seç'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            // Uploaded files
            if (_uploadedFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._uploadedFiles.map((file) => ListTile(
                leading: Icon(_getFileIcon(file.extension ?? ''), color: AppTheme.primaryColor),
                title: Text(file.name, overflow: TextOverflow.ellipsis),
                subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor),
                      tooltip: 'AI ile Tara',
                      onPressed: () => _scanWithAI(file),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () => setState(() => _uploadedFiles.remove(file)),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiResultCard() {
    return Card(
      color: AppTheme.successColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.successColor),
                const SizedBox(width: 8),
                const Text('AI Tarama Sonucu', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                const Spacer(),
                Text('${((_aiScanResult!['confidence'] as double) * 100).toInt()}% güven', 
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
            const Divider(),
            _AiResultRow(label: 'Firma', value: _aiScanResult!['vendor_name'] ?? '-'),
            _AiResultRow(label: 'Fatura No', value: _aiScanResult!['invoice_number'] ?? '-'),
            _AiResultRow(label: 'Tarih', value: _aiScanResult!['invoice_date'] ?? '-'),
            _AiResultRow(label: 'Tutar', value: '₺${_aiScanResult!['total_amount']}'),
            _AiResultRow(label: 'Kategori Önerisi', value: _aiScanResult!['category_suggestion'] ?? '-'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyAiResult,
                icon: const Icon(Icons.check),
                label: const Text('Bilgileri Uygula'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryBadge(String type) {
    Color color;
    String label;
    switch (type) {
      case 'FIXED':
        color = Colors.grey;
        label = 'Sabit';
        break;
      case 'VARIABLE':
        color = AppTheme.primaryColor;
        label = 'Değişken';
        break;
      case 'UNPLANNED':
        color = AppTheme.warningColor;
        label = 'Plansız';
        break;
      default:
        color = Colors.grey;
        label = '';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
      allowMultiple: true,
    );
    
    if (result != null) {
      setState(() {
        _uploadedFiles.addAll(result.files);
      });
      
      // Auto-scan first file
      if (result.files.isNotEmpty) {
        _scanWithAI(result.files.first);
      }
    }
  }

  Future<void> _scanWithAI(PlatformFile file) async {
    setState(() => _isScanning = true);
    
    // Simulate AI scan delay
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isScanning = false;
      _aiScanResult = {
        'vendor_name': 'AYEDAŞ Elektrik Dağıtım A.Ş.',
        'invoice_number': '2026-001234',
        'invoice_date': '28.01.2026',
        'total_amount': 2450.75,
        'tax_amount': 441.14,
        'category_suggestion': 'Ortak Elektrik',
        'confidence': 0.94,
      };
    });
  }

  void _applyAiResult() {
    if (_aiScanResult == null) return;
    
    setState(() {
      _vendorController.text = _aiScanResult!['vendor_name'] ?? '';
      _invoiceNumberController.text = _aiScanResult!['invoice_number'] ?? '';
      _amountController.text = _aiScanResult!['total_amount'].toString();
      
      // Find and select category
      final suggestion = _aiScanResult!['category_suggestion'];
      final cat = _categories.firstWhere(
        (c) => c['name'] == suggestion,
        orElse: () => _categories.last,
      );
      _selectedCategory = cat['id'] as String;
      _reflectsToAssessment = cat['reflects'] as bool;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI sonuçları uygulandı'), backgroundColor: AppTheme.successColor),
    );
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      // TODO: API call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isInvoiced ? 'Gider eklendi' : 'Gider onaya gönderildi'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    }
  }
}

class _AiResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _AiResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
