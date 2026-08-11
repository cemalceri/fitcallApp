import 'package:fitcall/services/core/fcm_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/notification/notification_fcm_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/common/ui_scale.dart';
import 'package:fitcall/services/core/tema_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tarih formatları Firebase'den bağımsız; ilk kareyi geciktirmemek için
  // ikisi paralel başlatılır. FCM init Firebase'e bağlı olduğu için sonra gelir.
  await Future.wait([
    Firebase.initializeApp(),
    initializeDateFormatting('tr', null),
    // Tema tercihi ilk kareden önce okunmalı; yoksa uygulama açık temada
    // açılıp anında koyuya geçer (göz yoran bir çakma).
    TemaKontrol.yukle(),
  ]);
  await NotificationFCMService.instance.initialize();
  initFCMTokenListener();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Navigator hazır olduktan sonra FCM'i kaydet ve initial message'ı işle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationFCMService.instance.registerNavigatorKey(navigatorKey);
      NotificationFCMService.instance.handleInitialMessage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Arka plandayken gelen bildirimler rozeti tahmini olarak artırmıştı;
    // dönüşte sunucudaki gerçek sayı ile düzeltilir.
    if (state == AppLifecycleState.resumed) {
      _okunmamisSayisiniTazele();
    }
  }

  Future<void> _okunmamisSayisiniTazele() async {
    if (!await StorageService.tokenGecerliMi()) return;
    try {
      await NotificationService.refreshUnreadCount();
    } catch (_) {
      // Ağ yoksa mevcut rozet olduğu gibi korunur.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaKontrol.modu,
      builder: (context, temaModu, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'Binay Akademi',
        theme: FitcallTema.acik,
        darkTheme: FitcallTema.koyu,
        themeMode: temaModu,
        onGenerateRoute: myRouteGenerator,
        initialRoute: '/',
        // Yazı ölçeğini uygulama genelinde makul üst sınıra çek (bkz. ui_scale.dart)
        builder: yaziOlceginiSinirla,
      ),
    );
  }
}
