class IfoodPagoRefundPayload {
  final String transactionIdAdyen;
  final bool printReceipt;

  IfoodPagoRefundPayload({required this.transactionIdAdyen, this.printReceipt = true});

  factory IfoodPagoRefundPayload.fromJson(Map<String, dynamic> json) {
    return IfoodPagoRefundPayload(transactionIdAdyen: json['transactionIdAdyen'] ?? '', printReceipt: json['printReceipt'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {'transactionIdAdyen': transactionIdAdyen, 'printReceipt': printReceipt};
  }
}
