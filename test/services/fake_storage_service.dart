
import 'package:cineart/services/storage_service.dart';

class FakeStorageService implements StorageService {
  final Map<String, String> _store = {};

  @override
  String? getItem(String key) => _store[key];
  @override
  void setItem(String key, String value) => _store[key] = value;

  @override
  void remove(String key) => _store.remove(key);

  @override
  Future<void> init() async {}

  void clear() => _store.clear();
}