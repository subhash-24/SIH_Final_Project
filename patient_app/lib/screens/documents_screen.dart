import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

/// Screen 09 — Document OCR & Clinical Review
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _uploadedFilename;
  final List<Map<String, String>> _ocrItems = [];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.uploadedDocumentName != null) {
      _uploadedFilename = state.uploadedDocumentName;
    }
    for (final item in state.documentExtractions) {
      _ocrItems.add(Map<String, String>.from(item.map((k, v) => MapEntry(k, v.toString()))));
    }
  }

  String _mapCategory(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'medicine':
        return 'Prescribed Medicine';
      case 'lab_value':
        return 'Lab Value';
      case 'diagnosis':
        return 'Clinical Diagnosis';
      case 'doctor':
        return 'Consultant Doctor';
      case 'hospital':
        return 'Hospital / Clinic';
      default:
        return 'Clinical Record';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _isUploading = true;
          _uploadedFilename = image.name;
        });

        final bytes = await image.readAsBytes();
        final state = context.read<AppState>();
        final encId = state.encounterId ?? 'mock-enc-01';

        final res = await ApiService.uploadDocument(
          encounterId: encId,
          fileBytes: bytes,
          filename: image.name,
        );

        final ocrText = (res['ocr_text'] as String?) ?? '';
        final extractions = (res['extractions'] as List<dynamic>?) ?? [];
        final List<Map<String, String>> newItems = [];

        for (final e in extractions) {
          final fieldType = e['entity_type']?.toString() ?? 'medicine';
          final val = e['value']?.toString() ?? '';
          if (val.trim().isNotEmpty) {
            newItems.add({
              'category': _mapCategory(fieldType),
              'value': val.trim(),
              'source': 'document_extracted',
              'status': 'Confirmed',
            });
          }
        }

        if (newItems.isEmpty && ocrText.trim().isNotEmpty) {
          newItems.add({
            'category': 'Prescribed Medicine',
            'value': ocrText.trim(),
            'source': 'document_extracted',
            'status': 'Confirmed',
          });
        }

        if (mounted) {
          setState(() {
            _ocrItems.clear();
            _ocrItems.addAll(newItems);
            _uploadedFilename = image.name;
          });

          state.setDocumentExtractions(
            filename: image.name,
            ocrText: ocrText,
            extractions: _ocrItems,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.tr(
                  'Document processed with OCR: ${_ocrItems.length} records extracted.',
                  'दस्तावेज़ ओसीआर द्वारा स्कैन किया गया: ${_ocrItems.length} रिकॉर्ड निकाले गए।',
                ),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _editItem(int index) {
    final state = context.read<AppState>();
    final item = _ocrItems[index];
    final ctrl = TextEditingController(text: item['value']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          '${state.tr('Edit', 'संशोधित करें')} ${item['category']}',
          style: AppTextStyles.headlineSm,
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          autofocus: true,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.tr('Cancel', 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _ocrItems[index]['value'] = ctrl.text.trim();
                  _ocrItems[index]['status'] = 'Confirmed';
                });
                final state = context.read<AppState>();
                state.updateDocumentExtraction(index, ctrl.text.trim(), 'Confirmed');
              }
              Navigator.pop(ctx);
            },
            child: Text(state.tr('Confirm', 'पुष्टि करें')),
          ),
        ],
      ),
    );
  }

  void _proceedToNext() {
    final state = context.read<AppState>();
    if (_uploadedFilename != null) {
      state.setDocumentExtractions(
        filename: _uploadedFilename!,
        ocrText: state.uploadedDocumentOcrText ?? '',
        extractions: _ocrItems,
      );
    }
    context.go('/ayush');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/medical-history'),
        ),
        title: Text(state.tr('Medical Documents & OCR', 'चिकित्सा पर्चे और ओसीआर')),
        actions: [
          TextButton(
            onPressed: () => context.go('/ayush'),
            child: Text(
              state.tr('Skip for now', 'छोड़ें'),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.tr('Previous Prescriptions & Reports', 'पुराने पर्चे और रिपोर्ट'),
                          style: AppTextStyles.headlineLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.tr(
                            'Scan or upload your previous doctor prescriptions or discharge summaries. Our clinical OCR extracts your medicines and lab results automatically.',
                            'अपने पुराने पर्चे या रिपोर्ट स्कैन करें। हमारा ओसीआर सिस्टम आपकी दवाओं और जांच परिणामों को स्वचालित रूप से निकाल लेगा।',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Action Buttons: Scan & Upload
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                                label: Text(
                                  state.tr('Scan Document', 'पर्चा स्कैन करें'),
                                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                ),
                                onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.border, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.upload_file_outlined, size: 20),
                                label: Text(
                                  state.tr('Upload File / PDF', 'फ़ाइल अपलोड करें'),
                                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                ),
                                onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Uploading Loading State
                        if (_isUploading) ...[
                          ClinicalCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            backgroundColor: AppColors.surfaceContainerLow,
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.tr('Processing document with OCR...', 'दस्तावेज़ को ओसीआर द्वारा स्कैन किया जा रहा है...'),
                                        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        state.tr('Extracting medicines, lab values, and clinical findings.', 'दवाओं और परीक्षणों की जानकारी निकाली जा रही है।'),
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        // Document Preview Banner (if uploaded)
                        if (_uploadedFilename != null) ...[
                          ClinicalCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            backgroundColor: AppColors.surfaceContainerLow,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.description, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _uploadedFilename!,
                                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'OCR Status: Analyzed • ${_ocrItems.length} Entities Extracted',
                                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'OCR Synced',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.tr('Extracted Prescriptions & Lab Records', 'निकाली गई दवाएं और जांच रिकॉर्ड'),
                              style: AppTextStyles.headlineSm,
                            ),
                            Text(
                              '${_ocrItems.length} records',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Empty State if no document yet
                        if (_ocrItems.isEmpty && !_isUploading) ...[
                          ClinicalCard(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.document_scanner_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.tr('No document processed yet', 'अभी तक कोई दस्तावेज़ स्कैन नहीं किया गया'),
                                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.tr('Scan or upload your previous prescription above, or skip to continue.', 'ऊपर दिए गए बटन से पर्चा स्कैन करें या आगे बढ़ें।'),
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // OCR Extracted Items Stack
                        if (_ocrItems.isNotEmpty) ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _ocrItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (ctx, i) {
                              final item = _ocrItems[i];
                              final isConfirmed = item['status'] == 'Confirmed';

                              return ClinicalCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                item['category']!,
                                                style: AppTextStyles.labelSmall.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SourceBadge(source: item['source']!),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isConfirmed
                                                      ? AppColors.successBg
                                                      : AppColors.warningBg,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item['status']!,
                                                  style: AppTextStyles.labelSmall.copyWith(
                                                    color: isConfirmed
                                                        ? AppColors.success
                                                        : AppColors.warning,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item['value']!,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                      onPressed: () => _editItem(i),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: state.tr(
                            _ocrItems.isNotEmpty
                                ? 'Confirm Records & Proceed to AYUSH • आगे बढ़ें'
                                : 'Proceed to AYUSH • आगे बढ़ें',
                            'पुष्टि करें और आयुष प्रोफ़ाइल पर जाएं',
                          ),
                          icon: Icons.arrow_forward,
                          onPressed: _proceedToNext,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
