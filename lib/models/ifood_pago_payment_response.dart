class IfoodPagoPaymentResponse {
  final String transactionIdAnotaAi;
  final String tableIdAnotaAi;
  final String? transactionIdAdyen;
  final String status;
  final String deviceSerialNumber;
  final String cardBrand;
  final String errorReason;
  final String transactionDate;
  final String transactionTime;
  final String authCode;
  final List<Map<String, dynamic>> subsidyInformation;

  IfoodPagoPaymentResponse({
    required this.transactionIdAnotaAi,
    required this.tableIdAnotaAi,
    required this.transactionIdAdyen,
    required this.status,
    required this.deviceSerialNumber,
    required this.cardBrand,
    required this.errorReason,
    required this.transactionDate,
    required this.transactionTime,
    required this.authCode,
    required this.subsidyInformation,
  });

  factory IfoodPagoPaymentResponse.fromJson(Map<String, dynamic> json) {
    return IfoodPagoPaymentResponse(
      transactionIdAnotaAi: json['transactionIdAnotaAi'] ?? '',
      tableIdAnotaAi: json['tableIdAnotaAi'] ?? '',
      transactionIdAdyen: json['transactionIdAdyen'],
      status: json['status'] ?? '',
      deviceSerialNumber: json['deviceSerialNumber'] ?? '',
      cardBrand: json['cardBrand'] ?? '',
      errorReason: json['errorReason'] ?? '',
      transactionDate: json['transactionDate'] ?? '',
      transactionTime: json['transactionTime'] ?? '',
      authCode: json['authCode'] ?? '',
      subsidyInformation: (json['subsidyInformation'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionIdAnotaAi': transactionIdAnotaAi,
      'tableIdAnotaAi': tableIdAnotaAi,
      'transactionIdAdyen': transactionIdAdyen,
      'status': status,
      'deviceSerialNumber': deviceSerialNumber,
      'cardBrand': cardBrand,
      'errorReason': errorReason,
      'transactionDate': transactionDate,
      'transactionTime': transactionTime,
      'authCode': authCode,
      'subsidyInformation': subsidyInformation,
    };
  }
}
