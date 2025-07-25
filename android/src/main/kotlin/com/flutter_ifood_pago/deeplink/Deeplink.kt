package com.flutter_ifood_pago.deeplink

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlin.reflect.typeOf

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

            val extras: Bundle = intent.extras
                ?: return mapOf(
                    "code" to "ERROR",
                    "message" to "no extras in intent"
                )

            val resultString: String = extras.get("RESULT")?.toString() ?: return mapOf(
                "code" to "ERROR",
                "message" to "no result in intent"
            )

            val gson = Gson()
            val type = object : TypeToken<Map<String, Any>>() {}.type
            val resultMap: Map<String, Any> = gson.fromJson(resultString, type)

            if (resultMap["status"] == "SUCCESS") {
                return mapOf(
                    "code" to "SUCCESS",
                    "data" to resultMap
                )
            } else  {
               val message = resultMap["errorReason"]?.toString() ?: "Erro não identificado"

                return mapOf(
                    "code" to "ERROR",
                    "message" to message
                )
            }
        } catch (e: Exception) {
            return mapOf(
                "code" to "ERROR",
                "message" to e.toString()
            )
        }
    }
}