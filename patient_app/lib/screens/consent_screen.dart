import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

/// Screen 03 — Consent
/// Simple, clear, non-legal. Never hide consent behind dense text.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                state.tr('Before We Collect Information', 'जानकारी लेने से पहले'),
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ConsentPoint(
                        icon: Icons.mic_rounded,
                        title: state.tr('Voice Recording', 'आवाज़ रिकॉर्डिंग'),
                        body: state.tr(
                          'We will record your voice to understand what is troubling you. This helps us structure your health information.',
                          'आपकी समस्या समझने के लिए हम आपकी आवाज़ रिकॉर्ड करेंगे। इससे आपकी स्वास्थ्य जानकारी व्यवस्थित होगी।',
                        ),
                      ),
                      _ConsentPoint(
                        icon: Icons.document_scanner_rounded,
                        title: state.tr('Document Processing', 'दस्तावेज़ प्रसंस्करण'),
                        body: state.tr(
                          'If you share previous medical documents, we will process them to extract relevant health information.',
                          'यदि आप पुराने मेडिकल दस्तावेज़ साझा करते हैं, तो हम उनसे स्वास्थ्य जानकारी निकालेंगे।',
                        ),
                      ),
                      _ConsentPoint(
                        icon: Icons.psychology_rounded,
                        title: state.tr('AI-Assisted Processing', 'AI-सहायक प्रसंस्करण'),
                        body: state.tr(
                          'AI technology helps organize your information. A physician will review everything before any clinical decision.',
                          'AI तकनीक आपकी जानकारी व्यवस्थित करने में मदद करती है। किसी भी नैदानिक निर्णय से पहले एक डॉक्टर सब कुछ देखेंगे।',
                        ),
                      ),
                      _ConsentPoint(
                        icon: Icons.person_rounded,
                        title: state.tr('Physician Review', 'चिकित्सक समीक्षा'),
                        body: state.tr(
                          'All information is reviewed by a qualified physician. AI does not make medical decisions.',
                          'सभी जानकारी एक योग्य चिकित्सक द्वारा समीक्षा की जाती है। AI चिकित्सा निर्णय नहीं लेता।',
                        ),
                      ),
                      _ConsentPoint(
                        icon: Icons.lock_rounded,
                        title: state.tr('Your Privacy', 'आपकी गोपनीयता'),
                        body: state.tr(
                          'Your data is kept private and secure. It is only shared with your treating physician.',
                          'आपका डेटा निजी और सुरक्षित रखा जाता है। यह केवल आपके उपचार करने वाले चिकित्सक के साथ साझा किया जाता है।',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: state.tr('I Understand & Consent', 'मैं समझता/समझती हूँ और सहमत हूँ'),
                icon: Icons.check_rounded,
                onPressed: () {
                  context.read<AppState>().grantConsent();
                  context.go('/patient-details');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: state.tr('Not Now', 'अभी नहीं'),
                onPressed: () => context.go('/welcome'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ConsentPoint({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brand, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
