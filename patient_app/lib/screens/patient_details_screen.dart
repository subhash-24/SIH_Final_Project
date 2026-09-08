import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

/// Screen 04 — Patient Details
class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});
  @override State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
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
    _nameCtrl.dispose(); _ageCtrl.dispose();
    _mobileCtrl.dispose(); _abhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final state = context.read<AppState>();
    try {
      // Create patient
      final patient = await ApiService.createPatient(
        name: _nameCtrl.text.trim(),
        age: _ageCtrl.text.trim(),
        gender: _gender,
        mobile: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
        abhaNumber: _abhaCtrl.text.trim().isEmpty ? null : _abhaCtrl.text.trim(),
        language: state.languageCode,
      );

      // Create encounter
      final encounter = await ApiService.createEncounter(patientId: patient['id']);

      final pd = PatientData()
        ..name = _nameCtrl.text.trim()
        ..age = _ageCtrl.text.trim()
        ..gender = _gender
        ..mobile = _mobileCtrl.text.trim()
        ..abhaNumber = _abhaCtrl.text.trim()
        ..preferredLanguage = state.languageCode;

      state.updatePatient(pd);
      state.setEncounter(encounter['id']);

      if (mounted) context.go('/before-begin');
    } catch (e) {
      setState(() { _error = state.tr('Could not save. Please try again.', 'सहेजा नहीं जा सका। कृपया पुनः प्रयास करें।'); });
    } finally {
      if (mounted) setState(() { _loading = false; });
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
              Text(state.tr('Your Details', 'आपकी जानकारी'), style: AppTextStyles.heading),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.tr('We need a few basic details to get started.',
                         'शुरुआत के लिए हमें कुछ बुनियादी जानकारी चाहिए।'),
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _field(
                          label: state.tr('Full Name *', 'पूरा नाम *'),
                          ctrl: _nameCtrl,
                          hint: state.tr('Enter your name', 'अपना नाम दर्ज करें'),
                          validator: (v) => v!.isEmpty ? state.tr('Name is required', 'नाम आवश्यक है') : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _field(
                          label: state.tr('Age', 'आयु'),
                          ctrl: _ageCtrl,
                          hint: state.tr('e.g. 45', 'जैसे 45'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Gender
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.tr('Gender', 'लिंग'), style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (final g in [
                                  (state.tr('Male', 'पुरुष'), 'Male'),
                                  (state.tr('Female', 'महिला'), 'Female'),
                                  (state.tr('Other', 'अन्य'), 'Other'),
                                ])
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _gender = g.$2),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: _gender == g.$2 ? AppColors.brandLight : AppColors.surface,
                                          border: Border.all(color: _gender == g.$2 ? AppColors.brand : AppColors.border,
                                              width: _gender == g.$2 ? 2 : 1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(g.$1,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: _gender == g.$2 ? AppColors.brand : AppColors.textPrimary,
                                            )),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _field(
                          label: state.tr('Mobile Number (Optional)', 'मोबाइल नंबर (वैकल्पिक)'),
                          ctrl: _mobileCtrl,
                          hint: state.tr('10-digit mobile', '10 अंक का मोबाइल'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _field(
                          label: 'ABHA ${state.tr('Number (Optional)', 'नंबर (वैकल्पिक)')}',
                          ctrl: _abhaCtrl,
                          hint: 'XX-XXXX-XXXX-XXXX',
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.urgentBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_error!, style: const TextStyle(color: AppColors.urgent, fontSize: 14)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: state.tr('Continue', 'जारी रखें'),
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.label.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brand, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
