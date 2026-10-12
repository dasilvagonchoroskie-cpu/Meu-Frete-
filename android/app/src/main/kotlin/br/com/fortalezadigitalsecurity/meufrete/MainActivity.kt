package br.com.fortalezadigitalsecurity.meufrete

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Licenca da Central (so e usada no APK de venda direta): o codigo do
        // aparelho sai do ANDROID_ID, que so muda se a chave do APK mudar.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fortaleza/licenca")
            .setMethodCallHandler { chamada, resultado ->
                when (chamada.method) {
                    "idDoAparelho" -> {
                        val id = try {
                            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                        } catch (erro: Exception) {
                            null
                        }
                        resultado.success(id ?: "")
                    }
                    "modelo" -> resultado.success("${Build.MANUFACTURER} ${Build.MODEL}".trim())
                    else -> resultado.notImplemented()
                }
            }
    }
}
