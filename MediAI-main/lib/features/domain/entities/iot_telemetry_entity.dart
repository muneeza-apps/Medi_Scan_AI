class IotTelemetryEntity {
  final bool finger;
  final int bpm;
  final int spo2;
  final double temp;
  final String status;
  final DateTime timestamp;
  final String hardwareNode;
  final String devicePort;
  final int packetSequence;

  const IotTelemetryEntity({
    required this.finger,
    required this.bpm,
    required this.spo2,
    required this.temp,
    required this.status,
    required this.timestamp,
    this.hardwareNode = 'Clinical Biometric Module',
    this.devicePort = 'USB-CDC',
    this.packetSequence = 0,
  });

  bool get isFingerDetected => finger;

  double get tempFahrenheit => (temp * 9.0 / 5.0) + 32.0;

  bool get isHypoxic => finger && spo2 > 0 && spo2 < 92;
  bool get isTachycardic => finger && bpm > 100;
  bool get isBradycardic => finger && bpm > 0 && bpm < 60;
  bool get isPeripheralHypothermia => finger && temp > 25.0 && temp < 28.0;
  bool get isNormalPeripheralTemp => finger && temp >= 29.5 && temp <= 36.2;
  bool get isElevatedPeripheralTemp => finger && temp > 36.5;
  bool get isFebrile => isElevatedPeripheralTemp;
  bool get isCritical =>
      isHypoxic ||
      isTachycardic ||
      isFebrile ||
      isPeripheralHypothermia;

  int get signalQualityPercent {
    if (!finger) return 0;
    if (status.toUpperCase().contains('CALIBRAT')) return 40;
    if (bpm >= 45 && bpm <= 190 && spo2 >= 85 && spo2 <= 100 && temp >= 29.5 && temp <= 42.0) {
      return 96;
    }
    if (bpm > 0 && spo2 > 0) return 75;
    return 20;
  }

  String get clinicalAssessment {
    if (!finger) return 'No Finger Contact';
    if (isCritical) {
      if (isPeripheralHypothermia) return 'Severe Hypothermia Alert';
      if (isHypoxic && isFebrile) return 'Hypoxia & Elevated Temp Warning';
      if (isHypoxic) return 'Hypoxia Warning (Low SpO₂)';
      if (isFebrile) return 'Febrile Alert (High Temp)';
      if (isTachycardic) return 'Tachycardia Alert';
    }
    if (bpm >= 60 && bpm <= 100 && spo2 >= 95 && isNormalPeripheralTemp) {
      return 'Vitals Optimal';
    }
    return 'Stable Measurement';
  }

  IotTelemetryEntity copyWith({
    bool? finger,
    int? bpm,
    int? spo2,
    double? temp,
    String? status,
    DateTime? timestamp,
    String? hardwareNode,
    String? devicePort,
    int? packetSequence,
  }) {
    return IotTelemetryEntity(
      finger: finger ?? this.finger,
      bpm: bpm ?? this.bpm,
      spo2: spo2 ?? this.spo2,
      temp: temp ?? this.temp,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      hardwareNode: hardwareNode ?? this.hardwareNode,
      devicePort: devicePort ?? this.devicePort,
      packetSequence: packetSequence ?? this.packetSequence,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IotTelemetryEntity &&
          runtimeType == other.runtimeType &&
          finger == other.finger &&
          bpm == other.bpm &&
          spo2 == other.spo2 &&
          temp == other.temp &&
          status == other.status &&
          packetSequence == other.packetSequence;

  @override
  int get hashCode =>
      finger.hashCode ^
      bpm.hashCode ^
      spo2.hashCode ^
      temp.hashCode ^
      status.hashCode ^
      packetSequence.hashCode;

  @override
  String toString() {
    return 'IotTelemetryEntity(finger: $finger, bpm: $bpm, spo2: $spo2, temp: $temp, status: $status, seq: $packetSequence)';
  }
}
