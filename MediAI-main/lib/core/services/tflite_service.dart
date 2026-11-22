import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../features/data/models/skin_analysis_model.dart';
import 'image_quality_gate.dart';

class ImagePreprocessResult {
  final bool passesStage1;
  final bool passesSkinCheck;
  final double skinRatio;
  final Float32List? buffer;
  final QualityGateResult? qualityGate;

  const ImagePreprocessResult({
    required this.passesSkinCheck,
    required this.skinRatio,
    this.buffer,
    this.qualityGate,
    this.passesStage1 = false,
  });
}

class TfliteService {
  static const String modelAssetPath = 'assets/models/skin_model.tflite';
  static const String labelsAssetPath = 'assets/models/labels.txt';

  static const int inputWidth = 300;
  static const int inputHeight = 300;
  static const int inputChannels = 3;
  static const int expectedClassCount = 24;

  static final TfliteService _instance = TfliteService._internal();
  factory TfliteService() => _instance;
  TfliteService._internal();

  Interpreter? _interpreter;
  List<String>? _labels;
  Uint8List? _cachedModelBytes;
  bool _isInitializing = false;
  int? _lastInferenceLatencyMs;

  bool get isReady => _interpreter != null;
  int? get lastInferenceLatencyMs => _lastInferenceLatencyMs;

  Future<List<String>> loadLabels() async {
    if (_labels != null && _labels!.isNotEmpty) return _labels!;
    try {
      final rawText = await rootBundle.loadString(labelsAssetPath);
      _labels = rawText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      return _labels!;
    } catch (e) {
      debugPrint('TfliteService: Error loading labels from $labelsAssetPath: $e');
      return [];
    }
  }

  Future<Uint8List> getModelBytes() async {
    if (_cachedModelBytes != null) return _cachedModelBytes!;
    final byteData = await rootBundle.load(modelAssetPath);
    _cachedModelBytes = byteData.buffer.asUint8List();
    return _cachedModelBytes!;
  }

  Future<void> initialize({Uint8List? modelBytes}) async {
    if (_interpreter != null) return;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;
    try {
      await loadLabels();
      final options = InterpreterOptions()..threads = 4;

      try {
        if (modelBytes != null) {
          _interpreter = Interpreter.fromBuffer(modelBytes, options: options);
        } else {
          _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);
        }
        debugPrint('TfliteService: Persistent CPU interpreter successfully initialized (threads = 4).');
      } catch (assetError) {
        debugPrint('TfliteService: Interpreter.fromAsset fallback to rootBundle buffer: $assetError');
        final bytes = modelBytes ?? await getModelBytes();
        _interpreter = Interpreter.fromBuffer(bytes, options: options);
        debugPrint('TfliteService: Buffer-based CPU interpreter successfully initialized.');
      }
    } catch (e) {
      debugPrint('TfliteService: Failed to initialize TFLite interpreter: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  static bool isDeterministicSkinPixel(int r, int g, int b) =>
      ImageQualityGate.isDeterministicSkinPixel(r, g, b);

  static double computeDeterministicSkinRatio(img.Image image) =>
      ImageQualityGate.computeDeterministicSkinRatio(image);

  static bool isHumanSkinChromaticity(int rInt, int gInt, int bInt) {
    if (ImageQualityGate.isDeterministicSkinPixel(rInt, gInt, bInt)) {
      return true;
    }
    return ImageQualityGate.isFitzpatrickSkinChromaticity(rInt, gInt, bInt);
  }

  static double computeSkinChromaticityRatio(img.Image image) =>
      computeDeterministicSkinRatio(image);

  static ImagePreprocessResult preprocessAndScreenImageBytes(Uint8List imageBytes) {
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode image format.');
    }
    debugPrint(
      'TfliteService loaded input image: ${decodedImage.width}x${decodedImage.height}',
    );

    final qualityGate = ImageQualityGate.evaluateImage(decodedImage);
    final double rawSkinRatio = computeDeterministicSkinRatio(decodedImage);
    final double skinRatio = math.max(rawSkinRatio, qualityGate.skinRatio);
    final bool passesSkin = qualityGate.passesSkinDetection;

    final bool passesStage1 = !qualityGate.isBlurry &&
        !qualityGate.isUnderexposed &&
        !qualityGate.isOverexposed &&
        passesSkin;

    if (!passesStage1) {
      debugPrint(
        'TfliteService Pre-check Rejected: blur=${qualityGate.isBlurry}, under=${qualityGate.isUnderexposed}, over=${qualityGate.isOverexposed}, foliage=${qualityGate.isOverwhelmingFoliage}, mono=${qualityGate.isMonochromeSynthetic}, cool=${qualityGate.isCoolToneVehicleScene}',
      );
      return ImagePreprocessResult(
        passesStage1: false,
        passesSkinCheck: passesSkin,
        skinRatio: skinRatio,
        buffer: null,
        qualityGate: qualityGate,
      );
    }

    final img.Image resized = _cropAndResizeSquare(decodedImage);
    final Float32List buffer = _buildTensorBuffer(resized);

    debugPrint(
      'TfliteService isolate prepared tensor buffer: ${resized.width}x${resized.height} (300x300, channels: $inputChannels, buffer length: ${buffer.length}, stage1: $passesStage1, skinRatio: ${(skinRatio * 100).toStringAsFixed(1)}%)',
    );

    return ImagePreprocessResult(
      passesStage1: passesStage1,
      passesSkinCheck: true,
      skinRatio: skinRatio,
      buffer: buffer,
      qualityGate: qualityGate,
    );
  }

  static img.Image _cropAndResizeSquare(img.Image decoded) {
    final int shortestSide = math.min(decoded.width, decoded.height);
    final int cropX = (decoded.width - shortestSide) ~/ 2;
    final int cropY = (decoded.height - shortestSide) ~/ 2;

    final img.Image squareCropped = (decoded.width == decoded.height)
        ? decoded
        : img.copyCrop(
            decoded,
            x: cropX,
            y: cropY,
            width: shortestSide,
            height: shortestSide,
          );

    return img.copyResize(
      squareCropped,
      width: inputWidth,
      height: inputHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  static Float32List _buildTensorBuffer(img.Image resized) {
    final Float32List buffer = Float32List(inputWidth * inputHeight * inputChannels);
    int bufferIdx = 0;
    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[bufferIdx++] = pixel.r.toDouble();
        buffer[bufferIdx++] = pixel.g.toDouble();
        buffer[bufferIdx++] = pixel.b.toDouble();
      }
    }
    return buffer;
  }

  static Float32List preprocessImageBytes(Uint8List imageBytes) {
    final result = preprocessAndScreenImageBytes(imageBytes);
    if (result.buffer != null) {
      return result.buffer!;
    }
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) throw Exception('Failed to decode image format.');
    final resized = _cropAndResizeSquare(decodedImage);
    return _buildTensorBuffer(resized);
  }

  static Future<ImagePreprocessResult> preprocessImageInIsolate(String imagePath) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('Lesion image not found at path: $imagePath');
    }
    final rawBytes = await imageFile.readAsBytes();
    return await Isolate.run(() => preprocessAndScreenImageBytes(rawBytes));
  }

  Future<SkinAnalysisModel> classifyImage(String imagePath) =>
      runInference(imagePath: imagePath);

  Future<SkinAnalysisModel> runInference({
    required String imagePath,
    Uint8List? imageBytes,
    Uint8List? modelBytes,
    List<String>? labels,
  }) async {
    debugPrint("Inference Input Path: $imagePath");
    final activeLabels = labels ?? _labels ?? await loadLabels();

    final ImagePreprocessResult prep;
    if (imageBytes != null) {
      prep = await Isolate.run(() => preprocessAndScreenImageBytes(imageBytes));
    } else {
      prep = await preprocessImageInIsolate(imagePath);
    }

    if (!prep.passesStage1 || prep.buffer == null) {
      debugPrint(
        'TfliteService Stage 1 Gate Failed: blur=${prep.qualityGate?.isBlurry}, under=${prep.qualityGate?.isUnderexposed}, over=${prep.qualityGate?.isOverexposed}, foliage=${prep.qualityGate?.isOverwhelmingFoliage}. Terminating pipeline immediately.',
      );
      return SkinAnalysisModel.universalInconclusive(
        imagePath: imagePath,
        confidence: 0.0,
        labels: activeLabels,
        customExplanation: prep.qualityGate?.rejectionReasonEn ??
            'The system could not detect valid human skin. Electronics, dark gadgets, and synthetic objects are rejected.',
        customInstructionEn: prep.qualityGate?.rejectionReasonEn ??
            'The system could not detect valid human skin. Electronics, dark gadgets, and synthetic objects are rejected.',
        customInstructionUr: prep.qualityGate?.rejectionReasonUr ??
            'سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ الیکٹرانکس، سیاہ آلات اور مصنوعی اشیاء مسترد کی جاتی ہیں۔',
      );
    }

    if (_interpreter == null) {
      await initialize(modelBytes: modelBytes);
    }

    final input = prep.buffer!.reshape([1, inputWidth, inputHeight, inputChannels]);
    final int outputClasses = activeLabels.isNotEmpty ? activeLabels.length : expectedClassCount;
    final output = List.generate(
      1,
      (_) => List<double>.filled(outputClasses, 0.0),
    );

    final stopwatch = Stopwatch()..start();
    _interpreter!.run(input, output);
    stopwatch.stop();
    _lastInferenceLatencyMs = stopwatch.elapsedMilliseconds;
    debugPrint(
      'MediAI Edge-AI [DermaPulse INT8]: Local inference latency = ${_lastInferenceLatencyMs}ms (target <90ms latency benchmark)',
    );

    final List<double> rawScores = List<double>.from(output[0]);

    return SkinAnalysisModel.fromInference(
      probabilities: rawScores,
      labels: activeLabels,
      imagePath: imagePath,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
