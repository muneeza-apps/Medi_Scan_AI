import '../../domain/entities/clinical_session_entities.dart';
import '../../domain/entities/iot_telemetry_entity.dart';
import '../../domain/entities/usb_port_info_entity.dart';

sealed class UsbSerialEvent {
  const UsbSerialEvent();
}

class UsbSerialStarted extends UsbSerialEvent {
  const UsbSerialStarted();
}

class SwitchIotTransportMode extends UsbSerialEvent {
  final IotTransportMode mode;
  const SwitchIotTransportMode(this.mode);
}

class RefreshUsbPorts extends UsbSerialEvent {
  final IotTransportMode? mode;
  const RefreshUsbPorts({this.mode});
}

class ConnectUsbPort extends UsbSerialEvent {
  final UsbPortInfoEntity? port;
  final int baudRate;

  const ConnectUsbPort({this.port, this.baudRate = 115200});
}

class DisconnectUsbPort extends UsbSerialEvent {
  const DisconnectUsbPort();
}

class LockVitalsSnapshot extends UsbSerialEvent {
  final VitalsSnapshot snapshot;
  const LockVitalsSnapshot(this.snapshot);
}

class ClearVitalsSnapshot extends UsbSerialEvent {
  const ClearVitalsSnapshot();
}

class SendUsbCommand extends UsbSerialEvent {
  final String command;
  const SendUsbCommand(this.command);
}

class ClearUsbLogs extends UsbSerialEvent {
  const ClearUsbLogs();
}

class ToggleRawConsole extends UsbSerialEvent {
  const ToggleRawConsole();
}

class UsbTelemetryReceived extends UsbSerialEvent {
  final IotTelemetryEntity telemetry;
  const UsbTelemetryReceived(this.telemetry);
}

class UsbStatusChanged extends UsbSerialEvent {
  final DualModeConnectionStatus status;
  const UsbStatusChanged(this.status);
}

class UsbRawLogReceived extends UsbSerialEvent {
  final String logLine;
  const UsbRawLogReceived(this.logLine);
}

