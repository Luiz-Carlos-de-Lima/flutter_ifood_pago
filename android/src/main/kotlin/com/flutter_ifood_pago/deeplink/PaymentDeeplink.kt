package com.flutter_ifood_pago.deeplink

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Base64
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import org.json.JSONObject

class PaymentDeeplink: Deeplink() {
    companion object {
        const val REQUEST_CODE = 10001
    }

    override fun startDeeplink(binding: ActivityPluginBinding ,bundle: Bundle) : Bundle {
        try {
            val paymentMethod: String? = bundle.getString("paymentMethod")
            val value: Int = bundle.getInt("value", 0)
            val transactionId: String? = bundle.getString("transactionId")
            val tableId: String? = bundle.getString("tableId")
            val printReceipt: Boolean = bundle.getBoolean("printReceipt", true)

            if (!(paymentMethod == "DEBIT" || paymentMethod == "CREDIT" || paymentMethod == "PIX" || paymentMethod == "VOUCHER")) {
                throw IllegalArgumentException("Invalid payment details: paymentMethod, paymentMethod must be DEBIT, CREDIT, PIX, VOUCHER.")
            }

            if (value <= 0) {
                throw IllegalArgumentException("Invalid payment details: value, value must be greater than 0")
            }

            if (transactionId.isNullOrEmpty()) {
                throw IllegalArgumentException("Invalid payment details: transactionId, transactionId must be of type string and cannot be null or empty")
            }

            val contentJson = JSONObject().apply {
                put("paymentMethod", paymentMethod)
                put("value", value)
                put("transactionId", transactionId)
                put("tableId", tableId)
                put("printReceipt", printReceipt)
                put("urlToReturn", "payment_response")
                put("sendResultInSameIntent", true)
            }

            val contentBase64 = Base64.encodeToString(
                contentJson.toString().toByteArray(Charsets.UTF_8),
                Base64.NO_WRAP or Base64.URL_SAFE
            )

            val uriBuilder = Uri.Builder().apply {
                scheme("https")
                authority("portal.ifood.com.br")
                appendPath("make-payment")
                appendQueryParameter("content", contentBase64)
            }

            val paymentIntent = Intent(Intent.ACTION_VIEW)
            paymentIntent.data = uriBuilder.build()
            binding.activity.startActivityForResult(paymentIntent, REQUEST_CODE)

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