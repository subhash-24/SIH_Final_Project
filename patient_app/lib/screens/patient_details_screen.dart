import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

/// Screen 04 — Patient Demographics & ABHA
/// Accessible 52px form controls, bilingual labels, touch-first
class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _abhaCtrl = TextEditingController();
  String _gender = 'Male';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _mobileCtrl.dispose();
    _abhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final state = context.read<AppState>();
    try {
      final patient = await ApiService.createPatient(
        name: _nameCtrl.text.trim(),
        age: _ageCtrl.text.trim(),
        gender: _gender,
        mobile: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
        abhaNumber: _abhaCtrl.text.trim().isEmpty ? null : _abhaCtrl.text.trim(),
        language: state.languageCode,
      );

      final encounter = await ApiService.createEncounter(patientId: patient['id']);

      final pd = PatientData(
        name: _nameCtrl.text.trim(),
        age: _ageCtrl.text.trim(),
        gender: _gender,
        mobile: _mobileCtrl.text.trim(),
        abhaNumber: _abhaCtrl.text.trim(),
        preferredLanguage: state.languageCode,
      );

      state.updatePatient(pd);
      state.setEncounter(encounter['id']);

      if (mounted) context.go('/before-begin');
    } catch (e) {
      setState(() {
        _error = state.tr(
          'Could not register encounter with server. Please try again.',
          'सर्वर से संपर्क नहीं हो सका। कृपया पुनः प्रयास करें।',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
          onPressed: () => context.go('/consent'),
        ),
        title: Text(state.tr('Patient Demographics', 'रोगी का विवरण')),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FlowProgressIndicator(
                            currentStep: 3,
                            totalSteps: 7,
                            stepLabel: 'Patient Details • व्यक्तिगत जानकारी',
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          Text(
                            state.tr('Patient Registration', 'रोगी पंजीकरण'),
                            style: AppTextStyles.headlineLg,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.tr(
                              'Please enter your basic information. If you have an ABHA Card, enter your 14-digit number.',
                              'कृपया अपनी बुनियादी जानकारी दर्ज करें। यदि आपके पास आभा कार्ड है तो 14 अंकों का नंबर दर्ज करें।',
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.urgentBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.urgent),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.urgent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.urgent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // Full Name
                          _buildTextField(
                            label: state.tr('Full Name / पूरा नाम *', 'पूरा नाम *'),
                            hint: state.tr('e.g. Ramesh Kumar', 'उदा. रमेश कुमार'),
                            controller: _nameCtrl,
                            icon: Icons.person_outline,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return state.tr('Please enter patient full name', 'कृपया पूरा नाम दर्ज करें');
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Age & Gender Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  label: state.tr('Age / उम्र *', 'उम्र *'),
                                  hint: 'e.g. 48',
                                  controller: _ageCtrl,
                                  keyboardType: TextInputType.number,
                                  icon: Icons.calendar_today_outlined,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return state.tr('Required', 'आवश्यक');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.tr('Gender / लिंग *', 'लिंग *'),
                                      style: AppTextStyles.labelLarge,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: ['Male', 'Female', 'Other'].map((g) {
                                          final isSelected = _gender == g;
                                          final label = g == 'Male'
                                              ? state.tr('Male', 'पुरुष')
                                              : g == 'Female'
                                                  ? state.tr('Female', 'महिला')
                                                  : state.tr('Other', 'अन्य');
                                          return Expanded(
                                            child: InkWell(
                                              onTap: () => setState(() => _gender = g),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                height: 42,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  label,
                                                  style: AppTextStyles.labelSmall.copyWith(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : AppColors.textPrimary,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Mobile Number
                          _buildTextField(
                            label: state.tr('Mobile Number / मोबाइल नंबर', 'मोबाइल नंबर'),
                            hint: '10-digit mobile number',
                            controller: _mobileCtrl,
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone_android_outlined,
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // ABHA ID
                          _buildTextField(
                            label: state.tr('ABHA Number / आभा संख्या (Optional)', 'आभा संख्या (वैकल्पिक)'),
                            hint: '14-digit ABHA (e.g. 91-8842-1092-3341)',
                            controller: _abhaCtrl,
                            icon: Icons.badge_outlined,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ABDM M2',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          PrimaryButton(
                            label: state.tr(
                              'Save Details & Continue • आगे बढ़ें',
                              'सहेजें और आगे बढ़ें',
                            ),
                            icon: Icons.arrow_forward,
                            loading: _loading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    Widget? trailing,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.labelLarge),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.textSecondary, size: 20) : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.urgent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
