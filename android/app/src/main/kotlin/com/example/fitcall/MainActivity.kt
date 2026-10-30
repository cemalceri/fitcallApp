package com.ceri.fitcall

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: enableEdgeToEdge() ComponentActivity ister,
// düz FlutterActivity'de yok.
class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val PARLAKLIK_KANALI = "fitcall/ekran_parlaklik"
    }

    /**
     * Play Console "uçtan uca ekran" önerisi: Android 15+ zaten uçtan uca;
     * bu çağrı eski sürümleri de aynı düzene alır (sistem çubuklarının
     * altına çizim, boşluğu Flutter'daki SafeArea/Scaffold verir).
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PARLAKLIK_KANALI)
            .setMethodCallHandler { cagri, sonuc ->
                when (cagri.method) {
                    "maksimumaAl" ->
                        sonuc.success(pencereParlakligiAyarla(1.0f))
                    "eskiHalineDondur" ->
                        sonuc.success(
                            pencereParlakligiAyarla(
                                WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                            )
                        )
                    else -> sonuc.notImplemented()
                }
            }
    }

    /**
     * Yalnızca uygulamanın kendi penceresinin parlaklığını değiştirir.
     * Sistem ayarına dokunulmadığı için WRITE_SETTINGS gibi bir izin gerekmez
     * ve uygulama kapanınca cihaz otomatik olarak kullanıcı ayarına döner.
     *
     * BRIGHTNESS_OVERRIDE_NONE (-1f) gönderilirse override kaldırılır.
     * Başarısız olursa false döner; Flutter tarafı bu durumda sayfayı mevcut
     * parlaklıkla göstermeye devam eder.
     */
    private fun pencereParlakligiAyarla(deger: Float): Boolean {
        return try {
            val pencere = window ?: return false
            val ayarlar = pencere.attributes
            ayarlar.screenBrightness = deger
            pencere.attributes = ayarlar
            true
        } catch (e: Exception) {
            false
        }
    }
}
