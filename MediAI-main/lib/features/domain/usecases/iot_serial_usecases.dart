import '../entities/iot_telemetry_entity.dart';
import '../entities/usb_port_info_entity.dart';
import '../repositories/iot_serial_repository.dart';

class GetUsbPortsUseCase {
  final IotSerialRepository repository;
  GetUsbPortsUseCase(this.repository);

  Future<List<UsbPortInfoEntity>> call({IotTransportMode? mode}) =>
      repository.getAvailablePorts(mode: mode);
}

class ConnectUsbSerialUseCase {
  final IotSerialRepository repository;
  ConnectUsbSerialUseCase(this.repository);

  Future<bool> call({UsbPortInfoEntity? port, int baudRate = 115200}) =>
      repository.connect(port: port, baudRate: baudRate);
}

class DisconnectUsbSerialUseCase {
  final IotSerialRepository repository;
  DisconnectUsbSerialUseCase(this.repository);

  Future<void> call() => repository.disconnect();
}

class SwitchTransportModeUseCase {
  final IotSerialRepository repository;
  SwitchTransportModeUseCase(this.repository);

  Future<void> call(IotTransportMode mode) => repository.switchTransportMode(mode);
}

class WatchUsbTelemetryUseCase {
  final IotSerialRepository repository;
  WatchUsbTelemetryUseCase(this.repository);

  Stream<IotTelemetryEntity> call() => repository.telemetryStream;
}

class WatchUsbStatusUseCase {
  final IotSerialRepository repository;
  WatchUsbStatusUseCase(this.repository);

  Stream<DualModeConnectionStatus> call() => repository.connectionStatusStream;
}

class WatchUsbRawLogsUseCase {
  final IotSerialRepository repository;
  WatchUsbRawLogsUseCase(this.repository);

  Stream<String> call() => repository.rawLogStream;
}

class SendUsbCommandUseCase {
  final IotSerialRepository repository;
  SendUsbCommandUseCase(this.repository);

  Future<void> call(String command) => repository.sendData(command);
}

