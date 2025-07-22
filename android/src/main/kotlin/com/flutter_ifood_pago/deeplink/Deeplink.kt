package com.flutter_ifood_pago.deeplink

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

abstract class Deeplink {
    open fun startDeeplink(binding: ActivityPluginBinding, bundle: Bundle) : Bundle {
        throw NotImplementedError()
    }

    open fun validateIntent(intent: Intent?): Map<String, Any?> {
        try {
            if (intent == null) {
                return mapOf(
                    "code" to "ERROR",
                    "message" to "no intent data"
                )
            }
            val extras: Bundle? = intent.extras
            val status: String? = extras?.getString("status")

            when (status) {
                "SUCCESS" -> {
                    val data: MutableMap<String, Any?> = mutableMapOf()

                    for (key: String in extras.keySet()) {
                        data[key] = extras.get(key)
                    }

                    return mapOf(
                        "code" to "SUCCESS",
                        "data" to data
                    )
                }
                else -> {
                    var message: String =  "Erro não identificado"
                    val resultDetail: String? = extras?.getString("errorReason")

                    if(resultDetail != null) {
                        message = "$resultDetail"
                    }

                    return mapOf(
                        "code" to "ERROR",
                        "message" to message
                    )
                }
            }
        } catch (e: Exception) {
            return mapOf(
                "code" to "ERROR",
                "message" to e.toString()
            )
        }
    }
}