import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

/// Screen 12 — Check-In Success & Token Confirmation
/// Clear routing, institutional reassurance, tablet-first
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.success,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    state.tr('Intake Successfully Recorded', 'पंजीकरण सफलतापूर्वक दर्ज हुआ'),
                    style: AppTextStyles.headlineLg.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.tr(
                      'Your clinical intake summary has been transferred to the physician workstation.',
                      'आपका केस विवरण डॉक्टर के क्लिनिकल वर्कस्टेशन पर भेज दिया गया है।',
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Token Display Card
                  ClinicalCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    backgroundColor: AppColors.surface,
                    child: Column(
                      children: [
                        Text(
                          state.tr('YOUR OPD TOKEN NUMBER', 'आपका ओपीडी टोकन नंबर'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TK-204',
                          style: AppTextStyles.headlineXl.copyWith(
                            color: AppColors.primary,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            state.tr('Estimated Wait: ~12 mins (2 patients ahead)', 'अनुमानित समय: ~12 मिनट (आगे 2 मरीज)'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Divider(height: 28, color: AppColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.tr('Consulting Physician', 'परामर्श चिकित्सक'),
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dr. Rajesh Verma',
                                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  state.tr('Assigned Chamber', 'कक्ष संख्या'),
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Room 204 • Block 3',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Lounge directions
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.tr(
                              'Please proceed to Waiting Lounge 3 outside Room 204. Your token will be announced on the OPD display.',
                              'कृपया कमरा 204 के बाहर प्रतीक्षालय 3 में बैठें। ओपीडी डिस्प्ले स्क्रीन पर आपका नंबर बुलाया जाएगा।',
                            ),
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  PrimaryButton(
                    label: state.tr('Done • Finish Session', 'समाप्त करें'),
                    icon: Icons.check,
                    onPressed: () {
                      context.read<AppState>().resetForNewPatient();
                      context.go('/welcome');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
