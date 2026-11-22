import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final DateTime createdAt;

  const LocalAuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'Patient',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocalAuthUser.fromJson(Map<String, dynamic> json) => LocalAuthUser(
        id: json['id'] as String? ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        role: json['role'] as String? ?? 'Patient',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class AuthService {
  AuthService._();

  static const String _usersKey = 'mediai_local_users';
  static const String _currentUserKey = 'mediai_active_user';
  static const String _passwordsKey = 'mediai_user_passwords';

  static final ValueNotifier<LocalAuthUser?> currentUser =
      ValueNotifier<LocalAuthUser?>(null);

  static bool get isAuthenticated => currentUser.value != null;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null && userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        currentUser.value = LocalAuthUser.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[AuthService] Init error: $e');
    }
  }

  static Future<({bool success, String? message, LocalAuthUser? user})>
      register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'Patient',
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = name.trim();

      if (cleanName.isEmpty) {
        return (success: false, message: 'Please enter your full name.', user: null);
      }
      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        return (
          success: false,
          message: 'Please enter a valid email address.',
          user: null
        );
      }
      if (password.trim().length < 6) {
        return (
          success: false,
          message: 'Password must be at least 6 characters long.',
          user: null
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final usersMap = _getStoredMap(prefs, _usersKey);
      final passwordsMap = _getStoredMap(prefs, _passwordsKey);

      if (usersMap.containsKey(cleanEmail)) {
        return (
          success: false,
          message: 'An account with this email already exists. Please login.',
          user: null
        );
      }

      final newUser = LocalAuthUser(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        email: cleanEmail,
        phone: phone?.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      usersMap[cleanEmail] = jsonEncode(newUser.toJson());
      passwordsMap[cleanEmail] = password.trim();

      await prefs.setString(_usersKey, jsonEncode(usersMap));
      await prefs.setString(_passwordsKey, jsonEncode(passwordsMap));
      await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));

      currentUser.value = newUser;

      return (success: true, message: null, user: newUser);
    } catch (e) {
      return (
        success: false,
        message: 'Registration failed: ${e.toString()}',
        user: null
      );
    }
  }

  static Future<({bool success, String? message, LocalAuthUser? user})>
      login({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPass = password.trim();

      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        return (
          success: false,
          message: 'Please enter a valid email address.',
          user: null
        );
      }
      if (cleanPass.isEmpty) {
        return (
          success: false,
          message: 'Please enter your password.',
          user: null
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final usersMap = _getStoredMap(prefs, _usersKey);
      final passwordsMap = _getStoredMap(prefs, _passwordsKey);

      if (usersMap.isEmpty) {
        final demoUser = LocalAuthUser(
          id: 'demo_user_01',
          name: 'Dr. / Patient Demo',
          email: 'user@mediai.org',
          role: 'Patient',
          createdAt: DateTime.now(),
        );
        usersMap['user@mediai.org'] = jsonEncode(demoUser.toJson());
        passwordsMap['user@mediai.org'] = '123456';
        await prefs.setString(_usersKey, jsonEncode(usersMap));
        await prefs.setString(_passwordsKey, jsonEncode(passwordsMap));
      }

      if (!usersMap.containsKey(cleanEmail)) {
        return (
          success: false,
          message: 'No account found with this email. Please sign up.',
          user: null
        );
      }

      final storedPassword = passwordsMap[cleanEmail];
      if (storedPassword != cleanPass) {
        return (
          success: false,
          message: 'Incorrect password. Please verify and try again.',
          user: null
        );
      }

      final userJson = usersMap[cleanEmail];
      final decoded = jsonDecode(userJson!) as Map<String, dynamic>;
      final user = LocalAuthUser.fromJson(decoded);

      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
      currentUser.value = user;

      return (success: true, message: null, user: user);
    } catch (e) {
      return (
        success: false,
        message: 'Login failed: ${e.toString()}',
        user: null
      );
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      currentUser.value = null;
    } catch (e) {
      debugPrint('[AuthService] Logout error: $e');
    }
  }

  static Map<String, String> _getStoredMap(
      SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return <String, String>{};
    }
  }
}
