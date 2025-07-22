import 'package:flutter_ifood_pago/constants/ifood_pago_transaction_type.dart';

class IfoodPagoPaymentPayload {
  final IfoodPagoTransactionType paymentMethod;
  final int value;
  final String transactionId;
  final String tableId;
  final bool printReceipt;

  IfoodPagoPaymentPayload({required this.paymentMethod, required this.value, required this.transactionId, required this.tableId, this.printReceipt = true});

  factory IfoodPagoPaymentPayload.fromJson(Map<String, dynamic> json) {
    return IfoodPagoPaymentPayload(
      paymentMethod: IfoodPagoTransactionType.values.firstWhere((e) => e.name.toString() == json['paymentMethod']),
      value: json['value'],
      transactionId: json['transactionId'],
      tableId: json['tableId'],
      printReceipt: json['printReceipt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'paymentMethod': paymentMethod.name.toString(), 'value': value, 'transactionId': transactionId, 'tableId': tableId, 'printReceipt': printReceipt};
  }
}
