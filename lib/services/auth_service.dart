import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  static const String _usersKey = 'cineart_users';
  static const String _currentUserKey = 'cineart_current_user';

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final existingRaw = StorageService().getItem(_usersKey);
    final List<dynamic> users =
    existingRaw != null ? jsonDecode(existingRaw) : [];

    final alreadyExists = users.any((u) => u['email'] == email);
    if (alreadyExists) {
      throw Exception('Un compte avec cet email existe déjà.');
    }

    final newUser = User(
      firstName: firstName,
      lastName: lastName,
      email: email,
      passwordHash: _hashPassword(password),
    );

    users.add(newUser.toJson());
    StorageService().setItem(_usersKey, jsonEncode(users));
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final raw = StorageService().getItem(_usersKey);
    final List<dynamic> users = raw != null ? jsonDecode(raw) : [];

    final hash = _hashPassword(password);
    final match = users.firstWhere(
          (u) => u['email'] == email && u['passwordHash'] == hash,
      orElse: () => null,
    );

    if (match == null) {
      throw Exception('Email ou mot de passe incorrect.');
    }

    final user = User.fromJson(match);
    StorageService().setItem(_currentUserKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<User?> getCurrentUser() async {
    final raw = StorageService().getItem(_currentUserKey);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw));
  }

  Future<void> logout() async {
    StorageService().remove(_currentUserKey);
  }
}