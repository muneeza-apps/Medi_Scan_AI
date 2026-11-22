enum IotTransportMode {
  usbOtg,
  ble,
}

enum DualModeConnectionStatus {
  disconnected,
  discovering,
  connecting,
  connected,
  streaming,
  error,
}

typedef UsbSerialConnectionStatus = DualModeConnectionStatus;

class UsbPortInfoEntity {
  final String deviceName;
  final String? manufacturerName;
  final String? productName;
  final int? vendorId;
  final int? productId;
  final String? serialNumber;
  final String? interfaceName;
  final bool isEsp32;
  final IotTransportMode transportMode;
  final String? bleDeviceId;
  final int? rssi;
  final String? serviceUuid;
  final String? characteristicUuid;

  const UsbPortInfoEntity({
    required this.deviceName,
    this.manufacturerName,
    this.productName,
    this.vendorId,
    this.productId,
    this.serialNumber,
    this.interfaceName,
    this.isEsp32 = false,
    this.transportMode = IotTransportMode.usbOtg,
    this.bleDeviceId,
    this.rssi,
    this.serviceUuid,
    this.characteristicUuid,
  });

  factory UsbPortInfoEntity.ble({
    required String deviceId,
    String deviceName = 'MediScanAI_Node',
    int? rssi,
    String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
    String characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8',
  }) {
    return UsbPortInfoEntity(
      deviceName: deviceName,
      productName: 'MediScanAI BLE Biometric Node',
      manufacturerName: 'Biometric Medical Systems',
      transportMode: IotTransportMode.ble,
      bleDeviceId: deviceId,
      rssi: rssi,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      isEsp32: true,
    );
  }

  factory UsbPortInfoEntity.usb({
    required String deviceName,
    String? manufacturerName,
    String? productName,
    int? vendorId,
    int? productId,
    String? serialNumber,
    String? interfaceName,
    bool isEsp32 = false,
  }) {
    return UsbPortInfoEntity(
      deviceName: deviceName,
      manufacturerName: manufacturerName,
      productName: productName,
      vendorId: vendorId,
      productId: productId,
      serialNumber: serialNumber,
      interfaceName: interfaceName,
      isEsp32: isEsp32,
      transportMode: IotTransportMode.usbOtg,
    );
  }

  String get displayTitle {
    if (transportMode == IotTransportMode.ble) {
      return deviceName.isNotEmpty ? deviceName : 'MediScanAI_Node';
    }
    if (productName != null && productName!.trim().isNotEmpty) {
      return productName!.trim();
    }
    if (isEsp32) {
      return 'MediScanAI Biometric Hub';
    }
    return deviceName.isNotEmpty ? deviceName : 'USB Serial Device';
  }

  String get displaySubtitle {
    if (transportMode == IotTransportMode.ble) {
      final rssiStr = rssi != null ? '$rssi dBm' : 'BLE Active';
      return 'BLE GATT • $rssiStr • UUID: 4faf...14b';
    }

    final List<String> parts = [];
    if (manufacturerName != null && manufacturerName!.isNotEmpty) {
      parts.add(manufacturerName!);
    }
    if (vendorId != null && productId != null) {
      parts.add('VID: 0x${vendorId!.toRadixString(16).toUpperCase()} PID: 0x${productId!.toRadixString(16).toUpperCase()}');
    }
    if (parts.isEmpty) {
      return '115200 Baud • 8N1 • CDC';
    }
    return parts.join(' • ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsbPortInfoEntity &&
          runtimeType == other.runtimeType &&
          deviceName == other.deviceName &&
          vendorId == other.vendorId &&
          productId == other.productId &&
          transportMode == other.transportMode &&
          bleDeviceId == other.bleDeviceId;

  @override
  int get hashCode =>
      deviceName.hashCode ^
      vendorId.hashCode ^
      productId.hashCode ^
      transportMode.hashCode ^
      (bleDeviceId?.hashCode ?? 0);
}
