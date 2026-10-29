import 'dart:convert';
import 'package:http/http.dart' as http;
import '../shared/models/trip_member.dart';
import 'constants.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  // ── Create Trip ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createTrip({
    required String displayName,
    required String avatar,
    required String color,
  }) async {
    final response = await http
        .post(
          Uri.parse(kApiTrips),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'display_name': displayName,
            'avatar': avatar,
            'color': color,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(_parseError(response.body));
  }

  // ── Join Trip ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> joinTrip({
    required String code,
    required String displayName,
    required String avatar,
    required String color,
    String? memberId,
  }) async {
    final body = {
      'display_name': displayName,
      'avatar': avatar,
      'color': color,
      if (memberId != null) 'member_id': memberId,
    };

    final response = await http
        .post(
          Uri.parse(kApiJoinTrip(code.toUpperCase())),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      throw ApiException('Trip not found. Check the code and try again.');
    }
    if (response.statusCode == 410) {
      throw ApiException('This trip has expired.');
    }
    throw ApiException(_parseError(response.body));
  }

  // ── Get Members ──────────────────────────────────────────────────────────

  static Future<List<TripMember>> getMembers(String code) async {
    final response = await http
        .get(Uri.parse(kApiMembers(code.toUpperCase())))
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['members'] as List;
      return list.map((m) => TripMember.fromJson(m as Map<String, dynamic>)).toList();
    }
    throw ApiException(_parseError(response.body));
  }

  // ── Leave Trip ───────────────────────────────────────────────────────────

  static Future<void> leaveTrip({
    required String code,
    required String memberId,
  }) async {
    await http
        .post(
          Uri.parse(kApiLeaveTrip(code.toUpperCase())),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'member_id': memberId}),
        )
        .timeout(_timeout);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error']?.toString() ?? data['detail']?.toString() ?? 'An error occurred.';
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
