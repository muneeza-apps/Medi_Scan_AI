import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:skio_usb_serial/skio_usb_serial.dart';

import '../../domain/entities/usb_port_info_entity.dart';
import '../models/iot_telemetry_model.dart';
import 'serial_stream_frame_decoder.dart';

abstract class IUsbSerialDataSource {
  Stream<IotTelemetryModel> get telemetryStream;
  Stream<DualModeConnectionStatus> get statusStream;
  Stream<String> get rawLogStream;

  IotTransportMode get activeTransportMode;
  Future<void> switchMode(IotTransportMode mode);

  Future<List<UsbPortInfoEntity>> listDevices({IotTransportMode? mode});
  Future<bool> connect({UsbPortInfoEntity? port, int baudRate = 115200});
  Future<void> disconnect();
  Future<void> writeData(String data);

  UsbPortInfoEntity? get currentPort;
  DualModeConnectionStatus get currentStatus;
  int get packetsReceived;
  int get errorsCount;

  void dispose();
}

class UsbSerialDataSourceImpl implements IUsbSerialDataSource {
  static const String defaultBleDeviceName = 'MediScanAI_Node';
  static const String targetServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String targetCharacteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  final StreamController<IotTelemetryModel> _telemetryController =
      StreamController<IotTelemetryModel>.broadcast();
  @override
  Stream<IotTelemetryModel> get telemetryStream => _telemetryController.stream;

  final StreamController<DualModeConnectionStatus> _statusController =
      StreamController<DualModeConnectionStatus>.broadcast();
  @override
  Stream<DualModeConnectionStatus> get statusStream => _statusController.stream;

  final StreamController<String> _rawLogController =
      StreamController<String>.broadcast();
  @override
  Stream<String> get rawLogStream => _rawLogController.stream;

  IotTransportMode _activeTransportMode = IotTransportMode.usbOtg;
  @override
  IotTransportMode get activeTransportMode => _activeTransportMode;

  UsbSerialPort? _activeUsbPort;
  BluetoothDevice? _activeBleDevice;
  BluetoothCharacteristic? _activeBleCharacteristic;

  UsbPortInfoEntity? _currentPort;
  @override
  UsbPortInfoEntity? get currentPort => _currentPort;

  DualModeConnectionStatus _currentStatus = DualModeConnectionStatus.disconnected;
  @override
  DualModeConnectionStatus get currentStatus => _currentStatus;

  StreamSubscription<dynamic>? _usbSubscription;
  StreamSubscription<dynamic>? _bleSubscription;
  StreamSubscription<BluetoothConnectionState>? _bleConnectionStateSub;
  SerialStreamFrameDecoder? _frameDecoder;

  int _packetsReceived = 0;
  @override
  int get packetsReceived => _packetsReceived;

  int _errorsCount = 0;
  @override
  int get errorsCount => _errorsCount;

  void _updateStatus(DualModeConnectionStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void _log(String message) {
    if (!_rawLogController.isClosed) {
      _rawLogController.add(message);
    }
  }

  @override
  Future<void> switchMode(IotTransportMode mode) async {
    if (_activeTransportMode == mode && (_activeUsbPort != null || _activeBleDevice != null)) {
      return;
    }
    _log('[SYS] Switching transport mode: ${_activeTransportMode.name.toUpperCase()} -> ${mode.name.toUpperCase()}');
    await disconnect();
    _activeTransportMode = mode;
  }

  @override
  Future<List<UsbPortInfoEntity>> listDevices({IotTransportMode? mode}) async {
    final targetMode = mode ?? _activeTransportMode;
    _updateStatus(DualModeConnectionStatus.discovering);

    if (targetMode == IotTransportMode.ble) {
      return await _scanBleDevices();
    } else {
      return await _scanUsbDevices();
    }
  }

  Future<List<UsbPortInfoEntity>> _scanUsbDevices() async {
    final List<UsbPortInfoEntity> result = [];
    try {
      final List<DeviceHandle> rawDevices = await UsbSerialPort.list();
      for (final dev in rawDevices) {
        final isEsp32 = (dev.vendorId == 0x303A) ||
            (dev.name?.toLowerCase().contains('esp32') ?? false);

        result.add(
          UsbPortInfoEntity.usb(
            deviceName: dev.id,
            manufacturerName: isEsp32 ? 'Espressif Systems' : null,
            productName: dev.name ?? 'USB Serial Adapter',
            vendorId: dev.vendorId,
            productId: dev.productId,
            serialNumber: dev.serialNumber,
            interfaceName: dev.interfaceClasses.join(','),
            isEsp32: isEsp32,
          ),
        );
      }
    } catch (e) {
      _log('[ERR] USB Serial enumeration error: $e');
      debugPrint('[UsbSerialDataSource] listUsbDevices error: $e');
    }

    _updateStatus(_activeUsbPort != null
        ? DualModeConnectionStatus.connected
        : DualModeConnectionStatus.disconnected);

    return result;
  }

  Future<List<UsbPortInfoEntity>> _scanBleDevices() async {
    final List<UsbPortInfoEntity> result = [];

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      final List<ScanResult> discovered = [];

      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.advertisementData.advName;
          if (name.contains(defaultBleDeviceName) ||
              name.toLowerCase().contains('mediscan') ||
              name.toLowerCase().contains('esp32') ||
              r.advertisementData.serviceUuids.any((u) => u.str.toLowerCase().contains('4fafc201'))) {
            if (!discovered.any((d) => d.device.remoteId == r.device.remoteId)) {
              discovered.add(r);
            }
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
      await sub.cancel();

      for (final r in discovered) {
        final dName = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : defaultBleDeviceName);

        result.add(
          UsbPortInfoEntity.ble(
            deviceId: r.device.remoteId.str,
            deviceName: dName,
            rssi: r.rssi,
            serviceUuid: targetServiceUuid,
            characteristicUuid: targetCharacteristicUuid,
          ),
        );
      }
    } catch (e) {
      _log('[ERR] BLE Scan error: $e');
      debugPrint('[UsbSerialDataSource] scanBleDevices error: $e');
    }

    _updateStatus(_activeBleDevice != null
        ? DualModeConnectionStatus.connected
        : DualModeConnectionStatus.disconnected);

    return result;
  }

  @override
  Future<bool> connect({UsbPortInfoEntity? port, int baudRate = 115200}) async {
    await disconnect();
    _updateStatus(DualModeConnectionStatus.connecting);

    final targetMode = port?.transportMode ?? _activeTransportMode;
    _activeTransportMode = targetMode;

    if (targetMode == IotTransportMode.ble) {
      return await _connectBle(port);
    } else {
      return await _connectUsb(port, baudRate);
    }
  }

  Future<bool> _connectUsb(UsbPortInfoEntity? port, int baudRate) async {
    _log('[USB] Searching for physical USB CDC serial device...');

    try {
      final List<DeviceHandle> rawDevices = await UsbSerialPort.list();
      if (rawDevices.isEmpty) {
        _log('[ERR] No physical USB CDC serial devices detected. Check USB OTG connection.');
        _updateStatus(DualModeConnectionStatus.error);
        return false;
      }

      DeviceHandle? matchedDevice;
      if (port != null && port.vendorId != null) {
        matchedDevice = rawDevices.firstWhere(
          (d) => d.id == port.deviceName || (d.vendorId == port.vendorId && d.productId == port.productId),
          orElse: () => rawDevices.first,
        );
      } else {
        matchedDevice = rawDevices.firstWhere(
          (d) => d.vendorId == 0x303A || (d.name?.toLowerCase().contains('esp32') ?? false),
          orElse: () => rawDevices.first,
        );
      }

      final isEsp32 = (matchedDevice.vendorId == 0x303A) ||
          (matchedDevice.name?.toLowerCase().contains('esp32') ?? false);

      final targetPort = UsbPortInfoEntity.usb(
        deviceName: matchedDevice.id,
        manufacturerName: isEsp32 ? 'Espressif Systems' : null,
        productName: matchedDevice.name ?? 'USB Serial Adapter',
        vendorId: matchedDevice.vendorId,
        productId: matchedDevice.productId,
        serialNumber: matchedDevice.serialNumber,
        interfaceName: matchedDevice.interfaceClasses.join(','),
        isEsp32: isEsp32,
      );

      _currentPort = targetPort;

      try {
        await UsbSerialPort.access.requestAccess(matchedDevice);
      } catch (e) {
        _log('[WARN] USB Permission request returned: $e');
      }

      final UsbSerialPort usbPort = await UsbSerialPort.open(
        matchedDevice,
        config: SerialConfig(
          baudRate: baudRate,
          dataBits: 8,
          stopBits: StopBits.one,
          parity: Parity.none,
        ),
      );

      _activeUsbPort = usbPort;
      _frameDecoder = SerialStreamFrameDecoder(
        devicePort: targetPort.displayTitle,
      );

      _log('[SYS] USB CDC Connected: ${targetPort.displayTitle} @ $baudRate baud (8N1)');
      _updateStatus(DualModeConnectionStatus.connected);

      _usbSubscription = usbPort.input.listen(
        (Uint8List bytes) {
          _handleIncomingBytes(bytes, channel: 'USB-CDC');
        },
        onError: (err) {
          _log('[ERR] USB Serial stream error: $err');
          _errorsCount++;
          _updateStatus(DualModeConnectionStatus.error);
        },
        onDone: () {
          _log('[SYS] USB Serial stream disconnected by remote hardware');
          disconnect();
        },
      );
      return true;
    } catch (e) {
      _log('[ERR] USB Serial open failed: $e');
      _updateStatus(DualModeConnectionStatus.error);
      return false;
    }
  }

  Future<bool> _connectBle(UsbPortInfoEntity? port) async {
    final deviceId = port?.bleDeviceId ?? '';
    if (deviceId.isEmpty) {
      _log('[ERR] No target BLE device selected. Scan for MediScanAI_Node first.');
      _updateStatus(DualModeConnectionStatus.error);
      return false;
    }

    _currentPort = port;
    _log('[BLE] Initiating GATT connection to ${port?.deviceName} ($deviceId)...');

    try {
      final bleDevice = BluetoothDevice.fromId(deviceId);
      _activeBleDevice = bleDevice;

      await bleDevice.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 12),
        autoConnect: false,
      );

      _bleConnectionStateSub = bleDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _log('[BLE] Peripheral disconnected unexpectedly');
          disconnect();
        }
      });

      try {
        await bleDevice.requestMtu(512);
      } catch (_) {}

      final services = await bleDevice.discoverServices();
      BluetoothCharacteristic? targetChar;

      for (final s in services) {
        final sUuid = s.uuid.str.toLowerCase();
        if (sUuid.contains(targetServiceUuid.toLowerCase()) || sUuid.contains('4fafc201')) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str.toLowerCase();
            if (cUuid.contains(targetCharacteristicUuid.toLowerCase()) || cUuid.contains('beb5483e')) {
              targetChar = c;
              break;
            }
          }
        }
      }

      if (targetChar != null) {
        _activeBleCharacteristic = targetChar;
        await targetChar.setNotifyValue(true);

        _frameDecoder = SerialStreamFrameDecoder(devicePort: port?.displayTitle ?? 'MediScanAI_Node');
        _log('[BLE] Subscribed to Telemetry Characteristic: ${targetChar.uuid.str}');
        _updateStatus(DualModeConnectionStatus.connected);

        _bleSubscription = targetChar.lastValueStream.listen(
          (bytes) {
            if (bytes.isNotEmpty) {
              _handleIncomingBytes(Uint8List.fromList(bytes), channel: 'BLE');
            }
          },
          onError: (err) {
            _log('[ERR] BLE GATT notify error: $err');
            _errorsCount++;
            _updateStatus(DualModeConnectionStatus.error);
          },
        );
        return true;
      } else {
        _log('[ERR] Telemetry Characteristic not found ($targetCharacteristicUuid).');
        _updateStatus(DualModeConnectionStatus.error);
        disconnect();
        return false;
      }
    } catch (e) {
      _log('[ERR] BLE Connection error: $e');
      _updateStatus(DualModeConnectionStatus.error);
      disconnect();
      return false;
    }
  }

  void _handleIncomingBytes(Uint8List bytes, {required String channel}) {
    if (_frameDecoder == null) return;

    final decodedResult = _frameDecoder!.processBytes(bytes);

    for (final rawFrame in decodedResult.rawFrames) {
      _log('RX [$channel]: $rawFrame');
    }

    for (final telemetry in decodedResult.validTelemetry) {
      _packetsReceived++;
      _updateStatus(DualModeConnectionStatus.streaming);
      if (!_telemetryController.isClosed) {
        _telemetryController.add(telemetry);
      }
    }

    if (decodedResult.malformedFrames.isNotEmpty) {
      _errorsCount += decodedResult.malformedFrames.length;
      for (final bad in decodedResult.malformedFrames) {
        _log('[WARN] Discarded noisy/corrupt frame: $bad');
      }
    }
  }

  @override
  Future<void> writeData(String data) async {
    final payload = data.endsWith('\n') ? data : '$data\n';
    _log('TX: ${payload.trim()}');

    if (_activeUsbPort != null) {
      try {
        await _activeUsbPort!.write(Uint8List.fromList(utf8.encode(payload)));
      } catch (e) {
        _log('[ERR] USB Transmit error: $e');
      }
    } else if (_activeBleCharacteristic != null) {
      try {
        await _activeBleCharacteristic!.write(utf8.encode(payload), withoutResponse: true);
      } catch (e) {
        _log('[ERR] BLE Transmit error: $e');
      }
    } else {
      _log('[WARN] No active physical transport to transmit data.');
    }
  }

  @override
  Future<void> disconnect() async {
    await _usbSubscription?.cancel();
    _usbSubscription = null;

    if (_activeUsbPort != null) {
      try {
        await _activeUsbPort!.close();
      } catch (_) {}
      _activeUsbPort = null;
    }

    await _bleSubscription?.cancel();
    _bleSubscription = null;

    await _bleConnectionStateSub?.cancel();
    _bleConnectionStateSub = null;

    if (_activeBleDevice != null) {
      try {
        await _activeBleDevice!.disconnect();
      } catch (_) {}
      _activeBleDevice = null;
      _activeBleCharacteristic = null;
    }

    _frameDecoder?.reset();
    _frameDecoder = null;
    _currentPort = null;
    _updateStatus(DualModeConnectionStatus.disconnected);
    _log('[SYS] Communication link closed (Disconnected)');
  }

  @override
  void dispose() {
    disconnect();
    if (!_telemetryController.isClosed) _telemetryController.close();
    if (!_statusController.isClosed) _statusController.close();
    if (!_rawLogController.isClosed) _rawLogController.close();
  }
}
