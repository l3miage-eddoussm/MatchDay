import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'movie_action_service.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal() : _storage = StorageService();

  final StorageService _storage;

  @visibleForTesting
  AuthService.withStorage(this._storage);

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
    final existingRaw = _storage.getItem(_usersKey);
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
    _storage.setItem(_usersKey, jsonEncode(users));
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final raw = _storage.getItem(_usersKey);
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
    _storage.setItem(_currentUserKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<User?> getCurrentUser() async {
    final raw = _storage.getItem(_currentUserKey);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw));
  }

  Future<void> logout() async {
    MovieActionService().clearUser();
    _storage.remove(_currentUserKey);
  }
}