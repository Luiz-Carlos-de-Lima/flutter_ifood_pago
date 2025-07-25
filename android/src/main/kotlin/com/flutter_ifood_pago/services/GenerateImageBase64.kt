package com.flutter_ifood_pago.services

import android.content.Context
import android.graphics.*
import android.os.Bundle
import android.util.Base64
import java.io.ByteArrayOutputStream

class GenerateImageBase64 {
    fun convertPrintableItemsToImageBase64(context: Context, data: List<Bundle>): Map<String, Any?> {
        return try {
            val listMap = convertPrintableContentInMapAndReturn(data).map { item ->
                if (item["type"] == "image") {
                    val originalBase64 = item["imagePath"] ?: ""
                    val decodedBytes = Base64.decode(originalBase64, Base64.DEFAULT)
                    val originalBitmap = BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)

                    if (originalBitmap != null){
                        val bwBitmap = convertTo1BitBitmap(originalBitmap)
                        val base64 = bitmapToBase64(bwBitmap)

                        mapOf(
                            "type" to "image",
                            "imageBase64" to base64
                        )
                    } else {
                        mapOf(
                            "type" to "image",
                            "imageBase64" to ""
                        )
                    }
                } else {
                    val content = item["content"] ?: ""
                    val align = item["align"] ?: "left"
                    val size = item["size"] ?: "small"

                    val bitmap = createTextBitmap(context, content, align, size)
                    val bwBitmap = convertTo1BitBitmap(bitmap)
                    val base64 = bitmapToBase64(bwBitmap)

                    mapOf(
                        "type" to "image",
                        "imageBase64" to base64
                    )
                }
            }

             mapOf(
                "code" to "SUCCESS",
                "data" to listMap
            )
        } catch (e: Exception) {
             mapOf(
                "code" to "ERROR",
                "message" to e.toString()
            )
        }
    }

    private fun convertTo1BitBitmap(source: Bitmap): Bitmap {
        val width = source.width
        val height = source.height
        val bwBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

        val canvas = Canvas(bwBitmap)
        val paint = Paint()
        canvas.drawColor(Color.WHITE)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixel = source.getPixel(x, y)
                val r = Color.red(pixel)
                val g = Color.green(pixel)
                val b = Color.blue(pixel)
                val gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt()

                val color = if (gray < 128) Color.BLACK else Color.WHITE
                paint.color = color
                canvas.drawPoint(x.toFloat(), y.toFloat(), paint)
            }
        }

        return bwBitmap
    }

    private fun convertPrintableContentInMapAndReturn(printableContent: List<Bundle>): MutableList<Map<String, String>> {
        val newListPrintable: MutableList<Map<String, String>> = ArrayList()

        for (content: Bundle in printableContent) {
            val map: Map<String, String> = content.keySet().associateWith { key ->
                content.getString(key).toString()
            }
            newListPrintable.add(map)
        }

        return newListPrintable
    }

    private fun createTextBitmap(
        context: Context,
        content: String,
        align: String,
        size: String
    ): Bitmap {
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

        val metrics = paint.fontMetrics
        val lineHeight = (metrics.bottom - metrics.top).toInt()
        val width = 384
        val height = lineHeight * lines.size

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)

        lines.forEachIndexed { index, line ->
            val x = when (align) {
                "center" -> (width - paint.measureText(line)) / 2
                "right" -> (width - paint.measureText(line))
                else -> 0f
            }
            val y = (index * lineHeight) - paint.fontMetrics.top
            canvas.drawText(line, x, y, paint)
        }

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
