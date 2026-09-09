import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

/// Screen 05 — Before We Begin
/// Explains what will happen — sets correct expectations.
class BeforeBeginScreen extends StatefulWidget {
  const BeforeBeginScreen({super.key});
  @override State<BeforeBeginScreen> createState() => _BeforeBeginScreenState();
}

class _BeforeBeginScreenState extends State<BeforeBeginScreen> {
  bool _loading = false;

  Future<void> _startInterview() async {
    final state = context.read<AppState>();
    if (state.encounterId == null) return;
    
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start interview: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              Text(state.tr('What Will Happen', 'क्या होगा'),
                  style: AppTextStyles.heading),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.tr('Here is what the next few minutes will look like.',
                         'अगले कुछ मिनट इस प्रकार होंगे।'),
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: Column(
                  children: [
                    _StepItem(
                      step: '1',
                      icon: Icons.mic_rounded,
                      title: state.tr('Speak About Your Problem', 'अपनी समस्या बताएं'),
                      body: state.tr(
                        'We will ask you a few questions. Speak naturally in your language.',
                        'हम आपसे कुछ सवाल पूछेंगे। अपनी भाषा में स्वाभाविक रूप से बोलें।',
                      ),
                    ),
                    _StepItem(
                      step: '2',
                      icon: Icons.document_scanner_rounded,
                      title: state.tr('Share Documents (Optional)', 'दस्तावेज़ साझा करें (वैकल्पिक)'),
                      body: state.tr(
                        'Previous prescriptions or reports help the doctor understand your history.',
                        'पिछले नुस्खे या रिपोर्ट डॉक्टर को आपका इतिहास समझने में मदद करते हैं।',
                      ),
                    ),
                    _StepItem(
                      step: '3',
                      icon: Icons.local_florist_rounded,
                      title: state.tr('AYUSH Wellness Check', 'आयुष स्वास्थ्य जांच'),
                      body: state.tr(
                        'Answer a few questions about your lifestyle for an Ayurvedic wellness profile.',
                        'आयुर्वेदिक स्वास्थ्य प्रोफ़ाइल के लिए अपनी जीवनशैली के बारे में कुछ सवालों के जवाब दें।',
                      ),
                    ),
                    _StepItem(
                      step: '4',
                      icon: Icons.person_rounded,
                      title: state.tr('Doctor Reviews', 'डॉक्टर समीक्षा करेंगे'),
                      body: state.tr(
                        'A qualified physician will review your information before your appointment.',
                        'एक योग्य चिकित्सक आपकी नियुक्ति से पहले आपकी जानकारी की समीक्षा करेंगे।',
                      ),
                    ),
                  ],
                ),
              ),

              // Hint
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, color: AppColors.brand, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.tr(
                          'Tip: The more you share, the better the doctor can prepare.',
                          'सुझाव: जितना अधिक आप साझा करेंगे, डॉक्टर उतना बेहतर तैयारी कर सकेंगे।',
                        ),
                        style: AppTextStyles.label.copyWith(color: AppColors.brand),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: state.tr("Let's Begin", 'शुरू करें'),
                icon: Icons.mic_rounded,
                loading: _loading,
                onPressed: _startInterview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String body;

  const _StepItem({required this.step, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
            child: Center(child: Text(step,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
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
