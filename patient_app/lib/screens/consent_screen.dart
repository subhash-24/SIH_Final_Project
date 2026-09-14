import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

/// Screen 03 — Consent & Clinical Intake Notice
/// Clear, dignified, non-legalistic, DPDP / ABDM compliant
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/language'),
        ),
        title: Text(state.tr('Informed Consent', 'सहमति एवं गोपनीयता')),
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
                        const FlowProgressIndicator(
                          currentStep: 2,
                          totalSteps: 7,
                          stepLabel: 'Clinical Consent • सहमति',
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Text(
                          state.tr(
                            'Before We Begin Clinical Intake',
                            'जांच और विवरण दर्ज करने से पहले',
                          ),
                          style: AppTextStyles.headlineLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.tr(
                            'Please review how your spoken words and medical records are processed for today’s OPD consultation.',
                            'कृपया समझें कि आपकी बातचीत और पुराने पर्चे आज के परामर्श के लिए कैसे सुरक्षित रूप से दर्ज किए जाते हैं।',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Points List
                        _ConsentCard(
                          icon: Icons.mic,
                          iconColor: AppColors.primary,
                          title: state.tr('Spoken Voice Intake • आवाज़ रिकॉर्डिंग', 'आवाज़ रिकॉर्डिंग'),
                          description: state.tr(
                            'Your spoken description of symptoms is converted to structured clinical notes for the doctor. Audio is encrypted and erased post-consultation.',
                            'आपके द्वारा बोले गए लक्षणों को डॉक्टर के लिए व्यवस्थित नोट्स में बदला जाता है। ऑडियो सुरक्षित और एन्क्रिप्टेड रहता है।',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _ConsentCard(
                          icon: Icons.document_scanner,
                          iconColor: AppColors.info,
                          title: state.tr('Document OCR Extraction • पर्चा स्कैन', 'पर्चा स्कैन'),
                          description: state.tr(
                            'Prior prescriptions and lab results are scanned only to help the doctor review your existing medications and past tests.',
                            'पुराने पर्चे और लैब रिपोर्ट केवल डॉक्टर को आपकी वर्तमान दवाएं और पुरानी रिपोर्ट दिखाने के लिए स्कैन किए जाते हैं।',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _ConsentCard(
                          icon: Icons.health_and_safety,
                          iconColor: AppColors.success,
                          title: state.tr('Physician Review Guarantee • चिकित्सक द्वारा जांच', 'चिकित्सक द्वारा जांच'),
                          description: state.tr(
                            'AI assists only in typing and structuring. Your consulting physician evaluates all findings and makes 100% of diagnostic decisions.',
                            'एआई केवल व्यवस्थित करने में मदद करता है। अंतिम जांच और इलाज का निर्णय पूरी तरह आपके डॉक्टर द्वारा किया जाता है।',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _ConsentCard(
                          icon: Icons.lock,
                          iconColor: AppColors.textPrimary,
                          title: state.tr('ABDM & DPDP Privacy • डेटा सुरक्षा', 'डेटा सुरक्षा'),
                          description: state.tr(
                            'Your health record is securely stored following Ayushman Bharat Digital Mission (ABDM) standards and never sold or shared with third parties.',
                            'आपका स्वास्थ्य डेटा आयुष्मान भारत डिजिटल मिशन के नियमों के अनुसार पूरी तरह निजी और सुरक्षित है।',
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: state.tr(
                            'I Understand & Consent • मैं सहमत हूँ',
                            'मैं समझता/समझती हूँ और सहमत हूँ',
                          ),
                          icon: Icons.check_circle_outline,
                          onPressed: () {
                            context.read<AppState>().grantConsent();
                            context.go('/patient-details');
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        SecondaryButton(
                          label: state.tr('Not Now • अभी नहीं', 'अभी नहीं'),
                          onPressed: () => context.go('/welcome'),
                        ),
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

class _ConsentCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _ConsentCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicalCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
