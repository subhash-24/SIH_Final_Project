import 'package:flutter/foundation.dart';

enum Language { english, hindi, marathi, tamil, telugu, bengali }

enum VoiceState { idle, listening, processing, completed, error }

enum SyncState { offline, pending, syncing, synced, failed }

class PatientData {
  String name;
  String age;
  String gender;
  String mobile;
  String abhaNumber;
  String preferredLanguage;

  PatientData({
    this.name = '',
    this.age = '',
    this.gender = 'Male',
    this.mobile = '',
    this.abhaNumber = '',
    this.preferredLanguage = 'en',
  });
}

class ClinicalFinding {
  String fieldType;
  String value;
  String source;
  bool needsReview;

  ClinicalFinding({
    required this.fieldType,
    required this.value,
    required this.source,
    this.needsReview = true,
  });
}

class RedFlagInfo {
  final String ruleName;
  final String severity;
  final String patientMessage;
  final List<String> triggeredBy;

  RedFlagInfo({
    required this.ruleName,
    required this.severity,
    required this.patientMessage,
    required this.triggeredBy,
  });
}

class AppState extends ChangeNotifier {
  // Language
  Language _language = Language.english;
  Language get language => _language;

  // Patient Info
  PatientData _patient = PatientData();
  PatientData get patient => _patient;

  // IDs
  String? _encounterId;
  String? get encounterId => _encounterId;

  String? _interviewId;
  String? get interviewId => _interviewId;

  // Voice Interaction
  VoiceState _voiceState = VoiceState.idle;
  VoiceState get voiceState => _voiceState;

  String _transcript = '';
  String get transcript => _transcript;

  int _audioDurationSeconds = 38;
  int get audioDurationSeconds => _audioDurationSeconds;

  // Structured Clinical Findings
  final List<ClinicalFinding> _findings = [];
  List<ClinicalFinding> get findings => _findings;

  // Red Flags
  final List<RedFlagInfo> _redFlags = [];
  List<RedFlagInfo> get redFlags => _redFlags;
  bool get hasUrgentRedFlag => _redFlags.any((r) => r.severity == 'urgent');

  // Interview Questions
  String? _currentQuestion;
  String? get currentQuestion => _currentQuestion;
  int _questionIndex = 0;
  int get questionIndex => _questionIndex;

  // Consent
  bool _consentGranted = false;
  bool get consentGranted => _consentGranted;

  // Medical History
  final Set<String> _pastConditions = {};
  Set<String> get pastConditions => _pastConditions;

  final List<String> _currentMedications = [];
  List<String> get currentMedications => _currentMedications;

  final List<String> _allergies = [];
  List<String> get allergies => _allergies;

  // Document Extractions
  final List<Map<String, dynamic>> _documentExtractions = [];
  List<Map<String, dynamic>> get documentExtractions => _documentExtractions;
  String? _uploadedDocumentName;
  String? get uploadedDocumentName => _uploadedDocumentName;
  String? _uploadedDocumentOcrText;
  String? get uploadedDocumentOcrText => _uploadedDocumentOcrText;

  // AYUSH Prakriti Answers
  final Map<String, String> _prakritiAnswers = {};
  Map<String, String> get prakritiAnswers => _prakritiAnswers;

  // Sync State
  SyncState _syncState = SyncState.synced;
  SyncState get syncState => _syncState;

  // ──────────────────────────────────────────────────────────────────────────

  void setLanguage(Language lang) {
    _language = lang;
    _patient.preferredLanguage = languageCode;
    notifyListeners();
  }

  void grantConsent() {
    _consentGranted = true;
    notifyListeners();
  }

  void updatePatient(PatientData data) {
    _patient = data;
    notifyListeners();
  }

  void setEncounter(String id) {
    _encounterId = id;
    notifyListeners();
  }

  void setInterview(String id) {
    _interviewId = id;
    notifyListeners();
  }

  void setVoiceState(VoiceState state) {
    _voiceState = state;
    notifyListeners();
  }

  void setTranscript(String text) {
    _transcript = text;
    notifyListeners();
  }

  void setAudioDuration(int sec) {
    _audioDurationSeconds = sec;
    notifyListeners();
  }

  void addFindings(List<ClinicalFinding> newFindings) {
    _findings.addAll(newFindings);
    notifyListeners();
  }

  void updateFinding(int index, String newValue) {
    if (index >= 0 && index < _findings.length) {
      _findings[index].value = newValue;
      _findings[index].source = 'physician_confirmed';
      _findings[index].needsReview = false;
      notifyListeners();
    }
  }

  void clearFindings() {
    _findings.clear();
    notifyListeners();
  }

  void addRedFlags(List<RedFlagInfo> flags) {
    _redFlags.addAll(flags);
    notifyListeners();
  }

  void clearRedFlags() {
    _redFlags.clear();
    notifyListeners();
  }

  void setCurrentQuestion(String? q, int index) {
    _currentQuestion = q;
    _questionIndex = index;
    notifyListeners();
  }

  void togglePastCondition(String condition) {
    if (_pastConditions.contains(condition)) {
      _pastConditions.remove(condition);
    } else {
      _pastConditions.add(condition);
    }
    notifyListeners();
  }

  void addPastCondition(String condition) {
    if (condition.trim().isNotEmpty) {
      _pastConditions.add(condition.trim());
      notifyListeners();
    }
  }

  void clearPastConditions() {
    _pastConditions.clear();
    notifyListeners();
  }

  void setMedications(List<String> meds) {
    _currentMedications.clear();
    _currentMedications.addAll(meds.where((m) => m.trim().isNotEmpty));
    notifyListeners();
  }

  void setAllergies(List<String> algs) {
    _allergies.clear();
    _allergies.addAll(algs.where((a) => a.trim().isNotEmpty));
    notifyListeners();
  }

  void setDocumentExtractions({
    required String filename,
    required String ocrText,
    required List<Map<String, dynamic>> extractions,
  }) {
    _uploadedDocumentName = filename;
    _uploadedDocumentOcrText = ocrText;
    _documentExtractions.clear();
    _documentExtractions.addAll(extractions);
    notifyListeners();
  }

  void addDocumentExtraction(Map<String, dynamic> item) {
    _documentExtractions.add(item);
    notifyListeners();
  }

  void updateDocumentExtraction(int index, String value, String status) {
    if (index >= 0 && index < _documentExtractions.length) {
      _documentExtractions[index]['value'] = value;
      _documentExtractions[index]['status'] = status;
      notifyListeners();
    }
  }

  void setPrakritiAnswer(String questionKey, String dosha) {
    _prakritiAnswers[questionKey] = dosha;
    notifyListeners();
  }

  (String, Map<String, int>) calculatePrakritiBaseline() {
    int vata = 0;
    int pitta = 0;
    int kapha = 0;

    for (var val in _prakritiAnswers.values) {
      if (val.toLowerCase().contains('vata')) vata++;
      if (val.toLowerCase().contains('pitta')) pitta++;
      if (val.toLowerCase().contains('kapha')) kapha++;
    }

    int total = vata + pitta + kapha;
    if (total == 0) {
      return ('Not Assessed', {'Pitta': 0, 'Vata': 0, 'Kapha': 0});
    }

    int vPct = ((vata / total) * 100).round();
    int pPct = ((pitta / total) * 100).round();
    int kPct = 100 - (vPct + pPct);

    final counts = [
      ('Pitta', pitta, pPct),
      ('Vata', vata, vPct),
      ('Kapha', kapha, kPct),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    final primaryDosha = counts[0];
    final secondaryDosha = counts[1];

    String primary = primaryDosha.$1;
    if (secondaryDosha.$2 > 0 && secondaryDosha.$2 >= (primaryDosha.$2 * 0.6).round()) {
      primary = '${primaryDosha.$1}–${secondaryDosha.$1}';
    }

    return (primary, {'Pitta': pPct, 'Vata': vPct, 'Kapha': kPct});
  }

  /// Clears all intake state so a second patient starts completely fresh
  void resetForNewPatient() {
    _patient = PatientData();
    _encounterId = null;
    _interviewId = null;
    _voiceState = VoiceState.idle;
    _transcript = '';
    _audioDurationSeconds = 38;
    _findings.clear();
    _redFlags.clear();
    _currentQuestion = null;
    _questionIndex = 0;
    _consentGranted = false;
    _pastConditions.clear();
    _currentMedications.clear();
    _allergies.clear();
    _documentExtractions.clear();
    _uploadedDocumentName = null;
    _uploadedDocumentOcrText = null;
    _prakritiAnswers.clear();
    _syncState = SyncState.synced;
    notifyListeners();
  }

  void setSyncState(SyncState state) {
    _syncState = state;
    notifyListeners();
  }

  String get languageCode {
    switch (_language) {
      case Language.hindi:
        return 'hi';
      case Language.marathi:
        return 'mr';
      case Language.tamil:
        return 'ta';
      case Language.telugu:
        return 'te';
      case Language.bengali:
        return 'bn';
      case Language.english:
        return 'en';
    }
  }

  bool get isHindi => _language == Language.hindi;

  String tr(String en, String hi) => isHindi ? hi : en;
}
