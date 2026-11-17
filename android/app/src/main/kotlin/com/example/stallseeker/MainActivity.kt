package com.example.stallseeker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.ActivityResultLauncher
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "stallseeker/receipt_download"
    private val methodSavePdf = "savePdf"
    // ActivityResultLauncher for creating a document (PDF)
    private lateinit var createDocumentLauncher: ActivityResultLauncher<String>
    private var pendingBytes: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Register the ActivityResultLauncher using the CreateDocument contract
        createDocumentLauncher = registerForActivityResult(
            ActivityResultContracts.CreateDocument("application/pdf")
        ) { uri: Uri? ->
            handleDocumentResult(uri)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != methodSavePdf) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val filename = call.argument<String>("filename")
                if (bytes == null || filename == null) {
                    result.error("invalid_args", "Missing bytes or filename", null)
                    return@setMethodCallHandler
                }
                // Store pending data and launch the system save dialog
                pendingBytes = bytes
                pendingResult = result
                createDocumentLauncher.launch(filename)
            }
    }

    private fun handleDocumentResult(uri: Uri?) {
        val result = pendingResult ?: return
        val bytes = pendingBytes ?: run { result.error("state_error", "No pending receipt data", null); return }
        if (uri == null) {
            // User cancelled the save operation
            result.success(false)
            clearPending()
            return
        }
        // Write the PDF bytes to the selected URI on a background thread
        Thread {
            var error: Exception? = null
            try {
                contentResolver.openOutputStream(uri)?.use { it.write(bytes) } ?: throw IllegalStateException("Unable to open output stream")
            } catch (e: Exception) {
                error = e
            }
            runOnUiThread {
                if (error == null) {
                    result.success(true)
                } else {
                    result.error("save_failed", error?.message, null)
                }
                clearPending()
            }
        }.start()
    }

    private fun clearPending() {
        pendingBytes = null
        pendingResult = null
    }
}
