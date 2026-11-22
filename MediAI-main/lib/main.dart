import 'dart:async';
import 'dart:developer';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/services/auth_service.dart';
import 'core/services/iot_vitals_service.dart';
import 'core/services/locale_service.dart';
import 'core/services/patient_profile_service.dart';
import 'features/features.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleService.init();
  await PatientProfileService.init();
  await AuthService.init();
  await IotVitalsService.instance.init();

  try {
    await Firebase.initializeApp();

    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidDebugProvider(
        debugToken: "4F3F1C87-B4EB-4A2E-8646-D2A3C0F99D20",
      ),
    );
  } catch (e) {
    log('[MediAI] Firebase / App Check configuration notice: $e');
  }

  runApp(const MediScanApp());
}

class MediScanApp extends StatelessWidget {
  const MediScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => SkinTriageRepositoryImpl(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TriageBloc>(
            create: (context) =>
                TriageBloc(repository: context.read<SkinTriageRepositoryImpl>()),
          ),
          BlocProvider<ClinicalSessionBloc>(
            create: (_) => ClinicalSessionBloc(),
          ),
        ],
        child: ValueListenableBuilder<Locale>(
          valueListenable: LocaleService.currentLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'MediScanAI',
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ur')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                useMaterial3: true,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF004D40),
                  primary: const Color(0xFF004D40),
                  secondary: const Color(0xFF00796B),
                  surface: Colors.white,
                ),
                scaffoldBackgroundColor: const Color(0xFFF7F9FA),
                cardTheme: CardThemeData(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                appBarTheme: const AppBarTheme(
                  elevation: 0,
                  centerTitle: false,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark,
                  ),
                ),
                chipTheme: ChipThemeData(
                  backgroundColor: Colors.transparent,
                  selectedColor: const Color(0xFF00796B),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                final isAndroid =
                    defaultTargetPlatform == TargetPlatform.android;

                if (!isAndroid) {
                  return child ?? const SizedBox.shrink();
                }

                final double screenWidth = mediaQuery.size.width;
                final double widthFactor = (screenWidth / 380.0).clamp(
                  0.82,
                  1.0,
                );
                final double baseScale = 0.88 * widthFactor;
                final double systemScale = mediaQuery.textScaler.scale(1.0);
                final double finalScale = (systemScale * baseScale).clamp(
                  0.76,
                  1.02,
                );

                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(finalScale),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const AnimatedSplashPage(),
            );
          },
        ),
      ),
    );
  }
}
