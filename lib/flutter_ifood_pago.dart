import 'package:flutter_ifood_pago/models/ifood_pago_payment_response.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_payment_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_print_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_refund_payload.dart';
import 'package:flutter_ifood_pago/models/ifood_pago_refund_response.dart';

import 'flutter_ifood_pago_platform_interface.dart';

class FlutterIfoodPago {
  Future<IfoodPagoPaymentResponse> pay({required IfoodPagoPaymentPayload payload}) {
    return FlutterIfoodPagoPlatform.instance.pay(payload: payload);
  }

  Future<IfoodPagoRefundResponse> refund({required IfoodPagoRefundPayload payload}) {
    return FlutterIfoodPagoPlatform.instance.refund(payload: payload);
  }

  Future<List<Map>> printData({required IfoodPagoPrintPayload payload}) {
    return FlutterIfoodPagoPlatform.instance.printData(payload: payload);
  }
}
