import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:stillscout/stillscout/services/face_quality_detector.dart';
import 'package:stillscout/stillscout/services/stillscout_auto_polish.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('stillscout_polish_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('polishImage adjusts pixels without changing dimensions', () {
    final flat = img.Image(width: 64, height: 64);
    img.fill(flat, color: img.ColorRgb8(90, 100, 110));

    final polished = StillScoutAutoPolish.polishImage(flat);

    expect(polished.width, 64);
    expect(polished.height, 64);

    final before = flat.getPixel(32, 32);
    final after = polished.getPixel(32, 32);
    expect(after.r != before.r || after.g != before.g || after.b != before.b, isTrue);
  });

  test('face-weighted polish brightens the portrait region', () {
    final image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgb8(80, 80, 80));
    img.fillRect(
      image,
      x1: 35,
      y1: 25,
      x2: 65,
      y2: 75,
      color: img.ColorRgb8(70, 75, 80),
    );

    const face = NormalizedFaceBounds(
      left: 0.35,
      top: 0.25,
      right: 0.65,
      bottom: 0.75,
    );

    final polished = StillScoutAutoPolish.polishImage(image, face: face);
    final centerBefore = image.getPixel(50, 50);
    final centerAfter = polished.getPixel(50, 50);
    final cornerAfter = polished.getPixel(5, 5);

    expect(centerAfter.r, greaterThan(centerBefore.r));
    expect(centerAfter.r - cornerAfter.r, greaterThan(0));
  });

  test('encodePolishedJpeg returns non-empty bytes', () {
    final image = img.Image(width: 32, height: 32);
    img.fill(image, color: img.ColorRgb8(120, 130, 140));

    final bytes = StillScoutAutoPolish.encodePolishedJpeg(image);
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(100));
  });
}
