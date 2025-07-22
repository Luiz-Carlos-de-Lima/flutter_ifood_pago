import 'package:flutter_ifood_pago/constants/ifood_pago_status_deeplink.dart';

class IfoodPagoAuthResponse {
  final IfoodPagoStatusDeeplink status;
  final String hash;
  final String createAt;
  final String deviceSerialNumber;

  IfoodPagoAuthResponse({required this.status, required this.hash, required this.createAt, required this.deviceSerialNumber});

  factory IfoodPagoAuthResponse.fromJson(Map<String, dynamic> json) {
    return IfoodPagoAuthResponse(
      status: IfoodPagoStatusDeeplink.values.firstWhere((e) => e.name == json['status'], orElse: () => IfoodPagoStatusDeeplink.ERROR),
      hash: json['hash'] ?? '',
      createAt: json['createAt'] ?? '',
      deviceSerialNumber: json['deviceSerialNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status.name, 'hash': hash, 'createAt': createAt, 'deviceSerialNumber': deviceSerialNumber};
  }
}
