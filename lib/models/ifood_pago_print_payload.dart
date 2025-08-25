import 'package:flutter_ifood_pago/models/ifood_pago_content_print.dart';

class IfoodPagoPrintPayload {
  final String integrationApp;
  final List<IfoodPagoContentprint> printableContent;
  final bool groupAll;

  IfoodPagoPrintPayload({required this.integrationApp, required this.printableContent, required this.groupAll});

  Map<String, dynamic> toJson() {
    return {'integrationApp': integrationApp, 'printable_content': printableContent.map((e) => e.toJson()).toList(), 'ignoreAll': groupAll};
  }

  static IfoodPagoPrintPayload fromJson(Map json) {
    return IfoodPagoPrintPayload(
      integrationApp: json['integrationApp'],
      printableContent: json['printable_content'].map<IfoodPagoContentprint>((e) => IfoodPagoContentprint.fromJson(e)).toList(),
      groupAll: json['groupAll'],
    );
  }
}
