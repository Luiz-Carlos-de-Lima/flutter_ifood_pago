package com.flutter_ifood_pago.deeplink

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Base64
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import org.json.JSONObject

class RefundDeeplink: Deeplink() {
    companion object {
        const val REQUEST_CODE = 10002
    }

    override fun startDeeplink(binding: ActivityPluginBinding ,bundle: Bundle) : Bundle {
        try {
            val transactionIdAdyen: String? = bundle.getString("transactionIdAdyen")
            val printReceipt: Boolean = bundle.getBoolean("printReceipt", true)

            if (transactionIdAdyen.isNullOrEmpty()) {
                throw IllegalArgumentException("Invalid refund details: transactionIdAdyen, transactionIdAdyen must be of type string and cannot be null or empty")
            }

            val contentJson = JSONObject().apply {
                put("transactionIdAdyen", transactionIdAdyen)
                put("printReceipt", printReceipt)
                put("urlToReturn", "refund_response")
                put("sendResultInSameIntent", true)
            }

            val contentBase64 = Base64.encodeToString(
                contentJson.toString().toByteArray(Charsets.UTF_8),
                Base64.NO_WRAP or Base64.URL_SAFE
            )

            val uriBuilder = Uri.Builder().apply {
                scheme("https")
                authority("portal.ifood.com.br")
                appendPath("make-refund")
                appendQueryParameter("content", contentBase64)
            }

            val refundIntent = Intent(Intent.ACTION_VIEW)
            refundIntent.data = uriBuilder.build()
            binding.activity.startActivityForResult(refundIntent, REQUEST_CODE)

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