package com.ceri.fitcall

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
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
        private const val INDIRME_KANALI = "fitcall/indirme"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INDIRME_KANALI)
            .setMethodCallHandler { cagri, sonuc ->
                when (cagri.method) {
                    "kaydet" -> sonuc.success(
                        indirilenlereKaydet(
                            cagri.argument<String>("ad") ?: "dosya",
                            cagri.argument<ByteArray>("baytlar") ?: ByteArray(0),
                            cagri.argument<String>("tur") ?: "application/octet-stream",
                        )
                    )
                    "ac" -> sonuc.success(
                        dosyayiAc(
                            cagri.argument<String>("uri") ?: "",
                            cagri.argument<String>("tur") ?: "*/*",
                        )
                    )
                    else -> sonuc.notImplemented()
                }
            }
    }

    /**
     * Dosyayı telefonun "İndirilenler" klasörüne yazar, içerik adresini döner.
     * Android 10+ MediaStore ile izin istemeden yazar; aynı ad varsa sistem
     * "(1)" ekler. Android 9 ve altında (depolama izni gerekir) ya da hata
     * olursa null döner; Flutter tarafı paylaşım menüsüne düşer.
     */
    private fun indirilenlereKaydet(ad: String, baytlar: ByteArray, tur: String): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        return try {
            val cozucu = contentResolver
            val degerler = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, ad)
                put(MediaStore.MediaColumns.MIME_TYPE, tur)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = cozucu.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, degerler)
                ?: return null
            val yazildi = cozucu.openOutputStream(uri)?.use { it.write(baytlar); true } ?: false
            if (!yazildi) {
                cozucu.delete(uri, null, null)
                return null
            }
            degerler.clear()
            degerler.put(MediaStore.MediaColumns.IS_PENDING, 0)
            cozucu.update(uri, degerler, null, null)
            uri.toString()
        } catch (e: Exception) {
            null
        }
    }

    /** İndirilen dosyayı telefondaki uygun uygulamayla açar; yoksa false. */
    private fun dosyayiAc(uri: String, tur: String): Boolean {
        if (uri.isEmpty()) return false
        return try {
            val niyet = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.parse(uri), tur)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(niyet)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: Exception) {
            false
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
