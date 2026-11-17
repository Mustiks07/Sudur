package kz.sudur.sudur

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sudur/prototype")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "root" -> {
                            val base = getExternalFilesDir(null)
                                ?: throw IllegalStateException("External storage unavailable")
                            val root = File(base, "prototype")
                            if (!root.exists() && !root.mkdirs()) throw IllegalStateException("Cannot create directory")
                            result.success(root.absolutePath)
                        }
                        "share" -> {
                            val json = call.arguments as? String
                                ?: throw IllegalArgumentException("Expected JSON")
                            val directory = File(cacheDir, "prototype-reports")
                            directory.mkdirs()
                            val file = File(directory, "sudur-timing.json")
                            file.writeText(json)
                            val uri = FileProvider.getUriForFile(this, "$packageName.reports", file)
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "application/json"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                clipData = android.content.ClipData.newRawUri("timing", uri)
                            }
                            startActivity(Intent.createChooser(intent, null))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("prototypePlatformFailed", "Operation failed", null)
                }
            }
    }
}
