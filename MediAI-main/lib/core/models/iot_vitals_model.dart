import 'dart:convert';

enum IotDeviceType {
  pulseOximeter,
  thermometer,
  bloodPressureMonitor,
  esp32Node,
  generalMedical,
}

enum IotConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
  error,
}

class IotDeviceModel {
  final String id;
  final String name;
  final int rssi;
  final IotDeviceType type;
  final IotConnectionState connectionState;
  final int? batteryLevel;

  const IotDeviceModel({
    required this.id,
    required this.name,
    this.rssi = -70,
    this.type = IotDeviceType.generalMedical,
    this.connectionState = IotConnectionState.disconnected,
    this.batteryLevel,
  });

  IotDeviceModel copyWith({
    String? id,
    String? name,
    int? rssi,
    IotDeviceType? type,
    IotConnectionState? connectionState,
    int? batteryLevel,
  }) {
    return IotDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      type: type ?? this.type,
      connectionState: connectionState ?? this.connectionState,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rssi': rssi,
      'type': type.name,
      'connectionState': connectionState.name,
      'batteryLevel': batteryLevel,
    };
  }

  factory IotDeviceModel.fromMap(Map<String, dynamic> map) {
    return IotDeviceModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Medical Sensor',
      rssi: (map['rssi'] as num?)?.toInt() ?? -70,
      type: IotDeviceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => IotDeviceType.generalMedical,
      ),
      connectionState: IotConnectionState.values.firstWhere(
        (e) => e.name == map['connectionState'],
        orElse: () => IotConnectionState.disconnected,
      ),
      batteryLevel: (map['batteryLevel'] as num?)?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory IotDeviceModel.fromJson(String source) =>
      IotDeviceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IotDeviceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class IotVitalsReading {
  final int heartRate;
  final int spo2;
  final double temperatureCelsius;
  final double perfusionIndex;
  final DateTime timestamp;
  final String deviceId;
  final String deviceName;
  final int batteryLevel;
  final bool isSimulated;
  final double? ambientTempCelsius;
  final double? irSkinTempCelsius;
  final String hardwareNode;

  const IotVitalsReading({
    required this.heartRate,
    required this.spo2,
    required this.temperatureCelsius,
    this.perfusionIndex = 2.4,
    required this.timestamp,
    required this.deviceId,
    required this.deviceName,
    this.batteryLevel = 95,
    this.isSimulated = false,
    this.ambientTempCelsius = 28.2,
    this.irSkinTempCelsius,
    this.hardwareNode = 'Clinical Biometric Module',
  });

  double get temperatureFahrenheit => (temperatureCelsius * 9 / 5) + 32;
  double get irTemperatureFahrenheit =>
      ((irSkinTempCelsius ?? temperatureCelsius) * 9 / 5) + 32;
  double get skinTemperature => irSkinTempCelsius ?? temperatureCelsius;

  bool get isValid => heartRate > 40 && spo2 > 70;
  bool get isTachycardic => heartRate > 115;
  bool get isBradycardic => heartRate > 40 && heartRate < 50;
  bool get isHypoxic => spo2 > 70 && spo2 < 92;
  bool get isPeripheralHypothermia =>
      skinTemperature > 25.0 && skinTemperature < 28.0;
  bool get isNormalPeripheralTemp =>
      skinTemperature >= 29.5 && skinTemperature <= 36.2;
  bool get isElevatedPeripheralTemp => skinTemperature > 36.5;
  bool get isFebrile => isElevatedPeripheralTemp;
  bool get isCriticalVitals =>
      isValid &&
      (isTachycardic ||
          isBradycardic ||
          isHypoxic ||
          isFebrile ||
          isPeripheralHypothermia);

  bool get isNormalVitals =>
      isValid &&
      heartRate >= 60 &&
      heartRate <= 100 &&
      spo2 >= 95 &&
      isNormalPeripheralTemp;

  String get tempStatus {
    if (isElevatedPeripheralTemp) return 'Elevated Temp / Fever';
    if (isPeripheralHypothermia) return 'Severe Hypothermia';
    if (skinTemperature < 29.5 && skinTemperature >= 25.0) return 'Cool Periphery';
    return 'Normal';
  }

  String get spo2Status {
    if (spo2 < 90) return 'Critical Hypoxia';
    if (spo2 < 95) return 'Low Saturation';
    return 'Normal';
  }

  String get heartRateStatus {
    if (heartRate > 100) return 'Tachycardia';
    if (heartRate < 60) return 'Bradycardia';
    return 'Normal Rhythm';
  }

  Map<String, dynamic> toMap() {
    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'temperatureCelsius': temperatureCelsius,
      'perfusionIndex': perfusionIndex,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'deviceName': deviceName,
      'batteryLevel': batteryLevel,
      'isSimulated': isSimulated,
      'ambientTempCelsius': ambientTempCelsius,
      'irSkinTempCelsius': irSkinTempCelsius,
      'hardwareNode': hardwareNode,
    };
  }

  factory IotVitalsReading.fromMap(Map<String, dynamic> map) {
    return IotVitalsReading(
      heartRate: (map['heartRate'] as num?)?.toInt() ?? 0,
      spo2: (map['spo2'] as num?)?.toInt() ?? 0,
      temperatureCelsius:
          (map['temperatureCelsius'] as num?)?.toDouble() ?? 0.0,
      perfusionIndex: (map['perfusionIndex'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      deviceId: map['deviceId'] as String? ?? 'BIOMETRIC-SCANNER',
      deviceName: map['deviceName'] as String? ?? 'MediScanAI Biometric Scanner',
      batteryLevel: (map['batteryLevel'] as num?)?.toInt() ?? 100,
      isSimulated: map['isSimulated'] as bool? ?? false,
      ambientTempCelsius: (map['ambientTempCelsius'] as num?)?.toDouble() ?? 0.0,
      irSkinTempCelsius: (map['irSkinTempCelsius'] as num?)?.toDouble(),
      hardwareNode: map['hardwareNode'] as String? ?? 'Clinical Biometric Module',
    );
  }

  String toJson() => json.encode(toMap());

  factory IotVitalsReading.fromJson(String source) =>
      IotVitalsReading.fromMap(json.decode(source) as Map<String, dynamic>);

  IotVitalsReading copyWith({
    int? heartRate,
    int? spo2,
    double? temperatureCelsius,
    double? perfusionIndex,
    DateTime? timestamp,
    String? deviceId,
    String? deviceName,
    int? batteryLevel,
    bool? isSimulated,
    double? ambientTempCelsius,
    double? irSkinTempCelsius,
    String? hardwareNode,
  }) {
    return IotVitalsReading(
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      perfusionIndex: perfusionIndex ?? this.perfusionIndex,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isSimulated: isSimulated ?? this.isSimulated,
      ambientTempCelsius: ambientTempCelsius ?? this.ambientTempCelsius,
      irSkinTempCelsius: irSkinTempCelsius ?? this.irSkinTempCelsius,
      hardwareNode: hardwareNode ?? this.hardwareNode,
    );
  }
}
