import 'package:fitcall/services/core/fcm_service.dart';
import 'package:fitcall/services/notification/notification_fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitcall/common/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr', null);
  await NotificationFCMService.instance.initialize();
  initFCMTokenListener();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Navigator hazır olduktan sonra FCM'i kaydet ve initial message'ı işle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationFCMService.instance.registerNavigatorKey(navigatorKey);
      NotificationFCMService.instance.handleInitialMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Binay Akademi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      onGenerateRoute: myRouteGenerator,
      initialRoute: '/',
    );
  }
}
