import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';
import 'package:fitcall/services/core/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/1_notification/notification_fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr', null);

  NotificationService.instance.registerNavigatorKey(navigatorKey);
  await NotificationService.instance.initialize();

  await PendingActionStore.instance.load();
  initFCMTokenListener();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
