package com.example.stallseeker

import android.app.Activity
import android.content.Intent
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val saveReceiptRequest = 4501
    private var pendingReceipt: Pair<ByteArray, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "stallseeker/receipt_download")
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val filename = call.argument<String>("filename")
                if (bytes == null || filename == null || pendingReceipt != null) {
                    result.error("save_failed", "Receipt data is missing or a save is already open.", null)
                    return@setMethodCallHandler
                }

                pendingReceipt = bytes to result
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/pdf"
                    putExtra(Intent.EXTRA_TITLE, filename)
                }
                try {
                    startActivityForResult(intent, saveReceiptRequest)
                } catch (error: Exception) {
                    pendingReceipt = null
                    result.error("save_failed", error.message, null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveReceiptRequest) return
        val (bytes, result) = pendingReceipt ?: return
        if (resultCode != Activity.RESULT_OK) {
            pendingReceipt = null
            result.success(false)
            return
        }

        val uri = data?.data
        if (uri == null) {
            pendingReceipt = null
            result.error("save_failed", "No file location returned.", null)
            return
        }

        Thread {
            val failure = runCatching {
                checkNotNull(contentResolver.openOutputStream(uri, "w")).use { it.write(bytes) }
            }.exceptionOrNull()
            if (failure != null) {
                runCatching { DocumentsContract.deleteDocument(contentResolver, uri) }
            }
            runOnUiThread {
                pendingReceipt = null
                if (failure == null) {
                    result.success(true)
                } else {
                    result.error("save_failed", failure.message, null)
                }
            }
        }.start()
    }
}
