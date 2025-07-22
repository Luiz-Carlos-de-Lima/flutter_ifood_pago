import 'package:flutter_ifood_pago/models/ifood_pago_content_print.dart';

class IfoodPagoPrintPayload {
  final String integrationApp;
  final List<IfoodPagoContentprint> printableContent;

  IfoodPagoPrintPayload({required this.integrationApp, required this.printableContent});

  Map<String, dynamic> toJson() {
    return {'integrationApp': integrationApp, 'printable_content': printableContent.map((e) => e.toJson()).toList()};
  }

  static IfoodPagoPrintPayload fromJson(Map json) {
    return IfoodPagoPrintPayload(
      integrationApp: json['integrationApp'],
      printableContent: json['printable_content'].map<IfoodPagoContentprint>((e) => IfoodPagoContentprint.fromJson(e)).toList(),
    );
  }
}
