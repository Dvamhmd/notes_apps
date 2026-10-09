package com.example.notes_app

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.text.Html
import android.text.Spanned
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CLIPBOARD_CHANNEL = "com.example.notes_app/clipboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL).setMethodCallHandler { call, result ->
            val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            if (clipboardManager == null) {
                result.error("UNAVAILABLE", "Clipboard manager unavailable", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "getClipboardData" -> {
                    try {
                        val primaryClip = clipboardManager.primaryClip
                        if (primaryClip != null && primaryClip.itemCount > 0) {
                            val item = primaryClip.getItemAt(0)
                            
                            var plainText: String? = item.text?.toString()
                            var htmlText: String? = item.htmlText

                            // If htmlText is null, check if item.text is a Spanned object with rich styles
                            if (htmlText.isNullOrBlank() && item.text is Spanned) {
                                val spanned = item.text as Spanned
                                htmlText = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                    Html.toHtml(spanned, Html.TO_HTML_PARAGRAPH_LINES_CONSECUTIVE)
                                } else {
                                    @Suppress("DEPRECATION")
                                    Html.toHtml(spanned)
                                }
                            }

                            // If plainText is null but html is present, coerce to plain text
                            if (plainText == null) {
                                plainText = item.coerceToText(this).toString()
                            }

                            val hasHtml = !htmlText.isNullOrBlank()
                            
                            val response = mapOf(
                                "plainText" to (plainText ?: ""),
                                "htmlText" to (htmlText ?: ""),
                                "hasHtml" to hasHtml
                            )
                            result.success(response)
                        } else {
                            result.success(mapOf(
                                "plainText" to "",
                                "htmlText" to "",
                                "hasHtml" to false
                            ))
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.localizedMessage, null)
                    }
                }
                "setClipboardData" -> {
                    try {
                        val plainText = call.argument<String>("plainText") ?: ""
                        val htmlText = call.argument<String>("htmlText")

                        val clipData: ClipData = if (!htmlText.isNullOrBlank()) {
                            ClipData.newHtmlText("Rich Text", plainText, htmlText)
                        } else {
                            ClipData.newPlainText("Plain Text", plainText)
                        }

                        clipboardManager.setPrimaryClip(clipData)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.localizedMessage, null)
                    }
                }
                "hasHtmlData" -> {
                    try {
                        val primaryClip = clipboardManager.primaryClip
                        val hasHtml = if (primaryClip != null && primaryClip.itemCount > 0) {
                            val description = primaryClip.description
                            description.hasMimeType(ClipDescription.MIMETYPE_TEXT_HTML) ||
                                !primaryClip.getItemAt(0).htmlText.isNullOrBlank() ||
                                primaryClip.getItemAt(0).text is Spanned
                        } else {
                            false
                        }
                        result.success(hasHtml)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
