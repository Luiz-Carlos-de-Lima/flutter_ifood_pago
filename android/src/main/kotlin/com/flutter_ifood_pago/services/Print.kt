package com.flutter_ifood_pago.services

import android.content.Context
import android.graphics.*
import android.os.Bundle
import android.util.Base64
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

class Print {
    suspend fun requestPrint(context: Context, token: String, bundles: List<Bundle>): String {
        val imagensBase64 = convertPrintableItemsToImageBase64(context, bundles)

        // Para simplificar, vou assumir que só tem uma imagem
        val base64 = imagensBase64.firstOrNull()?.get("imagePath") ?: throw Exception("Nenhuma imagem gerada")

        val body = JSONObject().apply {
            put("authorizationHash", token)
            put("contentBase64", base64)
        }

        return sendPostRequest(body.toString())
    }

    private suspend fun sendPostRequest(jsonBody: String): String = withContext(Dispatchers.IO) {
        val url = URL("https://movilepay-api.ifood.com.br/ifoodpay/mobile/api/v1/print/file")
        val connection = url.openConnection() as HttpURLConnection

        try {
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.doOutput = true

            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(jsonBody)
                writer.flush()
            }

            val responseCode = connection.responseCode
            val responseMessage = connection.inputStream.bufferedReader().use { it.readText() }

            if (responseCode == HttpURLConnection.HTTP_OK) {
                responseMessage
            } else {
                "Erro $responseCode: $responseMessage"
            }
        } catch (e: Exception) {
            "Exceção: ${e.message}"
        } finally {
            connection.disconnect()
        }
    }

    private fun convertPrintableItemsToImageBase64(context: Context, data: List<Bundle>): List<Map<String, String>> {
        val map = convertPrintableContentInMapAndReturn(data).map { item ->
            if (item["type"] == "image") {
                item
            } else {
                val content = item["content"] ?: ""
                val align = item["align"] ?: "left"
                val size = item["size"] ?: "small"

                val bitmap = createTextBitmap(context, content, align, size)
                val base64 = bitmapToBase64(bitmap)

                mapOf(
                    "type" to "image",
                    "imagePath" to base64
                )
            }
        }

        Log.d("Map convertido", map.toString())
        return map
    }

    private fun convertPrintableContentInMapAndReturn(printableContent: List<Bundle>): MutableList<Map<String, String>> {
        val newListPrintable: MutableList<Map<String, String>> = ArrayList()

        for (content: Bundle in printableContent) {
            val map: Map<String, String> = content.keySet().associateWith { key ->
                content.getString(key).toString()
            }
            newListPrintable.add(map)
        }

        Log.d("convertMap", newListPrintable.toString())
        return newListPrintable
    }

    private fun createTextBitmap(
        context: Context,
        content: String,
        align: String,
        size: String
    ): Bitmap {
        Log.d("SIZE", size.toString())

        val maxCharsPerLine = when (size) {
            "big", "medium" -> 32
            "small" -> 48
            else -> 48
        }

        val fontSize = when (size) {
            "big" -> 20f
            "medium" -> 18f
            "small" -> 14f
            else -> 14f
        }

        val paint = Paint().apply {
            color = Color.BLACK
            textSize = fontSize
            typeface = Typeface.createFromAsset(context.assets, "fonts/JetBrainsMono-Bold.ttf")
            isAntiAlias = true
        }

        val lines = content
            .split("\n")
            .flatMap { splitLine(it, maxCharsPerLine) }

        var lineHeigth = 1;

        if (lines.isNotEmpty()) {
            lineHeigth = lines.size
        }

        val metrics = paint.fontMetrics
        val lineHeight = (metrics.bottom - metrics.top).toInt()
        val width = 384
        val height = lineHeight * lineHeigth

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
//        paint.style = Paint.Style.FILL_AND_STROKE;
//        paint.strokeWidth = 1F;
        lines.forEachIndexed { index, line ->
            val x = when (align) {
                "center" -> (width - paint.measureText(line)) / 2
                "right" -> (width - paint.measureText(line))
                else -> 0f
            }
            val y = (index * lineHeight) - paint.fontMetrics.top
            canvas.drawText(line, x, y, paint)
        }
        Log.d("bitmap", bitmap.toString())
        return bitmap
    }

    private fun splitLine(text: String, maxChars: Int): List<String> {
        val result = mutableListOf<String>()
        var start = 0

        while (start < text.length) {
            val end = minOf(start + maxChars, text.length)
            result.add(text.substring(start, end))
            start = end
        }
        return result
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }
}
