import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/clinical_session_entities.dart';
import '../../domain/entities/iot_telemetry_entity.dart';
import '../../domain/entities/usb_port_info_entity.dart';
import '../../domain/usecases/iot_serial_usecases.dart';
import 'usb_serial_event.dart';
import 'usb_serial_state.dart';

class _StabilizationSample {
  final int bpm;
  final int spo2;
  final double temp;
  final DateTime timestamp;

  _StabilizationSample({
    required this.bpm,
    required this.spo2,
    required this.temp,
    required this.timestamp,
  });
}

class UsbSerialBloc extends Bloc<UsbSerialEvent, UsbSerialState> {
  final GetUsbPortsUseCase getPortsUseCase;
  final ConnectUsbSerialUseCase connectUseCase;
  final DisconnectUsbSerialUseCase disconnectUseCase;
  final SwitchTransportModeUseCase switchTransportModeUseCase;
  final WatchUsbTelemetryUseCase watchTelemetryUseCase;
  final WatchUsbStatusUseCase watchStatusUseCase;
  final WatchUsbRawLogsUseCase watchRawLogsUseCase;
  final SendUsbCommandUseCase sendCommandUseCase;

  StreamSubscription<dynamic>? _telemetrySub;
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _rawLogSub;

  final List<_StabilizationSample> _stabilityBuffer = [];

  UsbSerialBloc({
    required this.getPortsUseCase,
    required this.connectUseCase,
    required this.disconnectUseCase,
    required this.switchTransportModeUseCase,
    required this.watchTelemetryUseCase,
    required this.watchStatusUseCase,
    required this.watchRawLogsUseCase,
    required this.sendCommandUseCase,
  }) : super(const UsbSerialState()) {
    on<UsbSerialStarted>(_onStarted);
    on<SwitchIotTransportMode>(_onSwitchTransportMode);
    on<RefreshUsbPorts>(_onRefreshPorts);
    on<ConnectUsbPort>(_onConnectPort);
    on<DisconnectUsbPort>(_onDisconnectPort);
    on<LockVitalsSnapshot>(_onLockSnapshot);
    on<ClearVitalsSnapshot>(_onClearSnapshot);
    on<SendUsbCommand>(_onSendCommand);
    on<ClearUsbLogs>(_onClearLogs);
    on<ToggleRawConsole>(_onToggleRawConsole);
    on<UsbTelemetryReceived>(_onTelemetryReceived);
    on<UsbStatusChanged>(_onStatusChanged);
    on<UsbRawLogReceived>(_onRawLogReceived);
  }

  Future<void> _onStarted(
    UsbSerialStarted event,
    Emitter<UsbSerialState> emit,
  ) async {
    await _telemetrySub?.cancel();
    _telemetrySub = watchTelemetryUseCase().listen((telemetry) {
      add(UsbTelemetryReceived(telemetry));
    });

    await _statusSub?.cancel();
    _statusSub = watchStatusUseCase().listen((status) {
      add(UsbStatusChanged(status));
    });

    await _rawLogSub?.cancel();
    _rawLogSub = watchRawLogsUseCase().listen((logLine) {
      add(UsbRawLogReceived(logLine));
    });

    final ports = await getPortsUseCase(mode: state.activeTransportMode);
    emit(state.copyWith(availablePorts: ports));
  }

  Future<void> _onSwitchTransportMode(
    SwitchIotTransportMode event,
    Emitter<UsbSerialState> emit,
  ) async {
    emit(state.copyWith(
      activeTransportMode: event.mode,
      selectedPort: null,
      status: DualModeConnectionStatus.disconnected,
    ));

    await switchTransportModeUseCase(event.mode);
    final ports = await getPortsUseCase(mode: event.mode);
    emit(state.copyWith(availablePorts: ports));
  }

  Future<void> _onRefreshPorts(
    RefreshUsbPorts event,
    Emitter<UsbSerialState> emit,
  ) async {
    final mode = event.mode ?? state.activeTransportMode;
    final ports = await getPortsUseCase(mode: mode);
    emit(state.copyWith(availablePorts: ports));
  }

  Future<void> _onConnectPort(
    ConnectUsbPort event,
    Emitter<UsbSerialState> emit,
  ) async {
    final mode = event.port?.transportMode ?? state.activeTransportMode;
    emit(state.copyWith(
      selectedPort: event.port,
      activeTransportMode: mode,
      baudRate: event.baudRate,
      errorMessage: null,
    ));

    final success = await connectUseCase(
      port: event.port,
      baudRate: event.baudRate,
    );

    if (!success) {
      final modeName = mode == IotTransportMode.ble ? 'Wireless BLE' : 'USB CDC';
      emit(state.copyWith(
        errorMessage: 'Failed to establish $modeName link with selected biometric device.',
      ));
    }
  }

  Future<void> _onDisconnectPort(
    DisconnectUsbPort event,
    Emitter<UsbSerialState> emit,
  ) async {
    await disconnectUseCase();
    emit(state.copyWith(
      selectedPort: null,
    ));
  }

  void _onLockSnapshot(
    LockVitalsSnapshot event,
    Emitter<UsbSerialState> emit,
  ) {
    emit(state.copyWith(
      lockedSnapshot: event.snapshot,
      isSnapshotLocked: true,
    ));
  }

  void _onClearSnapshot(
    ClearVitalsSnapshot event,
    Emitter<UsbSerialState> emit,
  ) {
    _stabilityBuffer.clear();
    emit(state.copyWith(clearLockedSnapshot: true));
  }

  Future<void> _onSendCommand(
    SendUsbCommand event,
    Emitter<UsbSerialState> emit,
  ) async {
    await sendCommandUseCase(event.command);
  }

  void _onClearLogs(
    ClearUsbLogs event,
    Emitter<UsbSerialState> emit,
  ) {
    emit(state.copyWith(rawLogs: const []));
  }

  void _onToggleRawConsole(
    ToggleRawConsole event,
    Emitter<UsbSerialState> emit,
  ) {
    emit(state.copyWith(showRawConsole: !state.showRawConsole));
  }

  void _onTelemetryReceived(
    UsbTelemetryReceived event,
    Emitter<UsbSerialState> emit,
  ) {
    final telemetry = event.telemetry;

    final updatedHistory = List<IotTelemetryEntity>.from(state.telemetryHistory);
    updatedHistory.add(telemetry);
    if (updatedHistory.length > 50) {
      updatedHistory.removeAt(0);
    }

    final bool isPhysiological = telemetry.finger &&
        telemetry.bpm >= 50 &&
        telemetry.bpm <= 160 &&
        telemetry.spo2 >= 90 &&
        telemetry.temp >= 30.0;

    VitalsSnapshot? newLockedSnapshot = state.lockedSnapshot;
    bool newIsLocked = state.isSnapshotLocked;

    if (isPhysiological) {
      final now = telemetry.timestamp;
      _stabilityBuffer.add(_StabilizationSample(
        bpm: telemetry.bpm,
        spo2: telemetry.spo2,
        temp: telemetry.temp,
        timestamp: now,
      ));

      _stabilityBuffer.removeWhere(
        (s) => now.difference(s.timestamp).inMilliseconds > 6000,
      );

      if (_stabilityBuffer.isNotEmpty) {
        final durationMs = now.difference(_stabilityBuffer.first.timestamp).inMilliseconds;
        if (durationMs >= 3000 && _stabilityBuffer.length >= 5) {
          newLockedSnapshot = VitalsSnapshot(
            heartRate: telemetry.bpm,
            spo2: telemetry.spo2,
            temperature: telemetry.temp,
            capturedAt: now,
            isLocked: true,
          );
          newIsLocked = true;
        }
      }
    } else {

      _stabilityBuffer.clear();
    }

    emit(state.copyWith(
      currentTelemetry: telemetry,
      telemetryHistory: updatedHistory,
      packetsReceived: state.packetsReceived + 1,
      lockedSnapshot: newLockedSnapshot,
      isSnapshotLocked: newIsLocked,
    ));
  }

  void _onStatusChanged(
    UsbStatusChanged event,
    Emitter<UsbSerialState> emit,
  ) {
    emit(state.copyWith(status: event.status));
  }

  void _onRawLogReceived(
    UsbRawLogReceived event,
    Emitter<UsbSerialState> emit,
  ) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final formattedLine = '[$timeStr] ${event.logLine}';

    final updatedLogs = List<String>.from(state.rawLogs);
    updatedLogs.add(formattedLine);
    if (updatedLogs.length > 120) {
      updatedLogs.removeAt(0);
    }

    final isError = event.logLine.contains('[ERR]') || event.logLine.contains('[WARN]');
    emit(state.copyWith(
      rawLogs: updatedLogs,
      parseErrorsCount: isError ? state.parseErrorsCount + 1 : state.parseErrorsCount,
    ));
  }

  @override
  Future<void> close() {
    _telemetrySub?.cancel();
    _statusSub?.cancel();
    _rawLogSub?.cancel();
    return super.close();
  }
}

typedef TelemetryBloc = UsbSerialBloc;
