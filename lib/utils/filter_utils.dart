// lib/utils/filter_utils.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

Future<Uint8List?> applyFilterAlgorithm(Map<String, dynamic> data) async {
  String path = data['path'];
  String filterType = data['filter'];
  String ratioStr = data['ratio']; 
  bool isFrontCamera = data['isFrontCamera'] ?? false;
  bool saveAsPreview = data['saveAsPreview'] ?? true;
  Uint8List? lutBytes = data['lutBytes'];
  double iconTurns = data['iconTurns'] ?? 0.0;

  final bytes = await File(path).readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) return null;

  image = img.bakeOrientation(image);

  double targetRatio;
  if (ratioStr == '1:1') {
    targetRatio = 1.0;
  } else {
    final parts = ratioStr.split(':');
    int widthPart = int.parse(parts[0]);
    int heightPart = int.parse(parts[1]);
    targetRatio = widthPart / heightPart;
  }

  double currentRatio = image.width / image.height;
  int targetWidth = image.width;
  int targetHeight = image.height;

  if ((currentRatio - targetRatio).abs() > 0.01) {
    targetWidth = (image.height * targetRatio).round(); 
    int x = (image.width - targetWidth) ~/ 2; 
    int y = (image.height - targetHeight) ~/ 2; 
    image = img.copyCrop(image, x: x, y: y, width: targetWidth, height: targetHeight);
  }

  if (iconTurns == 0.25) { 
    image = img.copyRotate(image, angle: 90); 
  } else if (iconTurns == -0.25) { 
    image = img.copyRotate(image, angle: 270); 
  }

  if (filterType == 'Siyah Beyaz') {
    img.grayscale(image);
  } else if (filterType == 'Cinematic' && lutBytes != null) {
    img.Image? lutImage = img.decodeImage(lutBytes);
    if (lutImage != null) {
      for (var frame in image.frames) {
        for (var pixel in frame) {
          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();

          double bluePos = b / 255.0 * 63.0;
          int quad1 = bluePos.floor();
          int quad2 = bluePos.ceil();

          double rPos = r / 255.0 * 63.0;
          double gPos = g / 255.0 * 63.0;

          int x1 = (quad1 % 8) * 64 + rPos.round();
          int y1 = (quad1 ~/ 8) * 64 + gPos.round();

          var newColor = lutImage.getPixel(x1, y1);

          pixel.r = newColor.r;
          pixel.g = newColor.g;
          pixel.b = newColor.b;
        }
      }
    }
  }

  if (isFrontCamera && saveAsPreview) {
    image = img.flipHorizontal(image);
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}