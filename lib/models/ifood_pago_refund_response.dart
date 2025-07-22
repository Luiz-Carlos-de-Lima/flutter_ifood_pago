import 'package:flutter_ifood_pago/constants/ifood_pago_status_deeplink.dart';

class IfoodPagoRefundResponse {
  final IfoodPagoStatusDeeplink status;
  final String deviceSerialNumber;

  IfoodPagoRefundResponse({required this.status, required this.deviceSerialNumber});

  factory IfoodPagoRefundResponse.fromJson(Map<String, dynamic> json) {
    return IfoodPagoRefundResponse(
      status: IfoodPagoStatusDeeplink.values.firstWhere((e) => e.name == json['status'], orElse: () => IfoodPagoStatusDeeplink.ERROR),
      deviceSerialNumber: json['deviceSerialNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status.name, 'deviceSerialNumber': deviceSerialNumber};
  }
}
