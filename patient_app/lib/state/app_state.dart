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

  // AYUSH Prakriti Answers
  final Map<String, String> _prakritiAnswers = {
    'digestion': 'pitta',
    'sleep': 'vata',
    'frame': 'pitta',
    'weather': 'vata',
  };
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
      return ('Pitta–Vata', {'Pitta': 52, 'Vata': 33, 'Kapha': 15});
    }

    int vPct = ((vata / total) * 100).round();
    int pPct = ((pitta / total) * 100).round();
    int kPct = 100 - (vPct + pPct);

    String primary = 'Pitta–Vata';
    if (pPct >= vPct && pPct >= kPct) {
      primary = vPct >= kPct ? 'Pitta–Vata' : 'Pitta–Kapha';
    } else if (vPct >= pPct && vPct >= kPct) {
      primary = pPct >= kPct ? 'Vata–Pitta' : 'Vata–Kapha';
    } else {
      primary = pPct >= vPct ? 'Kapha–Pitta' : 'Kapha–Vata';
    }

    return (primary, {'Pitta': pPct, 'Vata': vPct, 'Kapha': kPct});
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
