package com.mediscanai.app

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mediscanai.app/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val fileName = call.argument<String>("fileName") ?: "MediScan_Report"
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("INVALID_ARGS", "PDF bytes cannot be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val sanitizedName = fileName.replace(Regex("[^a-zA-Z0-9_-]"), "_")
                        val fullFileName = if (sanitizedName.endsWith(".pdf", ignoreCase = true)) {
                            sanitizedName
                        } else {
                            "$sanitizedName.pdf"
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val contentValues = ContentValues().apply {
                                put(MediaStore.MediaColumns.DISPLAY_NAME, fullFileName)
                                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                            }

                            val resolver = applicationContext.contentResolver
                            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                                ?: throw Exception("Failed to create MediaStore entry in Downloads")

                            resolver.openOutputStream(uri)?.use { stream ->
                                stream.write(bytes)
                                stream.flush()
                            } ?: throw Exception("Failed to open MediaStore output stream")

                            result.success(mapOf(
                                "uri" to uri.toString(),
                                "fileName" to fullFileName,
                                "path" to "Downloads/$fullFileName"
                            ))
                        } else {
                            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            if (!downloadsDir.exists()) {
                                downloadsDir.mkdirs()
                            }
                            val targetFile = File(downloadsDir, fullFileName)
                            FileOutputStream(targetFile).use { stream ->
                                stream.write(bytes)
                                stream.flush()
                            }

                            MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(targetFile.absolutePath),
                                arrayOf("application/pdf"),
                                null
                            )

                            result.success(mapOf(
                                "uri" to Uri.fromFile(targetFile).toString(),
                                "fileName" to fullFileName,
                                "path" to targetFile.absolutePath
                            ))
                        }
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage, null)
                    }
                }
                "openPdf" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("INVALID_ARGS", "URI cannot be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val uri = if (uriString.startsWith("content://") || uriString.startsWith("file://")) {
                            Uri.parse(uriString)
                        } else {
                            val file = File(uriString)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                FileProvider.getUriForFile(
                                    applicationContext,
                                    "${applicationContext.packageName}.fileprovider",
                                    file
                                )
                            } else {
                                Uri.fromFile(file)
                            }
                        }

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/pdf")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        val chooser = Intent.createChooser(intent, "Open PDF").apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
