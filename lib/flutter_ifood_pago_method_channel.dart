import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ifood_pago/constants/ifood_pago_keys_storage.dart';
import 'package:flutter_ifood_pago/constants/ifood_pago_status_deeplink.dart';
import 'package:flutter_ifood_pago/exceptions/ifood_pago_payment_exception.dart';
import 'package:flutter_ifood_pago/exceptions/ifood_pago_print_exception.dart';
import 'package:flutter_ifood_pago/exceptions/ifood_pago_refund_exception.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_auth_response.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_payment_response.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_payment_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_print_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_refund_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_refund_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'flutter_ifood_pago_platform_interface.dart';

/// An implementation of [FlutterIfoodPagoPlatform] that uses method channels.
class MethodChannelFlutterIfoodPago extends FlutterIfoodPagoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_ifood_pago');

  @override
  Future<IfoodPagoPaymentResponse> pay({required IfoodPagoPaymentPayload payload}) async {
    try {
      final response = await methodChannel.invokeMethod<Map>('pay', payload.toJson());
      if (response is Map) {
        if (response['code'] == IfoodPagoStatusDeeplink.SUCCESS.name && response['data'] is Map) {
          return IfoodPagoPaymentResponse.fromJson(Map<String, dynamic>.from(response['data']));
        } else {
          throw IfoodPagoPaymentException(message: response['message']);
        }
      } else {
        throw IfoodPagoPaymentException(message: 'invalid response');
      }
    } on IfoodPagoPaymentException catch (e) {
      throw IfoodPagoPaymentException(message: e.message);
    } on PlatformException catch (e) {
      throw IfoodPagoPaymentException(message: e.message ?? 'PlatformException');
    } catch (e) {
      throw IfoodPagoPaymentException(message: "Pay Error: $e");
    }
  }

  @override
  Future<IfoodPagoRefundResponse> refund({required IfoodPagoRefundPayload payload}) async {
    try {
      final response = await methodChannel.invokeMethod<Map>('refund', payload.toJson());
      if (response is Map) {
        if (response['code'] == IfoodPagoStatusDeeplink.SUCCESS.name && response['data'] is Map) {
          return IfoodPagoRefundResponse.fromJson(Map<String, dynamic>.from(response['data']));
        } else {
          throw IfoodPagoRefundException(message: response['message']);
        }
      } else {
        throw IfoodPagoRefundException(message: 'invalid response');
      }
    } on IfoodPagoRefundException catch (e) {
      throw IfoodPagoRefundException(message: e.message);
    } on PlatformException catch (e) {
      throw IfoodPagoRefundException(message: e.message ?? 'PlatformException');
    } catch (e) {
      throw IfoodPagoRefundException(message: "Refund Error: $e");
    }
  }

  @override
  Future<List<Map>> printData({required IfoodPagoPrintPayload payload}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String accessToken = prefs.getString(IfoodPagoKeysStorage.TOKEN) ?? '';
      String createAt = prefs.getString(IfoodPagoKeysStorage.TOKEN_CREATED_AT) ?? '';

      DateTime? createAtDate = DateTime.tryParse(createAt);
      DateTime now = DateTime.now();
      Duration? difference;

      if (createAtDate != null) {
        difference = now.difference(createAtDate);
      }

      if (difference != null && difference.inHours > 23) {
        await prefs.remove(IfoodPagoKeysStorage.TOKEN);
        await prefs.remove(IfoodPagoKeysStorage.TOKEN_CREATED_AT);

        accessToken = '';
        createAt = '';
      }

      if (accessToken.isEmpty && createAt.isEmpty) {
        final response = await methodChannel.invokeMethod<Map>('requestPrintToken', {'integrationApp': payload.integrationApp});

        if (response is! Map) {
          throw IfoodPagoPrintException(message: 'invalid response');
        }

        if (response['code'] != IfoodPagoStatusDeeplink.SUCCESS.name) {
          throw IfoodPagoPrintException(message: response['message']);
        }

        if (response['data'] is! Map) {
          throw IfoodPagoPrintException(message: 'invalid response data');
        }

        final authResponse = IfoodPagoAuthResponse.fromJson(Map<String, dynamic>.from(response['data']));

        accessToken = authResponse.hash;
        createAt = authResponse.createAt;

        prefs.setString(IfoodPagoKeysStorage.TOKEN, accessToken);
        prefs.setString(IfoodPagoKeysStorage.TOKEN_CREATED_AT, createAt);
      }

      final listaImageBase64 = await methodChannel.invokeMethod<Map>('generateImageBase64', {
        'printable_content': payload.toJson()['printable_content'],
        'groupAll': payload.groupAll,
      });

      if (listaImageBase64 is! Map) {
        throw IfoodPagoPrintException(message: 'invalid listaImageBase64');
      }

      if (listaImageBase64['code'] != IfoodPagoStatusDeeplink.SUCCESS.name) {
        throw IfoodPagoPrintException(message: listaImageBase64['message']);
      }

      if (listaImageBase64['data'] is! List) {
        throw IfoodPagoPrintException(message: 'invalid response data');
      }

      List<Map> imageBase64List = [];

      for (var imageBase64 in listaImageBase64['data']) {
        log(imageBase64.toString());

        final response = await http.post(
          Uri.parse("https://movilepay-api.ifood.com.br/ifoodpay/mobile/api/v1/print/file"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"authorizationHash": accessToken, "contentBase64": imageBase64['imageBase64']}),
        );

        if (response.statusCode == 200) {
          imageBase64List.add({'imageBase64': imageBase64['imageBase64']});
        } else {
          imageBase64List.add({'messageError': 'Failed to print: ${response.reasonPhrase}', 'imageBase64': imageBase64['imageBase64']});
        }
      }

      return imageBase64List;
    } on IfoodPagoPrintException catch (e) {
      throw IfoodPagoPrintException(message: e.message);
    } on PlatformException catch (e) {
      throw IfoodPagoPrintException(message: e.message ?? 'PlatformException');
    } catch (e) {
      throw IfoodPagoPrintException(message: "Print Error: $e");
    }
  }
}
