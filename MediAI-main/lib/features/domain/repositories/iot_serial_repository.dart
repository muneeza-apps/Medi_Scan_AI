import '../entities/iot_telemetry_entity.dart';
import '../entities/usb_port_info_entity.dart';

abstract class IotSerialRepository {

  Stream<IotTelemetryEntity> get telemetryStream;

  Stream<DualModeConnectionStatus> get connectionStatusStream;

  Stream<String> get rawLogStream;

  IotTransportMode get activeTransportMode;

  Future<void> switchTransportMode(IotTransportMode mode);

  Future<List<UsbPortInfoEntity>> getAvailablePorts({IotTransportMode? mode});

  Future<bool> connect({UsbPortInfoEntity? port, int baudRate = 115200});

  Future<void> disconnect();

  Future<void> sendData(String data);

  IotTelemetryEntity? get latestTelemetry;
  UsbPortInfoEntity? get connectedPort;
  DualModeConnectionStatus get currentStatus;
  int get packetsReceived;
  int get parseErrorsCount;

  void dispose();
}
