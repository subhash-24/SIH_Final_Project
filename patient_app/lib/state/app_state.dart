/// Arogya-Saathi — App State (Provider)
import 'package:flutter/foundation.dart';

enum Language { hindi, english, telugu, tamil, bengali }

enum VoiceState { idle, listening, processing, success, error }

enum SyncState { offline, pending, syncing, synced, failed }

class PatientData {
  String? name;
  String? age;
  String? gender;
  String? mobile;
  String? abhaNumber;
  String? preferredLanguage;
}

class ClinicalFinding {
  final String fieldType;
  final String value;
  final String source;
  final bool needsReview;

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

  // Patient
  PatientData _patient = PatientData();
  PatientData get patient => _patient;

  // Encounter
  String? _encounterId;
  String? get encounterId => _encounterId;

  String? _interviewId;
  String? get interviewId => _interviewId;

  // Voice
  VoiceState _voiceState = VoiceState.idle;
  VoiceState get voiceState => _voiceState;

  String _transcript = '';
  String get transcript => _transcript;

  // Clinical findings
  List<ClinicalFinding> _findings = [];
  List<ClinicalFinding> get findings => _findings;

  // Red flags
  List<RedFlagInfo> _redFlags = [];
  List<RedFlagInfo> get redFlags => _redFlags;
  bool get hasUrgentRedFlag => _redFlags.any((r) => r.severity == 'urgent');

  // Current question
  String? _currentQuestion;
  String? get currentQuestion => _currentQuestion;
  int _questionIndex = 0;
  int get questionIndex => _questionIndex;

  // Consent
  bool _consentGranted = false;
  bool get consentGranted => _consentGranted;

  // AYUSH answers
  Map<String, String> _prakritiAnswers = {};
  Map<String, String> get prakritiAnswers => _prakritiAnswers;

  // Sync
  SyncState _syncState = SyncState.synced;
  SyncState get syncState => _syncState;

  // ─────────────────────────────────────────────────────────────

  void setLanguage(Language lang) {
    _language = lang;
    _patient.preferredLanguage = lang == Language.hindi ? 'hi' :
                                  lang == Language.telugu ? 'te' :
                                  lang == Language.tamil ? 'ta' :
                                  lang == Language.bengali ? 'bn' : 'en';
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

  void addFindings(List<ClinicalFinding> newFindings) {
    _findings.addAll(newFindings);
    notifyListeners();
  }

  void addRedFlags(List<RedFlagInfo> flags) {
    _redFlags.addAll(flags);
    notifyListeners();
  }

  void setCurrentQuestion(String? q, int index) {
    _currentQuestion = q;
    _questionIndex = index;
    notifyListeners();
  }

  void setPrakritiAnswer(String questionId, String dosha) {
    _prakritiAnswers[questionId] = dosha;
    notifyListeners();
  }

  void setSyncState(SyncState state) {
    _syncState = state;
    notifyListeners();
  }

  String get languageCode {
    switch (_language) {
      case Language.hindi: return 'hi';
      case Language.telugu: return 'te';
      case Language.tamil: return 'ta';
      case Language.bengali: return 'bn';
      case Language.english: return 'en';
    }
  }

  bool get isHindi => _language == Language.hindi;

  String tr(String en, String hi) => isHindi ? hi : en;
}
