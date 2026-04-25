import 'package:flutter/material.dart';
import 'app.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const CineArtApp());
}