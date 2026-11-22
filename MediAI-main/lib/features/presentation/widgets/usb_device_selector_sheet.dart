import 'package:flutter/material.dart';

import '../../domain/entities/usb_port_info_entity.dart';

class UsbDeviceSelectorSheet extends StatefulWidget {
  final List<UsbPortInfoEntity> ports;
  final UsbPortInfoEntity? selectedPort;
  final IotTransportMode activeMode;
  final bool isConnected;
  final Function(IotTransportMode mode) onModeChanged;
  final Function(UsbPortInfoEntity port, int baudRate) onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onRefresh;

  const UsbDeviceSelectorSheet({
    super.key,
    required this.ports,
    this.selectedPort,
    required this.activeMode,
    required this.isConnected,
    required this.onModeChanged,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefresh,
  });

  @override
  State<UsbDeviceSelectorSheet> createState() => _UsbDeviceSelectorSheetState();
}

class _UsbDeviceSelectorSheetState extends State<UsbDeviceSelectorSheet> {
  int _selectedBaudRate = 115200;
  final List<int> _baudRates = [9600, 19200, 38400, 57600, 115200, 230400];

  @override
  Widget build(BuildContext context) {
    final isBle = widget.activeMode == IotTransportMode.ble;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: const BoxDecoration(
        color: Color(0xFF111C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBle ? Icons.bluetooth_searching : Icons.usb,
                  color: const Color(0xFF64FFDA),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biometric Scanner Interfaces',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isBle ? 'Wireless BLE Biometric Node' : 'Wired USB OTG Serial (115200 Baud)',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF80CBC4)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh Endpoints',
                icon: const Icon(Icons.refresh, color: Color(0xFF64FFDA)),
                onPressed: widget.onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1315),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00382E)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (isBle) widget.onModeChanged(IotTransportMode.usbOtg);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !isBle ? const Color(0xFF004D40) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.usb, size: 16, color: !isBle ? Colors.white : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Wired USB OTG',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !isBle ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (!isBle) widget.onModeChanged(IotTransportMode.ble);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isBle ? const Color(0xFF004D40) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth, size: 16, color: isBle ? Colors.white : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Wireless BLE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isBle ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1315),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00382E)),
            ),
            child: Row(
              children: [
                Icon(
                  isBle ? Icons.cell_tower : Icons.info_outline,
                  color: const Color(0xFF64FFDA),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBle
                        ? 'Broadcasting as "MediScanAI_Node" (UUID: 4fafc201-1fb5-459e-8fcc-c5c9c331914b)'
                        : 'Connect via USB-OTG adapter. Default CDC baud rate is 115200 8N1.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFB2DFDB)),
                  ),
                ),
              ],
            ),
          ),

          if (!isBle) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Baud Rate:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  dropdownColor: const Color(0xFF162325),
                  value: _selectedBaudRate,
                  isDense: true,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: _baudRates.map((rate) {
                    return DropdownMenuItem<int>(
                      value: rate,
                      child: Text('$rate baud ${rate == 115200 ? "(Standard)" : ""}',
                          style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBaudRate = val);
                  },
                ),
              ],
            ),
          ],

          const Divider(height: 20, color: Color(0xFF00382E)),

          Text(
            isBle ? 'Discovered BLE Biometric Nodes:' : 'Available USB Serial Endpoints:',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),

          Flexible(
            child: widget.ports.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBle ? Icons.bluetooth_disabled : Icons.usb_off,
                            size: 36,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isBle ? 'No BLE peripherals detected nearby.' : 'No USB CDC devices detected on bus.',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBle
                                ? 'Ensure Biometric Scanner is powered on with BLE broadcasting.'
                                : 'Connect Biometric Scanner via USB OTG cable with data lines enabled.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.ports.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFF00382E)),
                    itemBuilder: (context, index) {
                      final port = widget.ports[index];
                      final isCurrent = (widget.selectedPort?.deviceName == port.deviceName ||
                              widget.selectedPort?.bleDeviceId == port.bleDeviceId) &&
                          widget.isConnected;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        leading: CircleAvatar(
                          backgroundColor: isCurrent ? const Color(0xFF00E676) : const Color(0xFF00382E),
                          child: Icon(
                            isBle ? Icons.bluetooth_connected : (port.isEsp32 ? Icons.memory : Icons.usb),
                            color: isCurrent ? Colors.black : const Color(0xFF64FFDA),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          port.displayTitle,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          port.displaySubtitle,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF80CBC4)),
                        ),
                        trailing: isCurrent
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade900.withValues(alpha: 0.5),
                                  foregroundColor: Colors.red.shade200,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                onPressed: () {
                                  widget.onDisconnect();
                                  Navigator.pop(context);
                                },
                                child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004D40),
                                  foregroundColor: const Color(0xFF64FFDA),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: () {
                                  widget.onConnect(port, _selectedBaudRate);
                                  Navigator.pop(context);
                                },
                                child: const Text('Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
