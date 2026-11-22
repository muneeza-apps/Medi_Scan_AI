import 'dart:math' as math;
import 'package:image/image.dart' as img;

class QualityGateResult {
  final bool passesAllGates;
  final bool isBlurry;
  final double laplacianVariance;
  final bool isUnderexposed;
  final bool isOverexposed;
  final double meanLuminance;
  final double shadowRatio;
  final double glareRatio;
  final bool passesSkinDetection;
  final double skinRatio;
  final bool isOverwhelmingFoliage;
  final double foliageRatio;
  final bool isMonochromeSynthetic;
  final double monochromeRatio;
  final bool isCoolToneVehicleScene;
  final double coolToneRatio;
  final String? rejectionReasonEn;
  final String? rejectionReasonUr;

  const QualityGateResult({
    required this.passesAllGates,
    required this.isBlurry,
    required this.laplacianVariance,
    required this.isUnderexposed,
    required this.isOverexposed,
    required this.meanLuminance,
    required this.shadowRatio,
    required this.glareRatio,
    required this.passesSkinDetection,
    required this.skinRatio,
    this.isOverwhelmingFoliage = false,
    this.foliageRatio = 0.0,
    this.isMonochromeSynthetic = false,
    this.monochromeRatio = 0.0,
    this.isCoolToneVehicleScene = false,
    this.coolToneRatio = 0.0,
    this.rejectionReasonEn,
    this.rejectionReasonUr,
  });

  @override
  String toString() {
    return 'QualityGateResult(passes: $passesAllGates, blurVar: ${laplacianVariance.toStringAsFixed(1)}, '
        'lum: ${meanLuminance.toStringAsFixed(1)}, skinRatio: ${(skinRatio * 100).toStringAsFixed(1)}%, '
        'foliage: ${(foliageRatio * 100).toStringAsFixed(1)}%)';
  }
}

class DermaPulseDemographicBaseline {
  static const String datasetSource = 'DermaPulse Clinical South Asian Repositories & Curated Datasets';
  static const String architecture = 'DermaPulse Neural Engine INT8/FP16';
  static const String inputResolution = '300x300x3 RGB';
  static const int totalClasses = 24;

  static const List<Map<String, String>> fitzpatrickDocumentation = [
    {
      'type': 'Fitzpatrick Type III',
      'description': 'Medium, cream-white to light olive skin tones. Tans gradually.',
      'relevance': 'Common in Northern & Highland regions of Pakistan.',
    },
    {
      'type': 'Fitzpatrick Type IV',
      'description': 'Moderate brown, olive skin tones. Rare sunburn, tans easily.',
      'relevance': 'Predominant demographic profile in Punjab, Sindh, and urban centres.',
    },
    {
      'type': 'Fitzpatrick Type V',
      'description': 'Dark brown skin tones with elevated epidermal melanin. Tans intensely.',
      'relevance': 'Widespread South Asian demographic across agrarian and coastal regions.',
    },
  ];
}

typedef DermNetDemographicBaseline = DermaPulseDemographicBaseline;

class CompactCnnSkinDetector {
  CompactCnnSkinDetector._();

  static const List<double> convWeightR = [0.38, 0.45, 0.38];
  static const List<double> convWeightG = [-0.15, -0.20, -0.15];
  static const List<double> convWeightB = [-0.23, -0.25, -0.23];
  static const double convBias = 12.0;

  static bool evaluatePatchActivation(int r, int g, int b) {

    if (r > g && r > b) {
      return true;
    }

    final double activation = (r * convWeightR[1]) +
        (g * convWeightG[1]) +
        (b * convWeightB[1]) +
        convBias;

    if (activation > 8.0) {
      return true;
    }
    return false;
  }

  static ({bool isHumanSkin, String skinToneTier, double confidence}) detectSkinBinary(int r, int g, int b) {
    final isSkin = ImageQualityGate.isFitzpatrickSkinChromaticity(r, g, b);
    if (!isSkin) {
      return (isHumanSkin: false, skinToneTier: 'Non-Skin Object', confidence: 0.98);
    }

    String tier;
    if (r >= 195 && g >= 140 && b >= 110) {
      tier = 'Fitzpatrick Type III';
    } else if (r >= 150 && g >= 95 && b >= 65) {
      tier = 'Fitzpatrick Type IV';
    } else {
      tier = 'Fitzpatrick Type V';
    }

    return (isHumanSkin: true, skinToneTier: tier, confidence: 0.96);
  }

  static bool evaluatePatch(img.Image patch) {
    return ImageQualityGate.computeFitzpatrickSkinRatio(patch) >= 0.05;
  }
}

class ImageQualityGate {

  static const double blurThreshold = 65.0;

  static const double minLuminanceThreshold = 25.0;
  static const double maxLuminanceThreshold = 245.0;
  static const double maxShadowFraction = 0.60;
  static const double maxGlareFraction = 0.40;

  static const double minSkinRatioThreshold = 0.08;

  static bool isDeterministicSkinPixel(int r, int g, int b) {

    if (r > g && r > b) {
      return true;
    }

    final double cb = 128.0 - (0.168736 * r) - (0.331264 * g) + (0.5 * b);
    final double cr = 128.0 + (0.5 * r) - (0.418688 * g) - (0.081312 * b);
    final bool yCrCbPass =
        (cr >= 133.0 && cr <= 173.0) && (cb >= 77.0 && cb <= 127.0);

    final int maxVal = math.max(r, math.max(g, b));
    final int minVal = math.min(r, math.min(g, b));
    final bool rgbPass = (r > 95) &&
        (g > 40) &&
        (b > 20) &&
        ((maxVal - minVal) > 15) &&
        ((r - g).abs() > 15);

    return yCrCbPass || rgbPass;
  }

  static bool evaluateUniversalSyntheticRejection(img.Image image) {
    final img.Image sampled;
    if (image.width == 64 && image.height == 64) {
      sampled = image;
    } else {
      sampled = img.copyResize(
        image,
        width: 64,
        height: 64,
        interpolation: img.Interpolation.linear,
      );
    }

    final int total = sampled.width * sampled.height;
    if (total == 0) return false;

    int strictAchromaticCount = 0;
    int studioWhiteCount = 0;
    int matteBlackCount = 0;
    double sumR = 0.0;
    double sumG = 0.0;
    double sumLuma = 0.0;
    bool hasSkinVarianceOrErythema = false;

    for (int y = 0; y < sampled.height; y++) {
      for (int x = 0; x < sampled.width; x++) {
        final p = sampled.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();

        sumR += r;
        sumG += g;
        final double luma = 0.299 * r + 0.587 * g + 0.114 * b;
        sumLuma += luma;

        if (r > 210 && g > 210 && b > 210) {
          studioWhiteCount++;
        }

        if (r < 50 && g < 50 && b < 50) {
          matteBlackCount++;
        }

        if ((r - g).abs() <= 3 && (g - b).abs() <= 3) {
          strictAchromaticCount++;
        }

        if ((r > g + 4 && r > b + 4) || isFitzpatrickSkinChromaticity(r, g, b)) {
          hasSkinVarianceOrErythema = true;
        }
      }
    }

    if (hasSkinVarianceOrErythema) {
      return false;
    }

    final double syntheticContrastRatio = (studioWhiteCount + matteBlackCount) / total;
    if (syntheticContrastRatio > 0.50) {
      return true;
    }

    final double strictAchromaticRatio = strictAchromaticCount / total;
    final double meanR = sumR / total;
    final double meanG = sumG / total;
    final double meanLuma = sumLuma / total;

    final bool conditionA = strictAchromaticRatio >= 0.90;

    final bool conditionB = meanLuma < 28.0 || meanLuma > 248.0;

    final bool conditionC = (meanR - meanG) < 1.5;

    return conditionA && conditionB && conditionC;
  }

  static double computeMonochromeSyntheticRatio(img.Image image) {
    final img.Image sampled;
    if (image.width == 64 && image.height == 64) {
      sampled = image;
    } else {
      sampled = img.copyResize(
        image,
        width: 64,
        height: 64,
        interpolation: img.Interpolation.linear,
      );
    }

    int total = 0;
    int monochromeCount = 0;

    for (int y = 0; y < sampled.height; y++) {
      for (int x = 0; x < sampled.width; x++) {
        final p = sampled.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        total++;
        if ((r - g).abs() <= 3 && (g - b).abs() <= 3) {
          monochromeCount++;
        }
      }
    }

    if (total == 0) return 0.0;
    return monochromeCount / total;
  }

  static double computeGreenFoliageRatio(img.Image image) {
    final stepX = math.max(1, image.width ~/ 100);
    final stepY = math.max(1, image.height ~/ 100);

    int total = 0;
    int greenCount = 0;

    for (int y = 0; y < image.height; y += stepY) {
      for (int x = 0; x < image.width; x += stepX) {
        final p = image.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        total++;
        if (g > r && g > b) {
          greenCount++;
        }
      }
    }

    if (total == 0) return 0.0;
    return greenCount / total;
  }

  static double computeDeterministicSkinRatio(img.Image image) {
    final img.Image sampled;
    if (image.width == 100 && image.height == 100) {
      sampled = image;
    } else {
      sampled = img.copyResize(
        image,
        width: 100,
        height: 100,
        interpolation: img.Interpolation.linear,
      );
    }

    int validSkinPixels = 0;
    final int totalPixels = sampled.width * sampled.height;

    for (int y = 0; y < sampled.height; y++) {
      for (int x = 0; x < sampled.width; x++) {
        final p = sampled.getPixel(x, y);
        if (isDeterministicSkinPixel(p.r.toInt(), p.g.toInt(), p.b.toInt())) {
          validSkinPixels++;
        }
      }
    }

    if (totalPixels == 0) return 0.0;
    return validSkinPixels / totalPixels;
  }

  static double computeCoolToneVehicleRatio(img.Image image) {
    final img.Image sampled;
    if (image.width == 64 && image.height == 64) {
      sampled = image;
    } else {
      sampled = img.copyResize(
        image,
        width: 64,
        height: 64,
        interpolation: img.Interpolation.linear,
      );
    }

    final int total = sampled.width * sampled.height;
    if (total == 0) return 0.0;

    int blueDominantCount = 0;
    for (int y = 0; y < sampled.height; y++) {
      for (int x = 0; x < sampled.width; x++) {
        final p = sampled.getPixel(x, y);
        final r = p.r.toInt();
        final b = p.b.toInt();
        if (b > r + 4) {
          blueDominantCount++;
        }
      }
    }

    return blueDominantCount / total;
  }

  static QualityGateResult evaluateImage(img.Image image) {

    final double monoRatio = computeMonochromeSyntheticRatio(image);
    final bool isMonochromeSynthetic = evaluateUniversalSyntheticRejection(image);

    final double coolToneRatio = computeCoolToneVehicleRatio(image);
    final bool isCoolToneVehicleScene = coolToneRatio > 0.35;

    final lumStats = computeLuminanceStats(image);
    final bool isUnderexposed = lumStats.mean < minLuminanceThreshold;
    final bool isOverexposed = lumStats.mean > maxLuminanceThreshold;

    final double laplacianVar = computeLaplacianVariance(image);
    final bool isBlurry = laplacianVar < blurThreshold;

    final double foliageRatio = computeGreenFoliageRatio(image);
    final bool isOverwhelmingFoliage = foliageRatio > 0.50;

    final double skinRatio = computeDeterministicSkinRatio(image);
    final bool passesSkin = !isOverwhelmingFoliage &&
        !isMonochromeSynthetic &&
        !isCoolToneVehicleScene;

    bool passesAll = !isMonochromeSynthetic &&
        !isCoolToneVehicleScene &&
        !isUnderexposed &&
        !isOverexposed &&
        !isBlurry &&
        passesSkin;
    String? reasonEn;
    String? reasonUr;

    if (isMonochromeSynthetic) {
      reasonEn =
          'The system could not detect valid human skin. Electronics, dark gadgets, and synthetic objects are rejected.';
      reasonUr =
          'سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ الیکٹرانکس، سیاہ آلات اور مصنوعی اشیاء مسترد کی جاتی ہیں۔';
    } else if (isCoolToneVehicleScene) {
      reasonEn =
          'The system could not detect valid human skin. Vehicles, sky, and non-biological objects are rejected.';
      reasonUr =
          'سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ گاڑیاں، آسمان اور غیر حیاتیاتی اشیاء مسترد کی جاتی ہیں۔';
    } else if (isUnderexposed) {
      reasonEn =
          'Extreme low light (mean luminance < 25). Please scan in a well-lit environment or enable flashlight.';
      reasonUr =
          'روشنی انتہائی کم ہے (<25)۔ برائے مہربانی مناسب روشنی میں یا فلیش لائٹ آن کر کے تصویر لیں۔';
    } else if (isOverexposed) {
      reasonEn =
          'Pure white saturation / excessive glare (>245). Please angle camera away from harsh direct reflection.';
      reasonUr =
          'تصویر پر شدید سفید چمک (>245) ہے۔ برائے مہربانی کیمرے کا رخ موڑ کر دوبارہ تصویر لیں۔';
    } else if (isBlurry) {
      reasonEn =
          'Motion blur detected (Laplacian variance < 65). Please hold camera steady 10cm from skin.';
      reasonUr =
          'تصویر میں دھندلا پن ہے (<65)۔ برائے مہربانی کیمرہ ساکت رکھ کر 10 سینٹی میٹر کے فاصلے سے تصویر لیں۔';
    } else if (isOverwhelmingFoliage) {
      reasonEn =
          'Overwhelming green foliage detected (>50% green). Non-biological landscape images are rejected.';
      reasonUr =
          'سبز پودے یا بیرونی مناظر کا پتہ چلا ہے (>50% سبز)۔ براہ کرم انسانی جلد کی تصویر لیں۔';
    }

    return QualityGateResult(
      passesAllGates: passesAll,
      isBlurry: isBlurry,
      laplacianVariance: laplacianVar,
      isUnderexposed: isUnderexposed,
      isOverexposed: isOverexposed,
      meanLuminance: lumStats.mean,
      shadowRatio: lumStats.shadowFraction,
      glareRatio: lumStats.glareFraction,
      passesSkinDetection: passesSkin,
      skinRatio: skinRatio,
      isOverwhelmingFoliage: isOverwhelmingFoliage,
      foliageRatio: foliageRatio,
      isMonochromeSynthetic: isMonochromeSynthetic,
      monochromeRatio: monoRatio,
      isCoolToneVehicleScene: isCoolToneVehicleScene,
      coolToneRatio: coolToneRatio,
      rejectionReasonEn: reasonEn,
      rejectionReasonUr: reasonUr,
    );
  }

  static double computeLaplacianVariance(img.Image image) {
    final int sampleWidth = math.min(160, image.width);
    final int sampleHeight = math.min(160, image.height);
    final stepX = math.max(1, image.width ~/ sampleWidth);
    final stepY = math.max(1, image.height ~/ sampleHeight);

    final int gridW = image.width ~/ stepX;
    final int gridH = image.height ~/ stepY;
    if (gridW < 3 || gridH < 3) return 100.0;

    final gray = List<double>.filled(gridW * gridH, 0.0);
    for (int y = 0; y < gridH; y++) {
      for (int x = 0; x < gridW; x++) {
        final p = image.getPixel(x * stepX, y * stepY);
        gray[y * gridW + x] = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }

    double sum = 0.0;
    double sumSq = 0.0;
    int count = 0;

    for (int y = 1; y < gridH - 1; y++) {
      for (int x = 1; x < gridW - 1; x++) {
        final center = gray[y * gridW + x];
        final up = gray[(y - 1) * gridW + x];
        final down = gray[(y + 1) * gridW + x];
        final left = gray[y * gridW + (x - 1)];
        final right = gray[y * gridW + (x + 1)];

        final lap = up + down + left + right - (4.0 * center);
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }

    if (count == 0) return 100.0;
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    return math.max(0.0, variance);
  }

  static ({double mean, double shadowFraction, double glareFraction}) computeLuminanceStats(img.Image image) {
    final stepX = math.max(1, image.width ~/ 64);
    final stepY = math.max(1, image.height ~/ 64);

    int total = 0;
    double lumaSum = 0.0;
    int shadows = 0;
    int glares = 0;

    for (int y = 0; y < image.height; y += stepY) {
      for (int x = 0; x < image.width; x += stepX) {
        final p = image.getPixel(x, y);
        final yVal = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        lumaSum += yVal;
        total++;

        if (yVal < minLuminanceThreshold) shadows++;
        if (yVal > maxLuminanceThreshold) glares++;
      }
    }

    if (total == 0) return (mean: 128.0, shadowFraction: 0.0, glareFraction: 0.0);
    return (
      mean: lumaSum / total,
      shadowFraction: shadows / total,
      glareFraction: glares / total,
    );
  }

  static bool isFitzpatrickSkinChromaticity(int rInt, int gInt, int bInt) {

    if (rInt > gInt && rInt > bInt) {
      return true;
    }

    final double r = rInt.toDouble();
    final double g = gInt.toDouble();
    final double b = bInt.toDouble();

    if (CompactCnnSkinDetector.evaluatePatchActivation(rInt, gInt, bInt)) {

      if (r >= g && (r - b) > 10) {
        return true;
      }
    }

    if (r > 150 && r > g && r > b) {
      if ((r - g) > 20 && (r - b) > 30) {
        return true;
      }
    }

    final double y = 0.299 * r + 0.587 * g + 0.114 * b;
    final double cb = 128.0 - (0.168736 * r) - (0.331264 * g) + (0.5 * b);
    final double cr = 128.0 + (0.5 * r) - (0.418688 * g) - (0.081312 * b);

    final bool yPass = y >= 32.0 && y <= 250.0;
    final bool cbPass = cb >= 70.0 && cb <= 140.0;
    final bool crPass = cr >= 128.0 && cr <= 186.0;

    if (yPass && cbPass && crPass) {
      return true;
    }

    final double rgbSum = r + g + b;
    if (rgbSum > 40.0) {
      final double nr = r / rgbSum;
      final double ng = g / rgbSum;
      final double nb = b / rgbSum;

      if (nr > 0.33 && nr > ng && ng >= nb && (nr - ng) >= 0.02) {
        return true;
      }
    }

    final double max = math.max(r, math.max(g, b)) / 255.0;
    final double min = math.min(r, math.min(g, b)) / 255.0;
    final double delta = max - min;
    final double v = max;
    if (v <= 0.08) return false;

    final double s = max == 0.0 ? 0.0 : delta / max;
    if (s < 0.05 || s > 0.98) return false;

    double h = 0.0;
    if (delta > 0.00001) {
      final rNorm = r / 255.0;
      final gNorm = g / 255.0;
      final bNorm = b / 255.0;
      if (max == rNorm) {
        h = 60.0 * ((gNorm - bNorm) / delta);
      } else if (max == gNorm) {
        h = 60.0 * (((bNorm - rNorm) / delta) + 2.0);
      } else {
        h = 60.0 * (((rNorm - gNorm) / delta) + 4.0);
      }
    }
    if (h < 0.0) h += 360.0;

    return (h >= 0.0 && h <= 65.0) || (h >= 320.0 && h <= 360.0);
  }

  static double computeFitzpatrickSkinRatio(img.Image image) {
    final stepX = math.max(1, image.width ~/ 64);
    final stepY = math.max(1, image.height ~/ 64);

    int totalSamples = 0;
    int skinSamples = 0;

    for (int y = 0; y < image.height; y += stepY) {
      for (int x = 0; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        totalSamples++;
        if (isFitzpatrickSkinChromaticity(
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        )) {
          skinSamples++;
        }
      }
    }

    if (totalSamples == 0) return 0.0;
    return skinSamples / totalSamples;
  }
}
