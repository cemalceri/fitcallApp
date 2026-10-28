import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/core/app_check_service.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/fcm_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/notification/notification_fcm_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    AppCheckServisi.istemciBasliklari()
        .then((b) => ApiClient.istemciBasliklari = b),
  ]);
  // App Check token'ı her API isteğine eklenir (bkz. app_check_service.dart).
  await AppCheckServisi.baslat();
  ApiClient.appCheckTokeni = AppCheckServisi.token;
  await NotificationFCMService.instance.initialize();
  initFCMTokenListener();
  // Sunucu token'ı reddedince (401) giriş ekranına dön
  ApiClient.oturumDustu = (token) =>
      AuthService.oturumDustu(navigatorKey, reddedilenToken: token);
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
    // Mod ve renk teması ayrı tercihler; ikisinden biri değişince yeniden kurulur.
    return ListenableBuilder(
      listenable: Listenable.merge([TemaKontrol.modu, TemaKontrol.takim]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'Binay Akademi',
        theme: FitcallTema.temasi(TemaKontrol.takim.value, Brightness.light),
        darkTheme: FitcallTema.temasi(TemaKontrol.takim.value, Brightness.dark),
        themeMode: TemaKontrol.modu.value,
        onGenerateRoute: myRouteGenerator,
        initialRoute: '/',
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Yazı ölçeğini uygulama genelinde makul üst sınıra çek (bkz. ui_scale.dart)
        builder: yaziOlceginiSinirla,
      ),
    );
  }
}
