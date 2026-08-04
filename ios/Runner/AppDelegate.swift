import Flutter
import UIKit
import firebase_messaging

@main
@objc class AppDelegate: FlutterAppDelegate {

  /// QR sayfasında ekranı maksimuma almak için kullanılan kanal.
  private let parlaklikKanalAdi = "fitcall/ekran_parlaklik"

  /// Kullanıcının sayfaya girmeden önceki parlaklığı; çıkışta geri yüklenir.
  private var oncekiParlaklik: CGFloat?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // iOS 10+ için foreground notification desteği
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    parlaklikKanaliniKur()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func parlaklikKanaliniKur() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      // Kanal kurulamazsa Flutter tarafındaki çağrılar hata döner ve sayfa
      // mevcut parlaklıkla çalışmaya devam eder.
      return
    }

    let kanal = FlutterMethodChannel(
      name: parlaklikKanalAdi,
      binaryMessenger: controller.binaryMessenger
    )

    kanal.setMethodCallHandler { [weak self] cagri, sonuc in
      guard let self = self else {
        sonuc(false)
        return
      }
      switch cagri.method {
      case "maksimumaAl":
        sonuc(self.parlakligiMaksimumaAl())
      case "eskiHalineDondur":
        sonuc(self.parlakligiGeriAl())
      default:
        sonuc(FlutterMethodNotImplemented)
      }
    }
  }

  /// iOS'ta ekran parlaklığı için ayrı bir izin gerekmez, ancak değişiklik
  /// sistem geneline uygulanır; bu yüzden önceki değer saklanır.
  private func parlakligiMaksimumaAl() -> Bool {
    if oncekiParlaklik == nil {
      oncekiParlaklik = UIScreen.main.brightness
    }
    UIScreen.main.brightness = 1.0
    return true
  }

  /// Saklanan değer yoksa (zaten geri alınmışsa) false döner; yapılacak bir şey
  /// olmadığı için Flutter tarafı bunu yok sayar.
  private func parlakligiGeriAl() -> Bool {
    guard let eski = oncekiParlaklik else { return false }
    UIScreen.main.brightness = eski
    oncekiParlaklik = nil
    return true
  }
}
