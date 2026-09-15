/// Arogya-Saathi — API Service (Patient App)
import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'http://localhost:8000/api/v1';

class ApiService {
  static const _headers = {'Content-Type': 'application/json'};

  /// Create encounter
  static Future<Map<String, dynamic>> createEncounter({
    required String patientId,
    String? chiefComplaint,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/encounters'),
      headers: _headers,
      body: jsonEncode({
        'patient_id': patientId,
        'chief_complaint': chiefComplaint,
      }),
    );
    return _parse(res);
  }

  /// Create patient
  static Future<Map<String, dynamic>> createPatient({
    required String name,
    String? age,
    String? gender,
    String? mobile,
    String? abhaNumber,
    String language = 'en',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/patients'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'age': age,
        'gender': gender,
        'mobile': mobile,
        'abha_number': abhaNumber,
        'preferred_language': language,
      }),
    );
    return _parse(res);
  }

  /// Start interview
  static Future<Map<String, dynamic>> startInterview({
    required String encounterId,
    String language = 'en',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/interviews/start'),
      headers: _headers,
      body: jsonEncode({
        'encounter_id': encounterId,
        'language': language,
      }),
    );
    return _parse(res);
  }

  /// Submit actual audio recording
  static Future<Map<String, dynamic>> submitAudioFile({
    required String interviewId,
    required List<int> audioBytes,
    required String language,
    String filename = 'audio.webm',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/interviews/$interviewId/audio'),
    );
    request.fields['language'] = language;
    request.files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: filename));

    final res = await request.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw Exception('API error ${res.statusCode}: $body');
  }

  /// Submit typed symptoms text for Gemini extraction
  static Future<Map<String, dynamic>> submitTextSymptoms({
    required String interviewId,
    required String text,
    String language = 'en',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/interviews/$interviewId/text'),
      headers: _headers,
      body: jsonEncode({
        'text': text,
        'language': language,
      }),
    );
    return _parse(res);
  }

  /// Upload Document
  static Future<Map<String, dynamic>> uploadDocument({
    required String encounterId,
    required List<int> fileBytes,
    String filename = 'document.jpg',
    String docType = 'prescription',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/documents/upload'),
    );
    request.fields['encounter_id'] = encounterId;
    request.fields['document_type'] = docType;
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: filename));

    final res = await request.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw Exception('API error ${res.statusCode}: $body');
  }

  /// Complete interview
  static Future<void> completeInterview(String interviewId) async {
    await http.post(
      Uri.parse('$_baseUrl/interviews/$interviewId/complete'),
      headers: _headers,
    );
  }

  /// Submit encounter (to physician queue)
  static Future<void> submitEncounter(String encounterId) async {
    await http.put(
      Uri.parse('$_baseUrl/encounters/$encounterId/submit'),
      headers: _headers,
    );
  }

  /// Submit AYUSH Prakriti
  static Future<Map<String, dynamic>> submitPrakriti({
    required String encounterId,
    required Map<String, String> answers,
    String? ahara,
    String? vihara,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/ayush/prakriti'),
      headers: _headers,
      body: jsonEncode({
        'encounter_id': encounterId,
        'answers': answers,
        'ahara': ahara,
        'vihara': vihara,
      }),
    );
    return _parse(res);
  }

  /// Get Prakriti questions
  static Future<List<dynamic>> getPrakritiQuestions() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/ayush/questions/prakriti'),
    );
    final data = _parse(res);
    return data['questions'] as List<dynamic>;
  }

  static Map<String, dynamic> _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }
}
