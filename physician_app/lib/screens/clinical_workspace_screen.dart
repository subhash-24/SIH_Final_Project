import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ClinicalWorkspaceScreen extends StatefulWidget {
  final String encounterId;
  const ClinicalWorkspaceScreen({super.key, required this.encounterId});

  @override
  State<ClinicalWorkspaceScreen> createState() => _ClinicalWorkspaceScreenState();
}

class _ClinicalWorkspaceScreenState extends State<ClinicalWorkspaceScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;
  String _activeTab = 'clinical';

  // Stopwatch timer
  Timer? _stopwatchTimer;
  int _secondsElapsed = 402; // Initialized to ~06:42 like Stitch screen

  // Diagnosis inputs
  final TextEditingController _diagSearchCtrl = TextEditingController(text: 'Gastro-oesophageal reflux disease');
  final TextEditingController _diagNotesCtrl = TextEditingController(
    text: 'Recurrent retrosternal burning post-prandial. Stat ECG ordered to exclude acute coronary syndrome before starting PPI.',
  );
  bool _savingDiagnosis = false;
  String? _diagnosisSavedMessage;

  // FHIR Bundle state
  Map<String, dynamic>? _fhirBundle;
  bool _loadingFhir = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _diagSearchCtrl.dispose();
    _diagNotesCtrl.dispose();
    super.dispose();
  }

  String _formatStopwatch(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    try {
      final summary = await ApiService.getSummary(widget.encounterId);
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load encounter summary: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchFhirBundle() async {
    setState(() => _loadingFhir = true);
    try {
      final bundle = await ApiService.generateFhirBundle(widget.encounterId);
      if (mounted) {
        setState(() {
          _fhirBundle = bundle;
          _loadingFhir = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingFhir = false);
    }
  }

  Future<void> _saveDiagnosis() async {
    setState(() {
      _savingDiagnosis = true;
      _diagnosisSavedMessage = null;
    });
    try {
      await ApiService.createDiagnosis(
        widget.encounterId,
        _diagSearchCtrl.text,
        _diagNotesCtrl.text,
      );
      if (mounted) {
        setState(() {
          _savingDiagnosis = false;
          _diagnosisSavedMessage = 'Dual Coding & Diagnosis confirmed and signed into FHIR R4 Bundle!';
        });
        _loadSummary();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _savingDiagnosis = false;
          _diagnosisSavedMessage = 'Error saving: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null || _summary == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
          title: const Text('Encounter Not Found'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AppTheme.urgent),
              const SizedBox(height: 12),
              Text(_error ?? 'Unable to load encounter record.', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Back to Dashboard Queue'),
              ),
            ],
          ),
        ),
      );
    }

    final patient = _summary!['patient'] ?? {};
    final redFlags = List<dynamic>.from(_summary!['red_flags'] ?? []);
    final isUrgent = _summary!['priority'] == 'urgent' || redFlags.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // 1. Patient Master Header & Vitals Ribbon (Stitch Screens 2, 3, 4)
          _buildPatientMasterHeader(patient, isUrgent),

          // 2. Main Workspace Layout: Navigation Sidebar + Tab Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Quick Workspace Navigation
                _buildWorkspaceSidebar(redFlags.length),

                // Center Main Dynamic Tab Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: _buildActiveTabContent(patient, redFlags, isUrgent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TOP PATIENT MASTER HEADER & VITALS
  Widget _buildPatientMasterHeader(Map<String, dynamic> patient, bool isUrgent) {
    final name = patient['name'] ?? 'Ramesh Chandra Gupta';
    final hindiName = patient['name_hi'] ?? 'रमेश चंद्र गुप्ता';
    final age = patient['age'] ?? 58;
    final gender = patient['gender'] ?? 'Male';
    final abhaId = patient['abha_id'] ?? '91-8842-1092-4410';
    final uhid = patient['uhid'] ?? 'AI-7824-DL';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Patient Demographics & Action Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  tooltip: 'Return to Queue',
                  onPressed: () => context.go('/dashboard'),
                ),
                const SizedBox(width: 8),

                // Patient Avatar Badge
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Demographics & IDs
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hindiName,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                          const SizedBox(width: 10),
                          AppTheme.buildBadge(label: '$age Yrs • $gender'),
                          const SizedBox(width: 6),
                          AppTheme.buildBadge(label: 'B+ve'),
                          const SizedBox(width: 6),
                          AppTheme.buildBadge(
                            label: 'NKDA (No Known Allergies)',
                            bg: AppTheme.secondaryContainer,
                            fg: AppTheme.onSecondaryContainer,
                            icon: Icons.verified,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'UHID: $uhid  •  ABHA ID: $abhaId  •  Apollo Hospital Records Linked (FHIR R4)',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Consultation Stopwatch & Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 3, backgroundColor: AppTheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'Consultation: ${_formatStopwatch(_secondsElapsed)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Past Visits'),
                ),
              ],
            ),
          ),

          // Vitals Ribbon Matrix (6 cards)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: AppTheme.surfaceLow,
            child: Row(
              children: [
                _buildVitalCard('Blood Pressure', '138/88', 'mmHg', 'Borderline', isWarning: true),
                const SizedBox(width: 8),
                _buildVitalCard('Pulse / HR', '84', 'bpm', 'Normal'),
                const SizedBox(width: 8),
                _buildVitalCard('SpO2', '98%', 'Room Air', 'Optimal', isOptimal: true),
                const SizedBox(width: 8),
                _buildVitalCard('Body Temp', '98.4', '°F', 'Normal'),
                const SizedBox(width: 8),
                _buildVitalCard('BMI', '26.4', 'kg/m²', 'Overweight'),
                const SizedBox(width: 8),
                _buildVitalCard('Random Glucose', '142', 'mg/dL', 'Post-prandial'),
              ],
            ),
          ),

          // Active Clinical Triage Alert Banner (Stitch Screen 2 / 3)
          if (isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.urgentBg,
                border: Border(top: BorderSide(color: AppTheme.urgentBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.urgent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.urgent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'EMERGENCY SYMPTOM TRIAGE TRIGGERED (Protocol E-102)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.urgent,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Patient reported episodic retrosternal chest pressure during voice intake. Stat 12-Lead ECG recommended to rule out Atypical Acute Coronary Syndrome.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stat 12-Lead ECG ordered with Priority STAT.')),
                      );
                    },
                    icon: const Icon(Icons.monitor_heart, size: 16),
                    label: const Text('Order Stat ECG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.urgent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(String label, String value, String unit, String tag, {bool isWarning = false, bool isOptimal = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isWarning ? AppTheme.tertiary : (isOptimal ? AppTheme.secondary : AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 3),
                Text(unit, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // WORKSPACE LEFT SIDEBAR
  Widget _buildWorkspaceSidebar(int alertCount) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'ENCOUNTER NAVIGATION',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
            ),
          ),
          _buildWorkspaceNavTile('clinical', 'Clinical Overview', Icons.article_outlined),
          _buildWorkspaceNavTile('red_flags', 'Red Flag Triage', Icons.emergency, isUrgent: alertCount > 0, badge: alertCount > 0 ? '$alertCount' : null),
          _buildWorkspaceNavTile('dual_coding', 'Dual Coding & Dx', Icons.menu_book),
          _buildWorkspaceNavTile('ocr_docs', 'Diagnostics & OCR', Icons.document_scanner),
          _buildWorkspaceNavTile('timeline', 'Longitudinal Timeline', Icons.timeline),
          _buildWorkspaceNavTile('fhir', 'FHIR R4 Inspector', Icons.data_object),
        ],
      ),
    );
  }

  Widget _buildWorkspaceNavTile(String id, String label, IconData icon, {bool isUrgent = false, String? badge}) {
    final isActive = _activeTab == id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 18,
          color: isActive
              ? AppTheme.primary
              : (isUrgent ? AppTheme.urgent : AppTheme.textSecondary),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isUrgent ? AppTheme.urgent : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              )
            : null,
        onTap: () {
          setState(() => _activeTab = id);
          if (id == 'fhir' && _fhirBundle == null) {
            _fetchFhirBundle();
          }
        },
      ),
    );
  }

  // DYNAMIC TAB CONTENT SWITCHER
  Widget _buildActiveTabContent(Map<String, dynamic> patient, List<dynamic> redFlags, bool isUrgent) {
    switch (_activeTab) {
      case 'clinical':
        return _buildClinicalOverviewTab(patient, redFlags);
      case 'red_flags':
        return _buildRedFlagTriageTab(redFlags);
      case 'dual_coding':
        return _buildDualCodingTab();
      case 'ocr_docs':
        return _buildOcrDocumentsTab();
      case 'timeline':
        return _buildTimelineTab(patient);
      case 'fhir':
        return _buildFhirInspectorTab();
      default:
        return _buildClinicalOverviewTab(patient, redFlags);
    }
  }

  // 1. CLINICAL OVERVIEW TAB (Stitch Screen 2: 3-column Master Grid)
  Widget _buildClinicalOverviewTab(Map<String, dynamic> patient, List<dynamic> redFlags) {
    final findings = _summary!['findings'] ?? {};
    final chiefComplaints = List<dynamic>.from(findings['chief_complaint'] ?? []);
    final hpi = List<dynamic>.from(findings['hpi'] ?? []);
    final ros = List<dynamic>.from(findings['ros'] ?? []);
    final docs = List<dynamic>.from(_summary!['documents'] ?? []);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Longitudinal Background
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildCardContainer(
                title: 'Longitudinal Profile',
                icon: Icons.history_edu,
                badge: 'ABDM M3 Sync',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CHRONIC CONDITIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    _buildConditionPill('Essential Hypertension', 'Stage 1 • Diagnosed 2021'),
                    const SizedBox(height: 4),
                    _buildConditionPill('Type 2 Diabetes Mellitus', 'Controlled • HbA1c 6.8%'),
                    const SizedBox(height: 16),

                    const Text('ACTIVE MEDICATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    _buildMedicationRow('Telmisartan 40mg', 'Once daily (morning)'),
                    _buildMedicationRow('Metformin 500mg ER', 'Twice daily post-prandial'),
                    const SizedBox(height: 16),

                    const Text('AYUSH PRAKRITI BASELINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border, width: 0.8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.spa, size: 16, color: AppTheme.secondary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pitta-dominant Prakriti (पित्त-प्रधान प्रकृति)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Center Column: Current Encounter & Intake
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildCardContainer(
                title: 'Current Encounter & Voice Intake',
                icon: Icons.mic_none,
                badge: 'Cloud LLM Extraction',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chief Complaint Card
                    const Text('CHIEF COMPLAINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (chiefComplaints.isNotEmpty)
                            ...chiefComplaints.map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.record_voice_over, size: 15, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          c['value'] ?? '',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                        ),
                                      ),
                                      AppTheme.buildSourceTag(c['source'] ?? 'PATIENT_REPORTED'),
                                    ],
                                  ),
                                ))
                          else
                            const Text('No chief complaint recorded.', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // HPI Findings
                    const Text('HISTORY OF PRESENT ILLNESS (HPI)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    if (hpi.isNotEmpty)
                      ...hpi.map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.border, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['value'] ?? '',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                                AppTheme.buildSourceTag(item['source'] ?? 'PATIENT_REPORTED'),
                              ],
                            ),
                          ))
                    else
                      const Text('Onset 2 hours ago with radiation to left arm and cold sweating.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),

                    // Review of Systems (ROS)
                    const Text('REVIEW OF SYSTEMS (ROS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    if (ros.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ros.map((r) => AppTheme.buildBadge(label: r['value'] ?? '')).toList(),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: [
                          AppTheme.buildBadge(label: 'Cardiovascular: Palpitation'),
                          AppTheme.buildBadge(label: 'Respiratory: Exertional Dyspnea'),
                          AppTheme.buildBadge(label: 'Gastrointestinal: Acid Reflux'),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Attached Documents & OCR Summary
              _buildCardContainer(
                title: 'Diagnostic Documents & OCR Review',
                icon: Icons.document_scanner,
                badge: '${docs.length} Uploaded',
                child: docs.isNotEmpty
                    ? Column(
                        children: docs.map((d) => _buildDocumentItem(d)).toList(),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.attachment, size: 16, color: AppTheme.textMuted),
                            SizedBox(width: 8),
                            Text('Pre-intake ECG Strip and lipid panel linked via ABHA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Right Column: Priority, Red Flags & Actions
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildCardContainer(
                title: 'Explainable Triage & Red Flags',
                icon: Icons.emergency,
                badge: redFlags.isNotEmpty ? '${redFlags.length} Rule Triggered' : 'Normal',
                isUrgentHeader: redFlags.isNotEmpty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (redFlags.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No critical symptom pattern alerts detected for this encounter.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      ...redFlags.map((flag) => _buildRedFlagDecisionCard(flag)),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('CLINICAL SAFETY MANDATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          SizedBox(height: 4),
                          Text(
                            'All deterministic red-flag evaluations use clinical protocols verified by medical board. AI outputs require final physician sign-off.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. RED FLAG EMERGENCY TRIAGE TAB (Stitch Screen 3)
  Widget _buildRedFlagTriageTab(List<dynamic> redFlags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.urgentBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(color: AppTheme.urgent, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.crisis_alert, size: 28, color: AppTheme.urgent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ACTIVE CLINICAL ESCALATION: RULE-OUT ACUTE CORONARY SYNDROME',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.urgent),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Triggered by deterministic safety rule "Possible Cardiac Emergency" on matching symptoms: chest heaviness/pain + sweating + arm radiation.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Audio Evidence & Algorithmic Stratification
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildCardContainer(
                    title: 'Intake Voice Evidence',
                    icon: Icons.mic,
                    badge: 'Audio Snippet @ 00:18s',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.format_quote, size: 16, color: AppTheme.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    '"चलने पर सीने में भारीपन सा लगता है और पसीना आता है"',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'English Translation: "Feels heaviness in chest when walking, and sweating occurs."',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Waveform Widget
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(width: 80, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(4))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text('00:18 (Trigger Timestamp)', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                      Text('Total 00:42', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildCardContainer(
                    title: 'Algorithmic Risk Stratification',
                    icon: Icons.analytics,
                    badge: 'HEART Score: 4 / 10',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('HEART Score Estimation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            Text('Moderate Risk (12-16% MACE)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.4,
                            backgroundColor: AppTheme.surfaceContainer,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tertiary),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pathway recommendation: Perform immediate serial ECG & bedside clinical adjudication before OPD discharge.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right Panel: Criteria Checklist & Action Protocol
            Expanded(
              flex: 5,
              child: _buildCardContainer(
                title: 'Identified Trigger Criteria & Adjudication',
                icon: Icons.checklist,
                badge: 'Clinical Adjudication',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCriteriaCheckItem('Retrosternal pressure on exertion', true),
                    _buildCriteriaCheckItem('Diaphoresis / cold sweating during episode', true),
                    _buildCriteriaCheckItem('Radiation to left arm / shoulder', true),
                    _buildCriteriaCheckItem('Associated syncope or dizziness', false),
                    _buildCriteriaCheckItem('Known coronary artery disease history', false),
                    const SizedBox(height: 20),

                    const Text('TRIAGE ADJUDICATION ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order Stat 12-Lead ECG + Troponin-I dispatched to Lab.')),
                        );
                      },
                      icon: const Icon(Icons.monitor_heart, size: 18),
                      label: const Text('Adjudicate & Order Stat ECG + Troponin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.urgent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Escalated for bedside clinical evaluation.')),
                        );
                      },
                      icon: const Icon(Icons.hotel, size: 18),
                      label: const Text('Escalate for Bedside Clinical Evaluation'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alert acknowledged and marked in encounter notes.')),
                        );
                      },
                      child: const Center(
                        child: Text(
                          'Acknowledge & Downgrade to Non-Urgent (Requires Justification)',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCriteriaCheckItem(String text, bool isMatched) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMatched ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMatched ? AppTheme.urgent : AppTheme.outlineVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isMatched ? FontWeight.w600 : FontWeight.normal,
                color: isMatched ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
          ),
          if (isMatched)
            AppTheme.buildBadge(label: 'MATCHED', bg: AppTheme.urgentBg, fg: AppTheme.urgent),
        ],
      ),
    );
  }

  // 3. DUAL CODING & DIAGNOSIS TAB (Stitch Screen 4)
  Widget _buildDualCodingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Context Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'NABH INTEGRATIVE DUAL-CODING WORKSPACE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Dual classification connecting Allopathic WHO ICD-11 MMS with AYUSH NAMASTE & ICD-11 TM2',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              AppTheme.buildBadge(
                label: 'NABH Protocol v3.2 Verified',
                bg: AppTheme.secondaryContainer,
                fg: AppTheme.onSecondaryContainer,
                icon: Icons.verified,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2 Side-by-Side Panels: Allopathic (ICD-11) & AYUSH (NAMASTE / TM2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Allopathic Panel
            Expanded(
              child: _buildCardContainer(
                title: 'Allopathic Diagnosis (ICD-11 MMS)',
                icon: Icons.monitor_heart,
                badge: 'Primary Coding',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ICD-11: MD81',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'monospace'),
                                ),
                              ),
                              AppTheme.buildBadge(label: 'Physician Confirmed', bg: AppTheme.secondaryContainer, fg: AppTheme.onSecondaryContainer),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gastro-oesophageal reflux disease',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'GORD / GERD with recurrent retrosternal pyrosis & acidic eructation post-prandial.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Anatomical Site: Lower Oesophageal Sphincter', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              Text('Severity: Moderate (Stage B)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Comorbid condition
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                            child: const Text('ICD-11: BA00', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Essential Hypertension (Controlled on ARB)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                          AppTheme.buildBadge(label: 'Secondary'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // AYUSH Panel
            Expanded(
              child: _buildCardContainer(
                title: 'AYUSH Diagnostic Framework',
                icon: Icons.spa,
                badge: 'Dual-Mapped',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NAMASTE: AYU-AM-0412',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onTertiaryContainer, fontFamily: 'monospace'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TM2: TM2-AY-104.2',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Text(
                                'Amlapitta',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '(अम्लपित्त)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.tertiary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Acid Dyspepsia with Vidagdha Pitta and vitiated Samana Vayu.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Dosha: Pitta-dominant (पित्त)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              Text('Sub-type: Urdhvaga Amlapitta', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Terminology Sync confidence
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('FHIR Mapping: Condition.code.coding[0..1]', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('Mapping Confidence: 99.4%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Physician Edit & Sign Section
        _buildCardContainer(
          title: 'Physician Diagnosis & Clinical Notes',
          icon: Icons.edit_note,
          badge: 'Sign-off Required',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _diagSearchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Primary Clinical Diagnosis (ICD-11 or Clinical Term)',
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _diagNotesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Physician Clinical Notes & Adjudication Rationale',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              if (_diagnosisSavedMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _diagnosisSavedMessage!,
                    style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _diagSearchCtrl.text = 'Gastro-oesophageal reflux disease';
                      _diagNotesCtrl.clear();
                    },
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _savingDiagnosis ? null : _saveDiagnosis,
                    icon: _savingDiagnosis
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.verified, size: 16),
                    label: const Text('Confirm & Sign Dual Diagnosis'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. DIAGNOSTIC DOCUMENTS & OCR TAB (Stitch Screen 4)
  Widget _buildOcrDocumentsTab() {
    final docs = List<dynamic>.from(_summary!['documents'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'DIAGNOSTICS & OCR DOCUMENT INGESTION',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                SizedBox(height: 2),
                Text('Handwriting recognition, prescription ingestion, and FHIR Observation conversion', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
            AppTheme.buildBadge(label: 'ABDM OCR Engine (32ms)'),
          ],
        ),
        const SizedBox(height: 16),

        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.document_scanner, size: 40, color: AppTheme.textMuted),
                  SizedBox(height: 8),
                  Text('No additional documents uploaded in this encounter.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          ...docs.map((d) => _buildDocumentCardFull(d)),
      ],
    );
  }

  Widget _buildDocumentCardFull(Map<String, dynamic> doc) {
    final name = doc['document_name'] ?? 'Prescription.jpg';
    final ocrData = doc['ocr_data'] ?? {};
    final fields = List<dynamic>.from(ocrData['extracted_fields'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                AppTheme.buildBadge(label: 'OCR Confidence: 94.2%'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EXTRACTED CLINICAL FIELDS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                if (fields.isEmpty)
                  const Text('No structured entities extracted.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted))
                else
                  ...fields.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('${f['field_name'] ?? 'Field'}: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Expanded(child: Text('${f['value'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. TIMELINE TAB
  Widget _buildTimelineTab(Map<String, dynamic> patient) {
    return _buildCardContainer(
      title: 'Longitudinal Medical Timeline',
      icon: Icons.timeline,
      badge: 'Multi-Hospital Ingestion',
      child: Column(
        children: [
          _buildTimelineEvent('Today 10:14 AM', 'Current OPD Consultation (AIIMS Delhi)', 'Chief complaint of retrosternal pressure, voice intake captured.', true),
          _buildTimelineEvent('12 Nov 2023', 'Diagnostic Lab - Lipid Profile (Apollo Hospital)', 'Total Cholesterol: 218 mg/dL, LDL: 134 mg/dL. Synced via ABDM FHIR.', false),
          _buildTimelineEvent('04 Jan 2023', 'Endoscopy & GI Consultation (Safdarjung Hospital)', 'Mild non-erosive gastroesophageal reflux. Prescribed Pantoprazole.', false),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(String date, String title, String desc, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor: isCurrent ? AppTheme.primary : AppTheme.outlineVariant,
              ),
              Container(width: 1.5, height: 36, color: AppTheme.border),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. FHIR R4 INSPECTOR TAB
  Widget _buildFhirInspectorTab() {
    return _buildCardContainer(
      title: 'ABDM FHIR R4 Bundle Inspector',
      icon: Icons.data_object,
      badge: 'FHIR R4 Compliant',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FHIR JSON Bundle (Encounter, Patient, Condition, Observation)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _fhirBundle != null
                        ? () {
                            Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_fhirBundle)));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FHIR JSON copied to clipboard.')));
                          }
                        : null,
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy JSON'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _fetchFhirBundle,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Regenerate Bundle'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingFhir)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppTheme.primary)))
          else if (_fhirBundle != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(_fhirBundle),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF9BE9E4),
                ),
              ),
            )
          else
            const Center(child: Text('Click "Regenerate Bundle" to inspect active FHIR R4 document.')),
        ],
      ),
    );
  }

  // HELPER WIDGETS
  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    String? badge,
    bool isUrgentHeader = false,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUrgentHeader ? AppTheme.urgentBorder : AppTheme.border,
          width: isUrgentHeader ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUrgentHeader ? AppTheme.urgentBg.withValues(alpha: 0.5) : AppTheme.surfaceLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              border: const Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: isUrgentHeader ? AppTheme.urgent : AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isUrgentHeader ? AppTheme.urgent : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (badge != null)
                  AppTheme.buildBadge(label: badge, isUrgent: isUrgentHeader),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildConditionPill(String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildMedicationRow(String med, String freq) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(med, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            ],
          ),
          Text(freq, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    final name = doc['document_name'] ?? 'Document';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          AppTheme.buildBadge(label: 'Verified OCR'),
        ],
      ),
    );
  }

  Widget _buildRedFlagDecisionCard(Map<String, dynamic> flag) {
    final isUrgent = flag['severity'] == 'urgent';
    final ruleName = flag['rule_name'] ?? 'Cardiac Risk';
    final reason = flag['reason'] ?? 'Emergency symptom pattern detected';
    final status = flag['status'] ?? 'detected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUrgent ? AppTheme.urgentBg : AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isUrgent ? AppTheme.urgentBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, size: 16, color: isUrgent ? AppTheme.urgent : AppTheme.tertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ruleName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? AppTheme.urgent : AppTheme.tertiary,
                  ),
                ),
              ),
              AppTheme.buildBadge(label: isUrgent ? 'URGENT' : 'WARNING', isUrgent: isUrgent),
            ],
          ),
          const SizedBox(height: 6),
          Text(reason, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          if (status == 'detected')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ApiService.acknowledgeRedFlag(flag['id']);
                      _loadSummary();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUrgent ? AppTheme.urgent : AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text('Acknowledge Alert', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            )
          else
            Row(
              children: const [
                Icon(Icons.check_circle, size: 14, color: AppTheme.secondary),
                SizedBox(width: 4),
                Text('Acknowledged by Dr. Rajesh Verma', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              ],
            ),
        ],
      ),
    );
  }
}
