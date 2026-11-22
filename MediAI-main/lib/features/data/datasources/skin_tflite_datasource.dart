import 'dart:typed_data';

import '../../../../core/services/tflite_service.dart';
import '../models/skin_analysis_model.dart';

class SkinTfliteDatasource {
  static const String modelAssetPath = TfliteService.modelAssetPath;
  static const String labelsAssetPath = TfliteService.labelsAssetPath;

  static const int inputWidth = TfliteService.inputWidth;
  static const int inputHeight = TfliteService.inputHeight;
  static const int inputChannels = TfliteService.inputChannels;
  static const int expectedClassCount = TfliteService.expectedClassCount;

  final TfliteService _tfliteService;

  SkinTfliteDatasource({TfliteService? tfliteService})
      : _tfliteService = tfliteService ?? TfliteService();

  Future<Uint8List> getModelBytes() => _tfliteService.getModelBytes();

  Future<List<String>> getLabels() => _tfliteService.loadLabels();

  Future<void> initialize() => _tfliteService.initialize();

  Future<SkinAnalysisModel> classifyImage(String imagePath) =>
      _tfliteService.classifyImage(imagePath);

  Future<SkinAnalysisModel> runInference({
    required String imagePath,
    Uint8List? imageBytes,
    Uint8List? modelBytes,
    required List<String> labels,
  }) {
    return _tfliteService.runInference(
      imagePath: imagePath,
      imageBytes: imageBytes,
      modelBytes: modelBytes,
      labels: labels,
    );
  }

  static Float32List preprocessImageBytes(Uint8List imageBytes) {
    return TfliteService.preprocessImageBytes(imageBytes);
  }

  static bool isHumanSkinChromaticity(int r, int g, int b) {
    return TfliteService.isHumanSkinChromaticity(r, g, b);
  }

  static void dispose() {
    TfliteService().dispose();
  }
}
