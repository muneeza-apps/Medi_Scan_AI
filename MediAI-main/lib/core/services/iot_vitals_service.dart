import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/iot_vitals_model.dart';

class IotVitalsService {
  IotVitalsService._internal();
  static final IotVitalsService instance = IotVitalsService._internal();

  static const String _prefKeyLastVitals = 'mediscan_last_iot_vitals';

  final StreamController<IotVitalsReading> _vitalsController =
      StreamController<IotVitalsReading>.broadcast();
  Stream<IotVitalsReading> get vitalsStream => _vitalsController.stream;

  final StreamController<List<IotDeviceModel>> _devicesController =
      StreamController<List<IotDeviceModel>>.broadcast();
  Stream<List<IotDeviceModel>> get devicesStream => _devicesController.stream;

  final StreamController<IotConnectionState> _connectionStateController =
      StreamController<IotConnectionState>.broadcast();
  Stream<IotConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  IotVitalsReading? _latestReading;
  IotVitalsReading? get latestReading => _latestReading;

  IotConnectionState _connectionState = IotConnectionState.disconnected;
  IotConnectionState get connectionState => _connectionState;

  IotDeviceModel? _connectedDevice;
  IotDeviceModel? get connectedDevice => _connectedDevice;

  final List<IotDeviceModel> _discoveredDevices = [];
  List<IotDeviceModel> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  BluetoothDevice? _activeBleDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKeyLastVitals);
      if (savedJson != null && savedJson.isNotEmpty) {
        _latestReading = IotVitalsReading.fromJson(savedJson);
        _vitalsController.add(_latestReading!);
      }
    } catch (_) {}
  }

  Future<bool> startScanning() async {
    if (_connectionState == IotConnectionState.scanning) {
      return true;
    }

    _updateConnectionState(IotConnectionState.scanning);
    _discoveredDevices.clear();
    _devicesController.add(List.unmodifiable(_discoveredDevices));

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final deviceName = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.advertisementData.advName;

          final dName = deviceName.isNotEmpty
              ? deviceName
              : 'IoT Device ${r.device.remoteId.str.substring(max(0, r.device.remoteId.str.length - 5))}';

          final type = _detectDeviceType(dName);

          final existingIndex =
              _discoveredDevices.indexWhere((d) => d.id == r.device.remoteId.str);

          final model = IotDeviceModel(
            id: r.device.remoteId.str,
            name: dName,
            rssi: r.rssi,
            type: type,
            connectionState: _connectedDevice?.id == r.device.remoteId.str
                ? IotConnectionState.connected
                : IotConnectionState.disconnected,
          );

          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] = model;
          } else {
            _discoveredDevices.add(model);
          }
        }
        _devicesController.add(List.unmodifiable(_discoveredDevices));
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
    } catch (_) {}

    if (_connectionState == IotConnectionState.scanning) {
      _updateConnectionState(_connectedDevice != null
          ? IotConnectionState.connected
          : IotConnectionState.disconnected);
    }
  }

  Future<bool> connectToDevice(IotDeviceModel device) async {
    await stopScanning();
    _updateConnectionState(IotConnectionState.connecting);

    try {
      final bleDevice = BluetoothDevice.fromId(device.id);
      _activeBleDevice = bleDevice;

      await bleDevice.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _deviceStateSubscription?.cancel();
      _deviceStateSubscription =
          bleDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      _connectedDevice = device.copyWith(
        connectionState: IotConnectionState.connected,
      );
      _updateConnectionState(IotConnectionState.connected);

      await _subscribeToServices(bleDevice);
      return true;
    } catch (_) {
      _updateConnectionState(IotConnectionState.error);
      return false;
    }
  }

  Future<void> _subscribeToServices(BluetoothDevice bleDevice) async {
    try {
      final services = await bleDevice.discoverServices();
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
            await c.setNotifyValue(true);
            c.lastValueStream.listen((bytes) {
              _parseGattData(s.uuid.str, c.uuid.str, bytes);
            });
          }
        }
      }
    } catch (_) {}
  }

  void _parseGattData(String serviceUuid, String charUuid, List<int> bytes) {
    if (bytes.isEmpty) return;

    int hr = _latestReading?.heartRate ?? 0;
    int o2 = _latestReading?.spo2 ?? 0;
    double temp = _latestReading?.temperatureCelsius ?? 0.0;

    final sLower = serviceUuid.toLowerCase();
    final cLower = charUuid.toLowerCase();

    if (sLower.contains('180d') || cLower.contains('2a37')) {
      if (bytes.length >= 2) {
        final flags = bytes[0];
        final is16Bit = (flags & 0x01) != 0;
        hr = is16Bit && bytes.length >= 3
            ? (bytes[1] | (bytes[2] << 8))
            : bytes[1];
      }
    } else if (sLower.contains('1809') || cLower.contains('2a1c')) {
      if (bytes.length >= 5) {
        final raw = (bytes[1] | (bytes[2] << 8) | (bytes[3] << 16));
        temp = (raw / 100.0).clamp(30.0, 45.0);
      }
    } else if (sLower.contains('1822') || cLower.contains('2a5f')) {
      if (bytes.length >= 3) {
        o2 = bytes[1].clamp(0, 100);
        hr = bytes[2].clamp(0, 240);
      }
    } else {
      try {
        final str = utf8.decode(bytes);
        if (str.startsWith('{') && str.endsWith('}')) {
          final map = json.decode(str) as Map<String, dynamic>;
          final parsed = IotVitalsReading(
            heartRate: (map['hr'] ?? map['bpm'] ?? map['heartRate'] ?? hr) as int,
            spo2: (map['spo2'] ?? o2) as int,
            temperatureCelsius:
                ((map['temp'] ?? map['temp_obj'] ?? map['temperatureCelsius'] ?? temp) as num).toDouble(),
            perfusionIndex:
                ((map['pi'] ?? map['perfusionIndex'] ?? 0.0) as num).toDouble(),
            ambientTempCelsius:
                ((map['temp_amb'] ?? map['ambientTempCelsius'] ?? 0.0) as num).toDouble(),
            irSkinTempCelsius:
                ((map['temp_obj'] ?? map['irSkinTempCelsius'] ?? temp) as num).toDouble(),
            hardwareNode: map['hardwareNode'] as String? ?? 'Clinical Biometric Module',
            timestamp: DateTime.now(),
            deviceId: _connectedDevice?.id ?? 'BIOMETRIC-SCANNER',
            deviceName: _connectedDevice?.name ?? 'MediScanAI Biometric Scanner',
            batteryLevel: _connectedDevice?.batteryLevel ?? 100,
            isSimulated: false,
          );
          _broadcastReading(parsed);
          return;
        }
      } catch (_) {}
    }

    final reading = IotVitalsReading(
      heartRate: hr,
      spo2: o2,
      temperatureCelsius: temp,
      ambientTempCelsius: 0.0,
      irSkinTempCelsius: temp,
      hardwareNode: 'Clinical Biometric Module',
      timestamp: DateTime.now(),
      deviceId: _connectedDevice?.id ?? 'BLE-DEV',
      deviceName: _connectedDevice?.name ?? 'Connected Sensor',
      batteryLevel: _connectedDevice?.batteryLevel ?? 92,
      isSimulated: false,
    );

    _broadcastReading(reading);
  }

  Future<void> disconnectDevice() async {
    _updateConnectionState(IotConnectionState.disconnecting);

    try {
      await _activeBleDevice?.disconnect();
    } catch (_) {}

    _handleDisconnection();
  }

  void _handleDisconnection() {
    _activeBleDevice = null;
    _deviceStateSubscription?.cancel();
    _connectedDevice = null;
    _updateConnectionState(IotConnectionState.disconnected);
  }

  void _broadcastReading(IotVitalsReading reading) {
    _latestReading = reading;
    _vitalsController.add(reading);
    _saveLatestReading(reading);
  }

  void recordExternalVitals(IotVitalsReading reading) {
    if (reading.heartRate > 40 && reading.spo2 > 70) {
      _broadcastReading(reading);
    }
  }

  Future<void> _saveLatestReading(IotVitalsReading reading) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLastVitals, reading.toJson());
    } catch (_) {}
  }

  void _updateConnectionState(IotConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  IotDeviceType _detectDeviceType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('oxi') || lower.contains('spo2') || lower.contains('pulse')) {
      return IotDeviceType.pulseOximeter;
    }
    if (lower.contains('therm') || lower.contains('temp')) {
      return IotDeviceType.thermometer;
    }
    if (lower.contains('bp') || lower.contains('blood') || lower.contains('pressure')) {
      return IotDeviceType.bloodPressureMonitor;
    }
    if (lower.contains('esp32') || lower.contains('node') || lower.contains('gateway')) {
      return IotDeviceType.esp32Node;
    }
    return IotDeviceType.generalMedical;
  }

  void dispose() {
    _scanSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _vitalsController.close();
    _devicesController.close();
    _connectionStateController.close();
  }
}
