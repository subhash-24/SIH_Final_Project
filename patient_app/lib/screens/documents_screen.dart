import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  int _uploadedCount = 0;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _isUploading = true;
        });
        
        final bytes = await image.readAsBytes();
        final state = context.read<AppState>();
        
        if (state.encounterId == null) {
          throw Exception("No active encounter");
        }

        final res = await ApiService.uploadDocument(
          encounterId: state.encounterId!,
          fileBytes: bytes,
          filename: image.name,
        );

        setState(() {
          _uploadedCount++;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(state.tr('Document uploaded successfully!', 'दस्तावेज़ सफलतापूर्वक अपलोड किया गया!'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload document: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(state.tr('Upload Documents', 'दस्तावेज़ अपलोड करें')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const FlowProgressIndicator(
                currentStep: 4,
                totalSteps: 6,
                stepLabel: 'Documents',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                state.tr('Any previous reports or prescriptions?', 'कोई पिछली रिपोर्ट या नुस्खे?'),
                style: AppTextStyles.question,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.tr("You can skip this if you don't have any.", 'यदि आपके पास कोई नहीं है तो आप इसे छोड़ सकते हैं।'),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              
              if (_uploadedCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.brand),
                      const SizedBox(width: 8),
                      Text(
                        '$_uploadedCount ${state.tr('documents uploaded', 'दस्तावेज़ अपलोड किए गए')}',
                        style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              
              if (_isUploading)
                const CircularProgressIndicator(color: AppColors.brand)
              else
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: state.tr('Take Photo', 'फोटो लें'),
                        icon: Icons.camera_alt,
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SecondaryButton(
                        label: state.tr('Upload File', 'फ़ाइल अपलोड करें'),
                        icon: Icons.upload_file,
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              PrimaryButton(
                label: _uploadedCount > 0 ? state.tr('Continue', 'जारी रखें') : state.tr('Skip', 'छोड़ें'),
                onPressed: () {
                  context.go('/ayush');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
