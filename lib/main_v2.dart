import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitcall/v2/shared/services/notification_service.dart'; // V2'de notification servisi
import 'package:fitcall/v2/router/routes.dart'; // V2 router
import 'package:fitcall/v2/theme/app_theme.dart'; // Yeni oluşturduğumuz tema

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr', null);
  await NotificationService.instance.initialize();
  runApp(const MyAppV2());
}

class MyAppV2 extends StatelessWidget {
  const MyAppV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Binay Akademi V2',
      theme: AppTheme.lightTheme, // V2 temamızı kullandık
      onGenerateRoute: v2RouteGenerator, // V2 route generator
      initialRoute: '/', // İlk açılacak ekran (V2 login veya başka bir ekran)
    );
  }
}
