import 'dart:convert';
import '../../../../core/models/iot_vitals_model.dart';
import '../../domain/entities/iot_telemetry_entity.dart';

class IotTelemetryModel extends IotTelemetryEntity {
  const IotTelemetryModel({
    required super.finger,
    required super.bpm,
    required super.spo2,
    required super.temp,
    required super.status,
    required super.timestamp,
    super.hardwareNode = 'Clinical Biometric Module',
    super.devicePort = 'USB-CDC',
    super.packetSequence = 0,
  });

  factory IotTelemetryModel.fromMap(
    Map<String, dynamic> map, {
    String devicePort = 'USB-CDC',
    int packetSequence = 0,
  }) {

    bool parsedFinger = false;
    final rawFinger = map['finger'];
    if (rawFinger is bool) {
      parsedFinger = rawFinger;
    } else if (rawFinger is num) {
      parsedFinger = rawFinger != 0;
    } else if (rawFinger is String) {
      parsedFinger = rawFinger.toLowerCase() == 'true' || rawFinger == '1';
    }

    int parsedBpm = 0;
    final rawBpm = map['bpm'] ?? map['hr'] ?? map['heartRate'];
    if (rawBpm is num) {
      parsedBpm = rawBpm.toInt();
    } else if (rawBpm is String) {
      parsedBpm = int.tryParse(rawBpm) ?? (double.tryParse(rawBpm)?.round() ?? 0);
    }

    int parsedSpo2 = 0;
    final rawSpo2 = map['spo2'] ?? map['o2'] ?? map['oxygen'];
    if (rawSpo2 is num) {
      parsedSpo2 = rawSpo2.toInt();
    } else if (rawSpo2 is String) {
      parsedSpo2 = int.tryParse(rawSpo2) ?? (double.tryParse(rawSpo2)?.round() ?? 0);
    }

    double parsedTemp = 0.0;
    final rawTemp = map['temp'] ?? map['temperature'] ?? map['temp_obj'];
    if (rawTemp is num) {
      parsedTemp = rawTemp.toDouble();
    } else if (rawTemp is String) {
      parsedTemp = double.tryParse(rawTemp) ?? 0.0;
    }

    String parsedStatus = 'MEASURING';
    final rawStatus = map['status'];
    if (rawStatus != null && rawStatus.toString().trim().isNotEmpty) {
      parsedStatus = rawStatus.toString().trim().toUpperCase();
    } else {
      parsedStatus = parsedFinger ? 'MEASURING' : 'NO_FINGER';
    }

    return IotTelemetryModel(
      finger: parsedFinger,
      bpm: parsedBpm.clamp(0, 240),
      spo2: parsedSpo2.clamp(0, 100),
      temp: double.parse(parsedTemp.clamp(0.0, 50.0).toStringAsFixed(1)),
      status: parsedStatus,
      timestamp: DateTime.now(),
      hardwareNode: map['hardwareNode'] as String? ?? 'Clinical Biometric Module',
      devicePort: devicePort,
      packetSequence: packetSequence,
    );
  }

  static IotTelemetryModel? tryParseJson(
    String rawJsonString, {
    String devicePort = 'USB-CDC',
    int packetSequence = 0,
  }) {
    final startIdx = rawJsonString.indexOf('{');
    final endIdx = rawJsonString.lastIndexOf('}');
    if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
      return null;
    }

    final candidate = rawJsonString.substring(startIdx, endIdx + 1);
    try {
      final decoded = json.decode(candidate);
      if (decoded is Map<String, dynamic>) {
        return IotTelemetryModel.fromMap(
          decoded,
          devicePort: devicePort,
          packetSequence: packetSequence,
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'finger': finger,
      'bpm': bpm,
      'spo2': spo2,
      'temp': temp,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'hardwareNode': hardwareNode,
      'devicePort': devicePort,
      'packetSequence': packetSequence,
    };
  }

  String toJson() => json.encode(toMap());

  IotVitalsReading toVitalsReading({String? deviceId, String? deviceName}) {
    return IotVitalsReading(
      heartRate: finger ? bpm : 0,
      spo2: finger ? spo2 : 0,
      temperatureCelsius: temp,
      perfusionIndex: finger ? 2.8 : 0.0,
      timestamp: timestamp,
      deviceId: deviceId ?? 'BIOMETRIC-SCANNER',
      deviceName: deviceName ?? 'MediScanAI Biometric Scanner',
      batteryLevel: 100,
      isSimulated: false,
      ambientTempCelsius: 28.0,
      irSkinTempCelsius: temp,
      hardwareNode: hardwareNode,
    );
  }
}
