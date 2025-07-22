package com.flutter_ifood_pago.deeplink

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Base64

import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import org.json.JSONObject

class RequestPrintTokenDeeplink: Deeplink() {
    companion object {
        const val REQUEST_CODE = 10003
    }

    override fun startDeeplink(binding: ActivityPluginBinding, bundle: Bundle): Bundle {
        try {
            val integrationApp: String? = bundle.getString("integrationApp")

            if (integrationApp.isNullOrEmpty()) {
                throw IllegalArgumentException("Invalid print details: integrationApp, integrationApp must be of type string and cannot be null or empty")
            }

            val contentJson = JSONObject().apply {
                put("integrationApp", integrationApp)
            }

            val contentBase64 = Base64.encodeToString(
                contentJson.toString().toByteArray(Charsets.UTF_8),
                Base64.NO_WRAP or Base64.URL_SAFE
            )

            val uriBuilder = Uri.Builder().apply {
                scheme("https")
                authority("portal.ifood.com.br")
                appendPath("print-file")
                appendQueryParameter("content", contentBase64)
            }

            val printIntent = Intent(Intent.ACTION_VIEW)
            printIntent.data = uriBuilder.build()
            binding.activity.startActivityForResult(printIntent, REQUEST_CODE)

            return Bundle().apply {
                putString("code", "SUCCESS")
            }
        } catch (e: IllegalArgumentException) {
            return Bundle().apply {
                putString("code", "ERROR")
                putString("message", e.message)
            }
        } catch (e: Exception) {
            return Bundle().apply {
                putString("code", "ERROR")
                putString("message", e.message ?: "An unexpected error occurred")
            }
        }
    }
}