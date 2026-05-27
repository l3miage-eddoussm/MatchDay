import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  Future<void> shareReview(
      ScreenshotController controller,
      String movieTitle,
      int movieId,
      ) async {
    final imageBytes = await controller.capture(pixelRatio: 3.0);
    if (imageBytes == null) return;
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/critique_$movieId.png');
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ma critique de "$movieTitle" sur CINEART',
    );
  }

  Future<void> shareStats(
      ScreenshotController controller,
      int year,
      ) async {
    final imageBytes = await controller.capture(pixelRatio: 3.0);
    if (imageBytes == null) return;
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/stats_$year.png');
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Mes stats ciné $year sur CINEART',
    );
  }
}