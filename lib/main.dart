import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitcall/screens/1_common/1_notification/notification_fcm_service.dart';
import 'package:fitcall/common/routes.dart'; // Burada myRouteGenerator var

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr', null);
  await NotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Binay Akademi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Artık 'routes:' yerine 'onGenerateRoute:' kullanıyoruz
      onGenerateRoute: myRouteGenerator,
      initialRoute: '/', // uygulama açılınca login (/) ekranı
    );
  }
}
