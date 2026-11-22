import 'dart:async';

import '../../../../core/services/iot_vitals_service.dart';
import '../../domain/entities/iot_telemetry_entity.dart';
import '../../domain/entities/usb_port_info_entity.dart';
import '../../domain/repositories/iot_serial_repository.dart';
import '../datasources/usb_serial_datasource.dart';
import '../models/iot_telemetry_model.dart';

class IotSerialRepositoryImpl implements IotSerialRepository {
  final IUsbSerialDataSource _dataSource;
  final StreamController<IotTelemetryEntity> _telemetryController =
      StreamController<IotTelemetryEntity>.broadcast();

  StreamSubscription<IotTelemetryModel>? _telemetrySub;
  IotTelemetryEntity? _latestTelemetry;

  IotSerialRepositoryImpl({IUsbSerialDataSource? dataSource})
      : _dataSource = dataSource ?? UsbSerialDataSourceImpl() {
    _initListeners();
  }

  void _initListeners() {
    _telemetrySub = _dataSource.telemetryStream.listen((model) {
      _latestTelemetry = model;
      _telemetryController.add(model);

      try {
        if (model.finger && model.bpm > 40 && model.spo2 > 70) {
          final vitals = model.toVitalsReading(
            deviceId: _dataSource.currentPort?.deviceName ?? 'Clinical-Scanner-CDC',
            deviceName: _dataSource.currentPort?.displayTitle ?? 'Clinical Biometric Scanner',
          );
          IotVitalsService.instance.recordExternalVitals(vitals);
        }
      } catch (_) {}
    });
  }

  @override
  Stream<IotTelemetryEntity> get telemetryStream => _telemetryController.stream;

  @override
  Stream<DualModeConnectionStatus> get connectionStatusStream =>
      _dataSource.statusStream;

  @override
  Stream<String> get rawLogStream => _dataSource.rawLogStream;

  @override
  IotTransportMode get activeTransportMode => _dataSource.activeTransportMode;

  @override
  Future<void> switchTransportMode(IotTransportMode mode) =>
      _dataSource.switchMode(mode);

  @override
  Future<List<UsbPortInfoEntity>> getAvailablePorts({IotTransportMode? mode}) =>
      _dataSource.listDevices(mode: mode);

  @override
  Future<bool> connect({UsbPortInfoEntity? port, int baudRate = 115200}) =>
      _dataSource.connect(port: port, baudRate: baudRate);

  @override
  Future<void> disconnect() => _dataSource.disconnect();

  @override
  Future<void> sendData(String data) => _dataSource.writeData(data);

  @override
  IotTelemetryEntity? get latestTelemetry => _latestTelemetry;

  @override
  UsbPortInfoEntity? get connectedPort => _dataSource.currentPort;

  @override
  DualModeConnectionStatus get currentStatus => _dataSource.currentStatus;

  @override
  int get packetsReceived => _dataSource.packetsReceived;

  @override
  int get parseErrorsCount => _dataSource.errorsCount;

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _telemetryController.close();
    _dataSource.dispose();
  }
}
