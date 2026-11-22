import 'package:flutter/foundation.dart';

import '../../domain/entities/clinical_session_entities.dart';
import '../../domain/entities/iot_telemetry_entity.dart';
import '../../domain/entities/usb_port_info_entity.dart';

class UsbSerialState {
  final IotTransportMode activeTransportMode;
  final DualModeConnectionStatus status;
  final IotTelemetryEntity? currentTelemetry;
  final List<UsbPortInfoEntity> availablePorts;
  final UsbPortInfoEntity? selectedPort;
  final List<IotTelemetryEntity> telemetryHistory;
  final List<String> rawLogs;
  final bool showRawConsole;
  final int packetsReceived;
  final int parseErrorsCount;
  final int baudRate;
  final int? bleRssi;
  final String? errorMessage;
  final VitalsSnapshot? lockedSnapshot;
  final bool isSnapshotLocked;

  const UsbSerialState({
    this.activeTransportMode = IotTransportMode.usbOtg,
    this.status = DualModeConnectionStatus.disconnected,
    this.currentTelemetry,
    this.availablePorts = const [],
    this.selectedPort,
    this.telemetryHistory = const [],
    this.rawLogs = const [],
    this.showRawConsole = false,
    this.packetsReceived = 0,
    this.parseErrorsCount = 0,
    this.baudRate = 115200,
    this.bleRssi,
    this.errorMessage,
    this.lockedSnapshot,
    this.isSnapshotLocked = false,
  });

  bool get isUsbMode => activeTransportMode == IotTransportMode.usbOtg;
  bool get isBleMode => activeTransportMode == IotTransportMode.ble;

  bool get isConnected =>
      status == DualModeConnectionStatus.connected ||
      status == DualModeConnectionStatus.streaming;

  bool get isStreaming => status == DualModeConnectionStatus.streaming;
  bool get isConnecting => status == DualModeConnectionStatus.connecting;
  bool get isDiscovering => status == DualModeConnectionStatus.discovering;
  bool get hasFinger => currentTelemetry?.finger ?? false;
  bool get hasLockedSnapshot => lockedSnapshot != null;

  VitalsSnapshot? get activeOrLockedSnapshot {
    if (hasFinger && currentTelemetry != null && currentTelemetry!.bpm > 0) {
      return VitalsSnapshot(
        heartRate: currentTelemetry!.bpm,
        spo2: currentTelemetry!.spo2,
        temperature: currentTelemetry!.temp,
        capturedAt: currentTelemetry!.timestamp,
        isLocked: isSnapshotLocked,
      );
    }
    return lockedSnapshot;
  }

  UsbSerialState copyWith({
    IotTransportMode? activeTransportMode,
    DualModeConnectionStatus? status,
    IotTelemetryEntity? currentTelemetry,
    List<UsbPortInfoEntity>? availablePorts,
    UsbPortInfoEntity? selectedPort,
    List<IotTelemetryEntity>? telemetryHistory,
    List<String>? rawLogs,
    bool? showRawConsole,
    int? packetsReceived,
    int? parseErrorsCount,
    int? baudRate,
    int? bleRssi,
    String? errorMessage,
    VitalsSnapshot? lockedSnapshot,
    bool? isSnapshotLocked,
    bool clearLockedSnapshot = false,
  }) {
    return UsbSerialState(
      activeTransportMode: activeTransportMode ?? this.activeTransportMode,
      status: status ?? this.status,
      currentTelemetry: currentTelemetry ?? this.currentTelemetry,
      availablePorts: availablePorts ?? this.availablePorts,
      selectedPort: selectedPort ?? this.selectedPort,
      telemetryHistory: telemetryHistory ?? this.telemetryHistory,
      rawLogs: rawLogs ?? this.rawLogs,
      showRawConsole: showRawConsole ?? this.showRawConsole,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      parseErrorsCount: parseErrorsCount ?? this.parseErrorsCount,
      baudRate: baudRate ?? this.baudRate,
      bleRssi: bleRssi ?? this.bleRssi,
      errorMessage: errorMessage,
      lockedSnapshot: clearLockedSnapshot ? null : (lockedSnapshot ?? this.lockedSnapshot),
      isSnapshotLocked: clearLockedSnapshot ? false : (isSnapshotLocked ?? this.isSnapshotLocked),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsbSerialState &&
          runtimeType == other.runtimeType &&
          activeTransportMode == other.activeTransportMode &&
          status == other.status &&
          currentTelemetry == other.currentTelemetry &&
          listEquals(availablePorts, other.availablePorts) &&
          selectedPort == other.selectedPort &&
          listEquals(telemetryHistory, other.telemetryHistory) &&
          listEquals(rawLogs, other.rawLogs) &&
          showRawConsole == other.showRawConsole &&
          packetsReceived == other.packetsReceived &&
          parseErrorsCount == other.parseErrorsCount &&
          baudRate == other.baudRate &&
          bleRssi == other.bleRssi &&
          errorMessage == other.errorMessage &&
          lockedSnapshot == other.lockedSnapshot &&
          isSnapshotLocked == other.isSnapshotLocked;

  @override
  int get hashCode => Object.hash(
        activeTransportMode,
        status,
        currentTelemetry,
        Object.hashAll(availablePorts),
        selectedPort,
        Object.hashAll(telemetryHistory),
        Object.hashAll(rawLogs),
        showRawConsole,
        packetsReceived,
        parseErrorsCount,
        baudRate,
        bleRssi,
        errorMessage,
        lockedSnapshot,
        isSnapshotLocked,
      );
}
