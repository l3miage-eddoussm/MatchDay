import 'package:localstorage/localstorage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  Future<void> init() async {
    await initLocalStorage();
  }

  void setItem(String key, String value) {
    localStorage.setItem(key, value);
  }

  String? getItem(String key) {
    return localStorage.getItem(key);
  }

  void remove(String key) {
    localStorage.removeItem(key);
  }
}