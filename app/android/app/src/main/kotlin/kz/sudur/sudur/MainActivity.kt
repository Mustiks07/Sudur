package kz.sudur.sudur

import android.app.Activity
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "kz.sudur/prototype"
    private val pickWavRequest = 5808
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler(::handlePrototypeCall)
    }

    private fun handlePrototypeCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "applicationDirectory" -> {
                val directory = File(filesDir, "prototype").apply { mkdirs() }
                result.success(directory.absolutePath)
            }
            "pickWav" -> pickWav(result)
            "shareFile" -> shareFile(call, result)
            else -> result.notImplemented()
        }
    }

    private fun pickWav(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("pickerBusy", "A WAV picker is already open.", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("audio/wav", "audio/x-wav"))
        }
        startActivityForResult(intent, pickWavRequest)
    }

    private fun shareFile(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("missingPath", "A log path is required.", null)
            return
        }
        val file = File(path)
        val allowedRoot = File(filesDir, "prototype").canonicalFile
        if (!file.canonicalFile.toPath().startsWith(allowedRoot.toPath()) || !file.isFile) {
            result.error("invalidPath", "The shared file is outside prototype storage.", null)
            return
        }
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.prototype.files",
            file,
        )
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/json"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, null))
        result.success(null)
    }

    @Deprecated("Deprecated in Android API; FlutterActivity still forwards this callback.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickWavRequest) return
        val result = pendingPick ?: return
        pendingPick = null
        val selectedUri = data?.data
        if (resultCode != Activity.RESULT_OK || selectedUri == null) {
            result.success(null)
            return
        }
        try {
            val inputDirectory = File(cacheDir, "prototype-wav").apply { mkdirs() }
            inputDirectory.listFiles()?.forEach { it.delete() }
            val output = File(inputDirectory, "measurement-input.wav")
            contentResolver.openInputStream(selectedUri).use { input ->
                requireNotNull(input) { "The selected WAV cannot be opened." }
                output.outputStream().use { sink -> input.copyTo(sink) }
            }
            result.success(output.absolutePath)
        } catch (error: Exception) {
            result.error("wavCopyFailed", "The selected WAV cannot be read.", null)
        }
    }
}
