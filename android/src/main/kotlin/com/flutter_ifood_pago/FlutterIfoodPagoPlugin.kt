package com.flutter_ifood_pago

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.flutter_ifood_pago.deeplink.Deeplink
import com.flutter_ifood_pago.deeplink.PaymentDeeplink
import com.flutter_ifood_pago.deeplink.RequestPrintTokenDeeplink
import com.flutter_ifood_pago.deeplink.RefundDeeplink
import com.flutter_ifood_pago.services.DeviceInfo
import com.flutter_ifood_pago.services.Print
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class FlutterIfoodPagoPlugin: FlutterPlugin, MethodCallHandler , ActivityAware {
  private lateinit var channel: MethodChannel

  private val paymentDeeplink = PaymentDeeplink()
  private val refundDeeplink = RefundDeeplink()
  private val requestPrintToken = RequestPrintTokenDeeplink()
  private val print = Print()

  private var binding: ActivityPluginBinding? = null
  private var resultScope: Result? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ifood_pago")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(newBinding: ActivityPluginBinding) {
    binding = newBinding
    binding?.addActivityResultListener { requestCode: Int, resultCode: Int, intent: Intent? ->
      if(Activity.RESULT_OK == resultCode) {
        var responseMap: Map<String, Any?> = mapOf()
        when (requestCode) {
          PaymentDeeplink.REQUEST_CODE -> {
            responseMap = paymentDeeplink.validateIntent(intent)
          }
          RefundDeeplink.REQUEST_CODE -> {
            responseMap = refundDeeplink.validateIntent(intent)
          }
          RequestPrintTokenDeeplink.REQUEST_CODE -> {
            responseMap = requestPrintToken.validateIntent(intent)
          }
        }

        sendResultData(responseMap)
      }
      true
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    binding = null
  }

  override fun onReattachedToActivityForConfigChanges(newBinding: ActivityPluginBinding) {
    onAttachedToActivity(newBinding)
  }

  override fun onDetachedFromActivity() {
    binding = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    resultScope = result

    if ((binding?.activity is Activity).not()) {
      resultScope!!.error("UNAVAILABLE", "Activity is not available", null)
      return
    }

    when (call.method) {
      "pay" -> {
        val bundle = Bundle().apply {
          putString("paymentMethod", call.argument<String>("paymentMethod"))
          putInt("value", call.argument<Int?>("value") ?: 0)
          putString("transactionId", call.argument<String>("transactionId"))
          putString("tableId", call.argument<String>("tableId"))
          putBoolean("printReceipt", call.argument<Boolean?>("printReceipt") ?: false)
        }
        starDeeplink(paymentDeeplink, bundle)
      }
      "refund" -> {
        val bundle = Bundle().apply {
          putString("transactionIdAdyen", call.argument<String>("transactionIdAdyen"))
          putBoolean("printReceipt", call.argument<Boolean?>("printReceipt") ?: false)
        }
        starDeeplink(refundDeeplink, bundle)
      }
      "requestPrintToken" -> {
        val bundle = Bundle().apply {
          putString("integrationApp", call.argument<String>("integrationApp"))
        }
        starDeeplink(requestPrintToken, bundle)
      }
      "print" -> {
        val token: String = call.argument<String>("token") ?: ""
        val listPrintContent: List<HashMap<String, Any?>>? = call.argument<List<HashMap<String, Any?>>>("printable_content")
        if (listPrintContent.isNullOrEmpty() ) {
          result.error("PRINT_ERROR", "print error, printable_content is null", null)
        }
        CoroutineScope(Dispatchers.Main).launch {
          try {
            val resultPrint = print.requestPrint(binding!!.activity, token, listPrintContent!!.toBundleList())
            result.success(resultPrint)
          } catch (e: Exception) {
            result.error("PRINT_ERROR", e.message, null)
          }
        }
      }
      "getSerialNumberAndDeviceModel" -> {
        val deviceInfo = DeviceInfo().getSerialNumberAndDeviceModel()
        resultScope?.success(mapOf(
          "code" to "SUCCESS",
          "data" to deviceInfo
        ))
      }
      else ->  {
        resultScope?.error("ERROR", "Value of ", null)
      }
    }
    return
  }

  private fun starDeeplink(deeplink: Deeplink, bundle: Bundle) {
    val bundleStartDeeplink: Bundle = deeplink.startDeeplink(binding!!, bundle)
    val code: String = bundleStartDeeplink.getString("code") ?: "ERROR"

    if (code == "ERROR") {
      val message: String = (bundleStartDeeplink.getString("message") ?: "start deeplink error").toString()
      resultScope?.error(code, message, null)
      resultScope = null
    }
  }

  private fun sendResultData(paymentData: Map<String, Any?>) {
    if (paymentData["code"] == "SUCCESS" && paymentData["data"] != null) {
      resultScope?.success(paymentData)
      resultScope = null
    } else {
      val message: String = (paymentData["message"] ?: "result error").toString()
      resultScope?.error((paymentData["code"] ?: "ERROR").toString(), message, null)
      resultScope = null
    }
  }

  private fun List<Map<String, Any?>>.toBundleList(): ArrayList<Bundle> {
    val bundleList = ArrayList<Bundle>()
    for (map in this) {
      bundleList.add(map.toBundle())
    }
    return bundleList
  }

  private fun Map<String, Any?>.toBundle(): Bundle {
    val bundle = Bundle()
    for ((key, value) in this) {
      when (value) {
        is String -> bundle.putString(key, value)
        is Int -> bundle.putInt(key, value)
        is Boolean -> bundle.putBoolean(key, value)
        is Double -> bundle.putDouble(key, value)
        is Float -> bundle.putFloat(key, value)
        is Long -> bundle.putLong(key, value)
        is Map<*, *> -> {
          @Suppress("UNCHECKED_CAST")
          bundle.putBundle(key, (value as? Map<String, Any?>)?.toBundle())
        }
      }
    }
    return bundle
  }
}
