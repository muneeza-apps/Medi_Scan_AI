import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/iot_vitals_model.dart';
import '../../../../core/services/iot_vitals_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../data/repositories/iot_serial_repository_impl.dart';
import '../../domain/entities/iot_telemetry_entity.dart';
import '../../domain/entities/usb_port_info_entity.dart';
import '../../domain/usecases/iot_serial_usecases.dart';
import '../bloc/clinical_session/clinical_session_bloc.dart';
import '../bloc/clinical_session/clinical_session_event.dart';
import '../bloc/usb_serial_bloc.dart';
import '../bloc/usb_serial_event.dart';
import '../bloc/usb_serial_state.dart';
import '../widgets/finger_detection_banner.dart';
import '../widgets/live_ppg_waveform_painter.dart';
import '../widgets/usb_device_selector_sheet.dart';
import '../widgets/vitals_metric_card.dart';

class IotVitalsPage extends StatelessWidget {
  const IotVitalsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return RepositoryProvider<IotSerialRepositoryImpl>(
      create: (_) => IotSerialRepositoryImpl(),
      child: Builder(
        builder: (repoContext) {
          final repo = repoContext.read<IotSerialRepositoryImpl>();
          return BlocProvider<UsbSerialBloc>(
            create: (_) => UsbSerialBloc(
              getPortsUseCase: GetUsbPortsUseCase(repo),
              connectUseCase: ConnectUsbSerialUseCase(repo),
              disconnectUseCase: DisconnectUsbSerialUseCase(repo),
              switchTransportModeUseCase: SwitchTransportModeUseCase(repo),
              watchTelemetryUseCase: WatchUsbTelemetryUseCase(repo),
              watchStatusUseCase: WatchUsbStatusUseCase(repo),
              watchRawLogsUseCase: WatchUsbRawLogsUseCase(repo),
              sendCommandUseCase: SendUsbCommandUseCase(repo),
            )..add(const UsbSerialStarted()),
            child: const _IotVitalsView(),
          );
        },
      ),
    );
  }
}

class _IotVitalsView extends StatefulWidget {
  const _IotVitalsView();

  @override
  State<_IotVitalsView> createState() => _IotVitalsViewState();
}

class _IotVitalsViewState extends State<_IotVitalsView> {
  bool _useFahrenheit = false;

  void _showDeviceSelector(BuildContext context, UsbSerialState state) {
    final bloc = context.read<UsbSerialBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocBuilder<UsbSerialBloc, UsbSerialState>(
          bloc: bloc,
          builder: (ctx, currentState) {
            return UsbDeviceSelectorSheet(
              ports: currentState.availablePorts,
              selectedPort: currentState.selectedPort,
              activeMode: currentState.activeTransportMode,
              isConnected: currentState.isConnected,
              onModeChanged: (mode) => bloc.add(SwitchIotTransportMode(mode)),
              onConnect: (port, baudRate) {
                bloc.add(ConnectUsbPort(port: port, baudRate: baudRate));
              },
              onDisconnect: () => bloc.add(const DisconnectUsbPort()),
              onRefresh: () => bloc.add(RefreshUsbPorts(mode: currentState.activeTransportMode)),
            );
          },
        );
      },
    );
  }

  void _attachVitalsToRecord(
    BuildContext context,
    UsbSerialState state,
    bool isUrdu,
  ) {
    final snapshot = state.activeOrLockedSnapshot;
    if (snapshot == null || snapshot.heartRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'کوئی فعال یا محفوظ شدہ وائٹلز سگنل نہیں ہے۔ براہ کرم بائیو میٹرک سنسر پر انگلی رکھیں۔'
                : 'No active or locked vitals signal. Place finger gently on the biometric scanner before attaching to clinical record.',
          ),
          backgroundColor: Colors.amber.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<ClinicalSessionBloc>().add(AttachVitalsSnapshot(snapshot));

    final vitals = IotVitalsReading(
      heartRate: snapshot.heartRate,
      spo2: snapshot.spo2,
      temperatureCelsius: snapshot.temperature,
      timestamp: snapshot.capturedAt,
      deviceId: 'BIOMETRIC-SCANNER',
      deviceName: 'MediScanAI Biometric Scanner',
      hardwareNode: 'Clinical Biometric Module',
    );
    IotVitalsService.instance.recordExternalVitals(vitals);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF64FFDA), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUrdu
                    ? 'کلینیکل وائٹلز کامیابی کے ساتھ سیشن سے منسلک ہو گئے (${snapshot.heartRate} BPM • ${snapshot.spo2}% SpO₂ • ${snapshot.temperature.toStringAsFixed(1)}°C)'
                    : 'Clinical Vitals attached to active session (${snapshot.heartRate} BPM • ${snapshot.spo2}% SpO₂ • ${snapshot.temperature.toStringAsFixed(1)}°C)',
                style: const TextStyle(fontSize: 12.5, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00382E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF004D40)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';

        return BlocConsumer<UsbSerialBloc, UsbSerialState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red.shade900,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final isConnected = state.isConnected;
            final isStreaming = state.isStreaming;
            final hasFinger = state.hasFinger;
            final isBle = state.activeTransportMode == IotTransportMode.ble;
            final hasLocked = state.hasLockedSnapshot;
            final locked = state.lockedSnapshot;

            final telemetry = state.currentTelemetry ??
                IotTelemetryEntity(
                  finger: false,
                  bpm: 0,
                  spo2: 0,
                  temp: 0.0,
                  status: isConnected ? 'AWAITING_FINGER' : 'DISCONNECTED',
                  timestamp: DateTime.now(),
                );

            final canAttach = (isConnected && hasFinger && telemetry.bpm > 0) || hasLocked;

            return Directionality(
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: const Color(0xFF0B1315),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF0B1315),
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: Color(0xFF00382E)),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          isUrdu ? 'طبی IoT وائٹلز مانیٹر' : 'Clinical IoT Vitals Hub',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isStreaming
                              ? const Color(0xFF00E676).withValues(alpha: 0.2)
                              : isConnected
                                  ? const Color(0xFFFFD600).withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isStreaming
                                ? const Color(0xFF00E676)
                                : isConnected
                                    ? const Color(0xFFFFD600)
                                    : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isStreaming
                                    ? const Color(0xFF00E676)
                                    : isConnected
                                        ? const Color(0xFFFFD600)
                                        : Colors.grey.shade500,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isStreaming
                                  ? (isBle ? 'BLE STREAMING' : 'CDC STREAMING')
                                  : isConnected
                                      ? (isBle ? 'BLE CONNECTED' : 'CDC CONNECTED')
                                      : 'DISCONNECTED',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isStreaming
                                    ? const Color(0xFF00E676)
                                    : isConnected
                                        ? const Color(0xFFFFD600)
                                        : Colors.white70,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: isBle ? 'Wireless BLE Devices' : 'USB Serial Device Settings',
                      icon: Icon(
                        isBle ? Icons.bluetooth_searching : Icons.usb,
                        color: const Color(0xFF64FFDA),
                      ),
                      onPressed: () => _showDeviceSelector(context, state),
                    ),
                  ],
                ),
                body: RefreshIndicator(
                  color: const Color(0xFF00BFA5),
                  backgroundColor: const Color(0xFF111C1E),
                  onRefresh: () async {
                    context.read<UsbSerialBloc>().add(RefreshUsbPorts(mode: state.activeTransportMode));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        _buildTransportModeSelector(context, state),
                        const SizedBox(height: 12),

                        _buildHardwareBar(context, state, isUrdu),
                        const SizedBox(height: 12),

                        FingerDetectionBanner(
                          hasFinger: hasFinger,
                          status: telemetry.status,
                          signalQuality: telemetry.signalQualityPercent,
                          isDarkMode: true,
                        ),
                        const SizedBox(height: 14),

                        if (!hasFinger && hasLocked) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00382E).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF00E676), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF004D40),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_clock, color: Color(0xFF64FFDA), size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'SESSION CAPTURED • LOCKED',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF69F0AE),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Captured at ${locked!.formattedCaptureTime} • Measurements frozen for clinical record',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFB2DFDB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        LivePpgWaveformWidget(
                          telemetryHistory: state.telemetryHistory,
                          bpm: hasFinger ? telemetry.bpm : (hasLocked ? locked!.heartRate : 0),
                          isFingerDetected: isConnected && hasFinger,
                          isMeasuring: isStreaming,
                          primaryColor: const Color(0xFF00E5FF),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: VitalsMetricCard(
                                title: isUrdu ? 'دل کی دھڑکن' : 'Heart Rate',
                                value: isConnected && hasFinger && telemetry.bpm > 0
                                    ? '${telemetry.bpm}'
                                    : (hasLocked ? '${locked!.heartRate}' : '--'),
                                unit: 'BPM',
                                status: isConnected && hasFinger && telemetry.bpm > 0
                                    ? (telemetry.isTachycardic
                                        ? 'Tachycardia'
                                        : telemetry.isBradycardic
                                            ? 'Bradycardia'
                                            : 'Normal Rhythm')
                                    : (hasLocked
                                        ? 'SESSION CAPTURED • LOCKED'
                                        : (isConnected ? 'NO SENSOR CONTACT' : 'Disconnected')),
                                icon: Icons.favorite,
                                themeColor: const Color(0xFFFF5252),
                                bgTint: const Color(0xFFFF5252),
                                isAlert: isConnected && hasFinger
                                    ? (telemetry.isTachycardic || telemetry.isBradycardic)
                                    : (hasLocked && (locked!.isTachycardic || locked.isBradycardic)),
                                isNoSignal: (!isConnected || !hasFinger) && !hasLocked,
                                isDarkMode: true,
                                normalRange: '60 - 100',
                                trailingBadge: hasLocked && !hasFinger
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF004D40),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF00E676), width: 0.6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock, size: 9, color: Color(0xFF69F0AE)),
                                            SizedBox(width: 2),
                                            Text(
                                              'LOCKED',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF69F0AE),
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: VitalsMetricCard(
                                title: isUrdu ? 'خون میں آکسیجن' : 'Oxygen Saturation',
                                value: isConnected && hasFinger && telemetry.spo2 > 0
                                    ? '${telemetry.spo2}'
                                    : (hasLocked ? '${locked!.spo2}' : '--'),
                                unit: '% SpO₂',
                                status: isConnected && hasFinger && telemetry.spo2 > 0
                                    ? (telemetry.isHypoxic ? 'Hypoxia Warning' : 'Optimal Saturation')
                                    : (hasLocked
                                        ? 'SESSION CAPTURED • LOCKED'
                                        : (isConnected ? 'NO SENSOR CONTACT' : 'Disconnected')),
                                icon: Icons.water_drop,
                                themeColor: const Color(0xFF00E5FF),
                                bgTint: const Color(0xFF00BFA5),
                                isAlert: isConnected && hasFinger
                                    ? telemetry.isHypoxic
                                    : (hasLocked && locked!.isHypoxic),
                                isNoSignal: (!isConnected || !hasFinger) && !hasLocked,
                                isDarkMode: true,
                                normalRange: '> 95%',
                                trailingBadge: hasLocked && !hasFinger
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF004D40),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF00E676), width: 0.6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock, size: 9, color: Color(0xFF69F0AE)),
                                            SizedBox(width: 2),
                                            Text(
                                              'LOCKED',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF69F0AE),
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        VitalsMetricCard(
                          title: isUrdu ? 'جسم کا درجہ حرارت (پیریفرل)' : 'Peripheral Body Temperature',
                          value: isConnected && hasFinger && telemetry.temp > 0.0
                              ? (_useFahrenheit
                                  ? telemetry.tempFahrenheit.toStringAsFixed(1)
                                  : telemetry.temp.toStringAsFixed(1))
                              : (hasLocked
                                  ? (_useFahrenheit
                                      ? locked!.temperatureFahrenheit.toStringAsFixed(1)
                                      : locked!.temperature.toStringAsFixed(1))
                                  : '--'),
                          unit: _useFahrenheit ? '°F' : '°C',
                          status: isConnected && hasFinger && telemetry.temp > 0.0
                              ? (telemetry.isFebrile
                                  ? 'Fever Alert'
                                  : (telemetry.isPeripheralHypothermia
                                      ? 'Severe Hypothermia'
                                      : (telemetry.temp < 29.5 ? 'Cool Periphery' : 'Normal Peripheral Temp')))
                              : (hasLocked
                                  ? 'SESSION CAPTURED • LOCKED'
                                  : (isConnected ? 'NO SENSOR CONTACT' : 'Disconnected')),
                          icon: Icons.thermostat,
                          themeColor: const Color(0xFFFFA726),
                          bgTint: const Color(0xFFFFA726),
                          isAlert: isConnected && hasFinger
                              ? (telemetry.isFebrile || telemetry.isPeripheralHypothermia)
                              : (hasLocked && (locked!.isFebrile || locked.isPeripheralHypothermia)),
                          isNoSignal: (!isConnected || !hasFinger) && !hasLocked,
                          isDarkMode: true,
                          normalRange: _useFahrenheit ? '85.1 - 97.2°F' : '29.5 - 36.2°C',
                          trailingBadge: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasLocked && !hasFinger) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF004D40),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF00E676), width: 0.6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, size: 9, color: Color(0xFF69F0AE)),
                                      SizedBox(width: 2),
                                      Text(
                                        'LOCKED',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF69F0AE),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              InkWell(
                                onTap: () => setState(() => _useFahrenheit = !_useFahrenheit),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA726).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFFA726), width: 0.8),
                                  ),
                                  child: Text(
                                    _useFahrenheit ? 'Switch to °C' : 'Switch to °F',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFA726),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildClinicalAdvisoryCard(state, telemetry, isUrdu),
                        const SizedBox(height: 14),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canAttach ? const Color(0xFF004D40) : const Color(0xFF162325),
                              foregroundColor: canAttach ? const Color(0xFF64FFDA) : Colors.grey.shade600,
                              side: BorderSide(
                                color: canAttach ? const Color(0xFF00BFA5) : const Color(0xFF00382E),
                                width: 1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: canAttach ? 2 : 0,
                            ),
                            onPressed: canAttach
                                ? () => _attachVitalsToRecord(context, state, isUrdu)
                                : null,
                            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                            label: Text(
                              isUrdu
                                  ? 'وائٹلز کو کلینیکل ریکارڈ اور AI ٹرائیج سے منسلک کریں'
                                  : 'Attach Vitals to Clinical Record & AI Triage',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: canAttach ? Colors.white : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransportModeSelector(BuildContext context, UsbSerialState state) {
    final isBle = state.activeTransportMode == IotTransportMode.ble;
    final bloc = context.read<UsbSerialBloc>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00382E), width: 1.2),
      ),
      child: Row(
        children: [

          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (isBle) {
                  bloc.add(const SwitchIotTransportMode(IotTransportMode.usbOtg));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !isBle ? const Color(0xFF004D40) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isBle
                      ? [
                          BoxShadow(
                            color: const Color(0xFF004D40).withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.usb,
                      size: 16,
                      color: !isBle ? const Color(0xFF64FFDA) : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Wired USB OTG',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: !isBle ? Colors.white : Colors.grey.shade400,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                if (!isBle) {
                  bloc.add(const SwitchIotTransportMode(IotTransportMode.ble));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isBle ? const Color(0xFF004D40) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isBle
                      ? [
                          BoxShadow(
                            color: const Color(0xFF004D40).withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth,
                      size: 16,
                      color: isBle ? const Color(0xFF64FFDA) : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Wireless BLE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isBle ? Colors.white : Colors.grey.shade400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareBar(BuildContext context, UsbSerialState state, bool isUrdu) {
    final isConnected = state.isConnected;
    final isBle = state.activeTransportMode == IotTransportMode.ble;
    final deviceTitle = state.selectedPort?.displayTitle ??
        (isBle ? 'MediScanAI Biometric Node (Wireless BLE)' : 'MediScanAI Biometric Hub (USB Serial)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00382E)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF004D40) : const Color(0xFF162325),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBle ? Icons.bluetooth_connected : Icons.sensors,
              color: isConnected ? const Color(0xFF64FFDA) : Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  deviceTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected
                      ? (isBle
                          ? (isUrdu ? 'وائرلیس BLE بائیو میٹرک فعال ہے' : 'Connected via Wireless BLE')
                          : (isUrdu ? 'یو ایس بی او ٹی جی فعال ہے' : 'Connected via USB OTG (115200 Baud)'))
                      : (isUrdu
                          ? (isBle ? 'کوئی BLE ڈیوائس منسلک نہیں' : 'کوئی یو ایس بی ڈیوائس منسلک نہیں')
                          : (isBle
                              ? 'Scan & Connect Biometric Node via BLE'
                              : 'Connect via USB-OTG @ 115200 baud')),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF80CBC4),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isConnected)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: const Color(0xFFFF8A80),
                side: BorderSide(color: Colors.red.shade900.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              onPressed: () {
                context.read<UsbSerialBloc>().add(const DisconnectUsbPort());
              },
              child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                foregroundColor: const Color(0xFF64FFDA),
                visualDensity: VisualDensity.compact,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              onPressed: () => _showDeviceSelector(context, state),
              child: Text(
                isBle ? 'Scan BLE' : 'Connect USB',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClinicalAdvisoryCard(UsbSerialState state, IotTelemetryEntity telemetry, bool isUrdu) {
    final bool hasFinger = telemetry.finger;
    final bool isCritical = telemetry.isCritical;
    final bool hasLocked = state.hasLockedSnapshot;
    final locked = state.lockedSnapshot;

    Color cardBg = const Color(0xFF0D231A);
    Color borderColor = const Color(0xFF1B5E20);
    Color iconColor = const Color(0xFF69F0AE);
    IconData icon = Icons.check_circle_outline;
    String title = 'Vitals Within Normal Physiological Baseline';
    String description =
        'Heart rate, SpO₂ saturation, and peripheral body temperature are stable with normal hemodynamics.';

    if (!hasFinger && hasLocked) {
      cardBg = const Color(0xFF0F261D);
      borderColor = const Color(0xFF00E676);
      iconColor = const Color(0xFF69F0AE);
      icon = Icons.lock_clock;
      title = 'Session Captured & Locked';
      description =
          'Clinical vitals securely frozen at ${locked!.formattedCaptureTime} (${locked.heartRate} BPM, ${locked.spo2}% SpO₂, ${locked.temperature.toStringAsFixed(1)}°C). Ready to attach to clinical record.';
    } else if (!hasFinger) {
      cardBg = const Color(0xFF162325);
      borderColor = const Color(0xFF00382E);
      iconColor = const Color(0xFF80CBC4);
      icon = Icons.info_outline;
      title = 'Biometric Scanner Standby';
      description =
          'Place finger gently on the biometric scanner. Real-time telemetry evaluates vitals every 500ms.';
    } else if (isCritical) {
      cardBg = const Color(0xFF281113);
      borderColor = Colors.red.shade900;
      iconColor = const Color(0xFFFF5252);
      icon = Icons.warning_amber_rounded;
      title = 'Clinical Vitals Advisory Warning';

      final issues = <String>[];
      if (telemetry.isHypoxic) issues.add('Low Blood Oxygen (${telemetry.spo2}%)');
      if (telemetry.isTachycardic) issues.add('Elevated Heart Rate (${telemetry.bpm} BPM)');
      if (telemetry.isBradycardic) issues.add('Low Heart Rate (${telemetry.bpm} BPM)');
      if (telemetry.isFebrile) issues.add('Elevated Temperature (${telemetry.temp}°C)');
      if (telemetry.isPeripheralHypothermia) issues.add('Severe Peripheral Cold / Hypothermia (${telemetry.temp}°C)');
      description = 'Detected abnormalities: ${issues.join(", ")}. Immediate medical attention recommended.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB2DFDB),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
