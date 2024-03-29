enum PaymentMode { stripe, netsQR, enets }

class PaymentModeSetting {
  PaymentMode paymentMode;
  bool active;
  bool show;
  String? pubKey = '';
  String? merchantIdentifier = '';
  String? paySvcHostUrl = '';
  bool? allowSavePaymentMethod = false;

  PaymentModeSetting({
    required this.paymentMode,
    required this.active,
    required this.show,
    this.pubKey,
    this.merchantIdentifier,
    this.paySvcHostUrl,
    this.allowSavePaymentMethod,
  });

  factory PaymentModeSetting.fromJson(Map<String, dynamic> json) {
    return PaymentModeSetting(
      paymentMode: json['payment_mode'],
      active: json['active'],
      show: json['show'],
      pubKey: json['pub_key'],
      merchantIdentifier: json['merchant_identifier'],
      paySvcHostUrl: json['pay_svc_host_url'],
      allowSavePaymentMethod: json['allow_save_payment_method'],
    );
  }
}
