// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  static const _headers = {'Content-Type': 'application/json'};

  // ── Grúas ──────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTowRequests({String? status}) async {
    final uri = Uri.parse(status != null
        ? '$kTowEndpoint?status=$status&limit=100'
        : '$kTowEndpoint?limit=100');
    final res = await http.get(uri, headers: _headers);
    _checkStatus(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> updateTowStatus(
      int id, String status, {String adminNotes = ''}) async {
    final res = await http.patch(
      Uri.parse('$kTowEndpoint/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status, 'admin_notes': adminNotes}),
    );
    _checkStatus(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ── Reservas de servicio ───────────────────────────────

  static Future<List<Map<String, dynamic>>> getBookings({String? status}) async {
    final uri = Uri.parse(status != null
        ? '$kBookingsEndpoint?status=$status&limit=100'
        : '$kBookingsEndpoint?limit=100');
    final res = await http.get(uri, headers: _headers);
    _checkStatus(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> updateBookingStatus(
      int id, String status, {String adminNotes = ''}) async {
    final res = await http.patch(
      Uri.parse('$kBookingsEndpoint/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status, 'admin_notes': adminNotes}),
    );
    _checkStatus(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ── Órdenes de productos ───────────────────────────────

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final res = await http.get(Uri.parse(kOrdersEndpoint), headers: _headers);
    _checkStatus(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  // ── Cotizaciones ───────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getQuotes() async {
    final res = await http.get(Uri.parse(kQuotesEndpoint), headers: _headers);
    _checkStatus(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  // ── FCM token ─────────────────────────────────────────

  static Future<void> registerFcmToken(String token) async {
    await http.post(
      Uri.parse(kRegisterToken),
      headers: _headers,
      body: jsonEncode({'token': token, 'device_label': 'Safe Car Admin APK'}),
    );
  }

  // ── Helper ────────────────────────────────────────────

  static void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
