import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyMemberId = 'member_id';
  static const String _keyDisplayName = 'display_name';
  static const String _keyAvatar = 'avatar';
  static const String _keyColor = 'color';
  static const String _keyLastTripCode = 'last_trip_code';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    if (_prefs == null) throw Exception('StorageService not initialized');
    return _prefs!;
  }

  // Member ID — persisted across sessions so the same device can rejoin
  static String? getMemberId() => _p.getString(_keyMemberId);
  static Future<void> setMemberId(String id) => _p.setString(_keyMemberId, id);

  // Display preferences
  static String? getDisplayName() => _p.getString(_keyDisplayName);
  static Future<void> setDisplayName(String name) => _p.setString(_keyDisplayName, name);

  static String? getAvatar() => _p.getString(_keyAvatar);
  static Future<void> setAvatar(String avatar) => _p.setString(_keyAvatar, avatar);

  static String? getColor() => _p.getString(_keyColor);
  static Future<void> setColor(String color) => _p.setString(_keyColor, color);

  // Last trip code — for quick rejoin
  static String? getLastTripCode() => _p.getString(_keyLastTripCode);
  static Future<void> setLastTripCode(String code) => _p.setString(_keyLastTripCode, code);

  static Future<void> clearTrip() async {
    await _p.remove(_keyMemberId);
    await _p.remove(_keyLastTripCode);
  }
}
