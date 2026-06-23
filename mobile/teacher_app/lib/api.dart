import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ManasetyApi {
  static const String base = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:5050/api', // Android emulator → host
  );

  static String? _token;

  static Future<void> _loadToken() async {
    if (_token != null) return;
    final p = await SharedPreferences.getInstance();
    _token = p.getString('token');
  }

  static Future<void> setToken(String token) async {
    _token = token;
    (await SharedPreferences.getInstance()).setString('token', token);
  }

  static Future<void> logout() async {
    _token = null;
    (await SharedPreferences.getInstance()).remove('token');
  }

  static Map<String, String> _headers({bool json = false}) {
    return {
      if (_token != null) 'Authorization': 'Bearer $_token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, dynamic>> login(String u, String p) async {
    final r = await http.post(Uri.parse('$base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': u, 'password': p}));
    if (r.statusCode != 200) {
      throw Exception('فشل تسجيل الدخول (${r.statusCode})');
    }
    final data = jsonDecode(r.body);
    await setToken(data['token']);
    return data['user'];
  }

  static Future<dynamic> get(String path) async {
    await _loadToken();
    final r = await http.get(Uri.parse('$base$path'), headers: _headers());
    if (r.statusCode == 401) throw Exception('انتهت الجلسة');
    if (r.statusCode >= 400) throw Exception('خطأ ${r.statusCode}');
    return jsonDecode(r.body);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    await _loadToken();
    final r = await http.post(Uri.parse('$base$path'),
        headers: _headers(json: true), body: jsonEncode(body));
    if (r.statusCode == 401) throw Exception('انتهت الجلسة');
    if (r.statusCode >= 400) throw Exception('خطأ ${r.statusCode}: ${r.body}');
    return jsonDecode(r.body);
  }
}
