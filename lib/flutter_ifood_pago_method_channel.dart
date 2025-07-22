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

import 'dart:convert';
import 'dart:io';

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
          final jsonData = response['data'];
          return IfoodPagoPaymentResponse.fromJson(jsonData);
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
          final jsonData = response['data'];
          return IfoodPagoRefundResponse.fromJson(jsonData);
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
  Future<void> print({required IfoodPagoPrintPayload payload}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String accessToken = prefs.getString(IfoodPagoKeysStorage.TOKEN) ?? '';
      String createAt = prefs.getString(IfoodPagoKeysStorage.TOKEN_CREATED_AT) ?? '';

      DateTime createAtDate = DateTime.parse(createAt);
      DateTime now = DateTime.now();
      Duration difference = now.difference(createAtDate);

      if (difference.inHours > 24) {
        await prefs.remove(IfoodPagoKeysStorage.TOKEN);
        await prefs.remove(IfoodPagoKeysStorage.TOKEN_CREATED_AT);

        accessToken = '';
        createAt = '';
      }

      if (accessToken.isEmpty && createAt.isEmpty) {
        final response = await methodChannel.invokeMethod<Map>('print', {'integrationApp': payload.integrationApp});

        if (response is! Map) {
          throw IfoodPagoPrintException(message: 'invalid response');
        }

        if (response['code'] != IfoodPagoStatusDeeplink.SUCCESS.name) {
          throw IfoodPagoPrintException(message: response['message']);
        }

        if (response['data'] is! Map) {
          throw IfoodPagoPrintException(message: 'invalid response data');
        }

        final jsonData = response['data'];
        final authResponse = IfoodPagoAuthResponse.fromJson(jsonData);

        accessToken = authResponse.hash;
        createAt = authResponse.createAt;

        prefs.setString(IfoodPagoKeysStorage.TOKEN, accessToken);
        prefs.setString(IfoodPagoKeysStorage.TOKEN_CREATED_AT, createAt);
      }

      final url = Uri.parse('https://movilepay-api.ifood.com.br/ifoodpay/mobile/api/v1/print/file');
      final httpClient = HttpClient();
      final request = await httpClient.postUrl(url);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      final body = jsonEncode({"authorizationHash": accessToken, "contentBase64": ''});

      request.add(utf8.encode(body));

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final responseJson = jsonDecode(responseBody);
        if (responseJson is! Map) {
          throw IfoodPagoPrintException(message: 'invalid response format');
        }

        if (responseJson['code'] != IfoodPagoStatusDeeplink.SUCCESS.name) {
          throw IfoodPagoPrintException(message: responseJson['message']);
        }

        if (responseJson['data'] is! Map) {
          throw IfoodPagoPrintException(message: 'invalid response data');
        }

        final data = responseJson['data'];
      } else {
        throw IfoodPagoPrintException(message: 'invalid response');
      }
    } on IfoodPagoPrintException catch (e) {
      throw IfoodPagoPrintException(message: e.message);
    } on PlatformException catch (e) {
      throw IfoodPagoPrintException(message: e.message ?? 'PlatformException');
    } catch (e) {
      throw IfoodPagoPrintException(message: "Print Error: $e");
    }
  }
}
