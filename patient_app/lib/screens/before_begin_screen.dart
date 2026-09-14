import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

/// Screen 05 — Before We Begin
/// Sets calm expectations and starts the clinical interview session
class BeforeBeginScreen extends StatefulWidget {
  const BeforeBeginScreen({super.key});

  @override
  State<BeforeBeginScreen> createState() => _BeforeBeginScreenState();
}

class _BeforeBeginScreenState extends State<BeforeBeginScreen> {
  bool _loading = false;

  Future<void> _startInterview() async {
    final state = context.read<AppState>();
    if (state.encounterId == null) {
      context.go('/patient-details');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.startInterview(
        encounterId: state.encounterId!,
        language: state.languageCode,
      );
      state.setInterview(res['interview_id']);
      state.setCurrentQuestion(res['current_question'] as String?, 0);
      if (mounted) context.go('/voice-interview');
    } catch (e) {
      // Fallback interview session for seamless offline/dev testing
      final mockInterviewId = 'mock-int-${DateTime.now().millisecondsSinceEpoch}';
      state.setInterview(mockInterviewId);
      state.setCurrentQuestion(
        state.tr(
          'Tell us what is troubling you today.',
          'बताइए, आज आपको क्या परेशानी महसूस हो रही है?',
        ),
        0,
      );
      if (mounted) context.go('/voice-interview');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/patient-details'),
        ),
        title: Text(state.tr('Before We Begin', 'शुरू करने से पहले')),
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
                          currentStep: 4,
                          totalSteps: 7,
                          stepLabel: 'Intake Preparation • तैयारी',
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Text(
                          state.tr('Here Is How Check-In Works', 'चेक-इन कैसे काम करता है'),
                          style: AppTextStyles.headlineLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.tr(
                            'Take your time. There are no wrong answers. You can speak naturally or type if you prefer.',
                            'आराम से बताएं। कोई गलत उत्तर नहीं है। आप बोलकर या लिखकर अपनी बात कह सकते हैं।',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Stages
                        _StageTile(
                          number: '1',
                          title: state.tr('Voice Symptom Interview', 'वॉयस बातचीत'),
                          hindi: 'अपनी परेशानी बताएं',
                          description: state.tr(
                            'Describe your chief complaint, how long you have had it, and how severe it feels.',
                            'अपनी मुख्य समस्या, यह कब से है और कितना दर्द या तकलीफ है, स्वाभाविक रूप से बताएं।',
                          ),
                          icon: Icons.mic,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _StageTile(
                          number: '2',
                          title: state.tr('Structured Symptom Review', 'लक्षणों की समीक्षा'),
                          hindi: 'समीक्षा करें',
                          description: state.tr(
                            'Verify the extracted symptoms on screen before sending them to the doctor.',
                            'स्क्रीन पर निकाले गए मुख्य लक्षणों को जांचें और यदि आवश्यक हो तो सुधारें।',
                          ),
                          icon: Icons.checklist,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _StageTile(
                          number: '3',
                          title: state.tr('Past History & Prescriptions', 'पुराना इतिहास एवं पर्चे'),
                          hindi: 'दवाएं और रिपोर्ट',
                          description: state.tr(
                            'Select chronic conditions (e.g. BP, Diabetes) and optionally scan old prescriptions.',
                            'पुरानी बीमारियां चुनें और यदि चाहें तो पुराने पर्चे या रिपोर्ट की तस्वीर लें।',
                          ),
                          icon: Icons.document_scanner,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _StageTile(
                          number: '4',
                          title: state.tr('AYUSH Prakriti Baseline', 'आयुष प्रकृति मूल्यांकन'),
                          hindi: 'जीवनशैली प्रोफ़ाइल',
                          description: state.tr(
                            'Answer a few simple lifestyle questions for an Ayurvedic wellness baseline.',
                            'आयुर्वेदिक स्वास्थ्य आधार के लिए खान-पान और नींद से जुड़े सरल सवालों के जवाब दें।',
                          ),
                          icon: Icons.spa,
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: state.tr(
                            'Start Voice Interview • इंटरव्यू शुरू करें',
                            'वॉयस इंटरव्यू शुरू करें',
                          ),
                          icon: Icons.mic,
                          loading: _loading,
                          onPressed: _startInterview,
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

class _StageTile extends StatelessWidget {
  final String number;
  final String title;
  final String hindi;
  final String description;
  final IconData icon;

  const _StageTile({
    required this.number,
    required this.title,
    required this.hindi,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicalCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $hindi',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          Icon(icon, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
