package com.example.carenest_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent

class MainActivity : FlutterActivity() {
    private var pendingBytes: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carenest/files").setMethodCallHandler { call, result ->
            if (call.method != "save") { result.notImplemented(); return@setMethodCallHandler }
            if (pendingResult != null) { result.error("BUSY", "Đang lưu một tệp khác", null); return@setMethodCallHandler }
            val bytes = call.argument<ByteArray>("bytes")
            val name = call.argument<String>("name")
            if (bytes == null || name == null) { result.error("INVALID", "Thiếu dữ liệu tệp", null); return@setMethodCallHandler }
            pendingBytes = bytes
            pendingResult = result
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = call.argument<String>("type") ?: "application/octet-stream"
                putExtra(Intent.EXTRA_TITLE, name)
            }
            try { startActivityForResult(intent, 903) } catch (e: Exception) {
                pendingBytes = null; pendingResult = null; result.error("SAVE_FAILED", "Không mở được nơi lưu tệp", null)
            }
        }
    }

    @Deprecated("FlutterActivity still dispatches activity results through this callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 903) return
        val result = pendingResult
        val bytes = pendingBytes
        pendingResult = null; pendingBytes = null
        if (resultCode != Activity.RESULT_OK || data?.data == null || bytes == null) { result?.success(null); return }
        try {
            val stream = contentResolver.openOutputStream(data.data!!) ?: throw IllegalStateException()
            stream.use { it.write(bytes) }
            result?.success(null)
        } catch (e: Exception) { result?.error("SAVE_FAILED", "Không thể lưu tệp", null) }
    }
}
