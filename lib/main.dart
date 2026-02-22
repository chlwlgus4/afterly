import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const forceAppCheckDebug = bool.fromEnvironment(
    'FORCE_APP_CHECK_DEBUG',
    defaultValue: false,
  );
  debugPrint('kDebugMode=$kDebugMode');
  debugPrint('forceAppCheckDebug=$forceAppCheckDebug');
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        (kDebugMode || forceAppCheckDebug)
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
    appleProvider:
        (kDebugMode || forceAppCheckDebug)
            ? AppleProvider.debug
            : AppleProvider.deviceCheck,
  );
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: AfterlyApp()));
}
