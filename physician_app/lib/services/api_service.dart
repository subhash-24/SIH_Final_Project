import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'API Error';
      try {
        final body = jsonDecode(response.body);
        if (body['detail'] != null) {
          message = body['detail'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _handleError(res);
    return jsonDecode(res.body);
  }

  // Queue
  static Future<List<dynamic>> getQueue() async {
    final res = await http.get(Uri.parse('$baseUrl/physician/queue'), headers: await _getHeaders());
    _handleError(res);
    final data = jsonDecode(res.body);
    return data['queue'] ?? [];
  }

  // Encounters
  static Future<Map<String, dynamic>> getSummary(String encounterId) async {
    final res = await http.get(Uri.parse('$baseUrl/encounters/$encounterId/summary'), headers: await _getHeaders());
    _handleError(res);
    return jsonDecode(res.body);
  }

  // Patients
  static Future<List<dynamic>> getTimeline(String patientId) async {
    final res = await http.get(Uri.parse('$baseUrl/patients/$patientId/timeline'), headers: await _getHeaders());
    _handleError(res);
    final data = jsonDecode(res.body);
    return data['events'] ?? [];
  }

  // Red Flags
  static Future<void> acknowledgeRedFlag(String id) async {
    final res = await http.post(Uri.parse('$baseUrl/redflags/$id/acknowledge'), headers: await _getHeaders());
    _handleError(res);
  }

  // AYUSH
  static Future<Map<String, dynamic>> getAyushAssessment(String encounterId) async {
    final res = await http.get(Uri.parse('$baseUrl/ayush/$encounterId'), headers: await _getHeaders());
    _handleError(res);
    final data = jsonDecode(res.body);
    return data['assessment'] ?? data;
  }

  // Diagnosis
  static Future<List<dynamic>> searchDiagnosis(String q) async {
    final res = await http.get(Uri.parse('$baseUrl/diagnoses/search?q=$q'), headers: await _getHeaders());
    _handleError(res);
    final data = jsonDecode(res.body);
    return data['results'] ?? [];
  }

  static Future<Map<String, dynamic>> createDiagnosis(String encounterId, String text, String notes) async {
    final res = await http.post(
      Uri.parse('$baseUrl/diagnoses'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'encounter_id': encounterId,
        'diagnosis_text': text,
        'physician_notes': notes,
      }),
    );
    _handleError(res);
    return jsonDecode(res.body);
  }

  // FHIR
  static Future<Map<String, dynamic>> generateFhirBundle(String encounterId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/fhir/bundle?encounter_id=$encounterId'),
      headers: await _getHeaders(),
    );
    _handleError(res);
    return jsonDecode(res.body);
  }
}
