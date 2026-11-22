import 'dart:convert';
import 'dart:typed_data';

import '../models/iot_telemetry_model.dart';

class DecodedFrameResult {
  final List<String> rawFrames;
  final List<IotTelemetryModel> validTelemetry;
  final List<String> malformedFrames;

  const DecodedFrameResult({
    required this.rawFrames,
    required this.validTelemetry,
    required this.malformedFrames,
  });
}

class SerialStreamFrameDecoder {
  final StringBuffer _buffer = StringBuffer();
  final int maxBufferSizeBytes;
  int _sequenceCounter = 0;
  final String devicePort;

  SerialStreamFrameDecoder({
    this.maxBufferSizeBytes = 4096,
    this.devicePort = 'USB-CDC',
  });

  DecodedFrameResult processBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const DecodedFrameResult(
        rawFrames: [],
        validTelemetry: [],
        malformedFrames: [],
      );
    }

    final incomingString = utf8.decode(bytes, allowMalformed: true);
    return processChunk(incomingString);
  }

  DecodedFrameResult processChunk(String chunk) {
    if (chunk.isEmpty) {
      return const DecodedFrameResult(
        rawFrames: [],
        validTelemetry: [],
        malformedFrames: [],
      );
    }

    _buffer.write(chunk);

    if (_buffer.length > maxBufferSizeBytes) {
      final current = _buffer.toString();
      final lastNewline = current.lastIndexOf('\n');
      _buffer.clear();
      if (lastNewline != -1 && lastNewline < current.length - 1) {

        _buffer.write(current.substring(lastNewline + 1));
      }
    }

    final accumulated = _buffer.toString();
    if (!accumulated.contains('\n')) {

      return const DecodedFrameResult(
        rawFrames: [],
        validTelemetry: [],
        malformedFrames: [],
      );
    }

    final segments = accumulated.split('\n');

    final trailingFragment = segments.removeLast();
    _buffer.clear();
    _buffer.write(trailingFragment);

    final rawFrames = <String>[];
    final validTelemetry = <IotTelemetryModel>[];
    final malformedFrames = <String>[];

    for (final rawSegment in segments) {
      final sanitized = rawSegment.replaceAll('\r', '').replaceAll('\x00', '').trim();
      if (sanitized.isEmpty) continue;

      rawFrames.add(sanitized);

      final parsed = IotTelemetryModel.tryParseJson(
        sanitized,
        devicePort: devicePort,
        packetSequence: ++_sequenceCounter,
      );

      if (parsed != null) {
        validTelemetry.add(parsed);
      } else {
        malformedFrames.add(sanitized);
      }
    }

    return DecodedFrameResult(
      rawFrames: rawFrames,
      validTelemetry: validTelemetry,
      malformedFrames: malformedFrames,
    );
  }

  void reset() {
    _buffer.clear();
    _sequenceCounter = 0;
  }

  int get currentBufferSize => _buffer.length;
}
