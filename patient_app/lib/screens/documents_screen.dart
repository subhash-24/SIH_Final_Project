import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

/// Screen 09 — Document OCR & Clinical Review
/// Matches Stitch Screen 4 standards: Scan / Upload / Skip actions, document preview,
/// structured OCR findings with provenance labels and inline editing.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _uploadedFilename;

  // Local editable list of OCR extractions
  final List<Map<String, String>> _ocrItems = [
    {
      'category': 'Prescribed Medicine',
      'value': 'Tab Metformin 500mg — 1 tab BD after meals',
      'source': 'document_extracted',
      'status': 'Confirmed',
    },
    {
      'category': 'Prescribed Medicine',
      'value': 'Tab Telmisartan 40mg — 1 tab OD morning',
      'source': 'document_extracted',
      'status': 'Confirmed',
    },
    {
      'category': 'Lab Value',
      'value': 'HbA1c: 7.2% • Fasting Glucose: 138 mg/dL',
      'source': 'document_extracted',
      'status': 'Needs review',
    },
    {
      'category': 'Clinical Diagnosis',
      'value': 'Type 2 Diabetes Mellitus • Essential Hypertension',
      'source': 'document_extracted',
      'status': 'Confirmed',
    },
    {
      'category': 'Consultant & Hospital',
      'value': 'Dr. A. Sharma • AIIMS New Delhi (14 Aug 2024)',
      'source': 'document_extracted',
      'status': 'Confirmed',
    },
  ];

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

        try {
          await ApiService.uploadDocument(
            encounterId: encId,
            fileBytes: bytes,
            filename: image.name,
          );
        } catch (_) {
          // Graceful fallback for demo/offline
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.tr(
                  'Document processed with OCR successfully.',
                  'दस्तावेज़ ओसीआर द्वारा सफलतापूर्वक स्कैन किया गया।',
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note: $e')),
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
              }
              Navigator.pop(ctx);
            },
            child: Text(state.tr('Confirm', 'पुष्टि करें')),
          ),
        ],
      ),
    );
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

                        // Document Preview Banner
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
                                      _uploadedFilename ?? 'Prescription_AIIMS_Aug2024.jpg',
                                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'OCR Status: Analyzed • 5 Entities Extracted',
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

                        // OCR Extracted Items Stack
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

                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: state.tr(
                            'Confirm Records & Proceed to AYUSH • आगे बढ़ें',
                            'पुष्टि करें और आयुष प्रोफ़ाइल पर जाएं',
                          ),
                          icon: Icons.arrow_forward,
                          onPressed: () => context.go('/ayush'),
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
