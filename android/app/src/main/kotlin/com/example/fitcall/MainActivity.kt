package com.ceri.fitcall

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val PARLAKLIK_KANALI = "fitcall/ekran_parlaklik"
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
