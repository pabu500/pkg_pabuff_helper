import 'package:intl/intl.dart';

class Evs2ConsumerTransaction {
  String? transactionId;
  DateTime transactionLogTimestamp;
  double topupAmt;
  double gst;
  double netAmt;
  int? paymentMode;
  String? paymentModeStr;
  int? transactionStatus;
  String? transactionStatusStr;
  String? currency;
  String? meterDisplayname;
  int offerId;
  DateTime? responseTimstamp;
  bool completeSendToBackend;
  String? transactionCode;
  int? paymentChannel;
  String? paymentChannelStr;
  int? transactionStatusRcved;
  double? conversionRatio;
  String? auditNumber;
  bool? isDedicated;

  Evs2ConsumerTransaction({
    required this.transactionId,
    required this.transactionLogTimestamp,
    required this.topupAmt,
    required this.gst,
    required this.netAmt,
    required this.paymentModeStr,
    required this.transactionStatusStr,
    required this.currency,
    required this.meterDisplayname,
    required this.offerId,
    required this.responseTimstamp,
    required this.completeSendToBackend,
    required this.transactionCode,
    required this.paymentChannelStr,
    required this.transactionStatusRcved,
    // required this.conversionRatio,
    // required this.auditNumber,
    // required this.isDedicated,
  });

  factory Evs2ConsumerTransaction.fromJson(Map<String, dynamic> json) {
    return Evs2ConsumerTransaction(
      transactionId: json['transaction_id'],
      transactionLogTimestamp:
          DateTime.parse(json['transaction_log_timestamp']),
      topupAmt: double.parse(json['topup_amt']),
      gst: double.parse(json['gst']),
      netAmt: double.parse(json['net_amt']),
      paymentModeStr: json['payment_mode'],
      transactionStatusStr: json['transaction_status'],
      currency: json['currency'] ?? '',
      meterDisplayname: json['meter_displayname'],
      offerId: int.parse(json['offer_id']),
      responseTimstamp: json['response_timestamp'] == null
          ? null
          : DateTime.parse(json['response_timestamp']),
      completeSendToBackend:
          json['complete_send_to_backend'] == 'true' ? true : false,
      transactionCode: json['transaction_code'],
      paymentChannelStr: json['payment_channel'],
      transactionStatusRcved: json['transaction_status_rcved'] == null
          ? null
          : int.parse(json['transaction_status_rcved']),
      // conversionRatio: json['conversion_ratio'],
      // auditNumber: json['audit_number'],
      // isDedicated: json['is_dedicated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'transaction_timestamp': transactionLogTimestamp.toIso8601String(),
      'topup_amt': topupAmt,
      'gst': gst,
      'net_amt': netAmt,
      'payment_mode': paymentModeStr,
      'transaction_status': transactionStatusStr,
      'currency': currency,
      'meter_displayname': meterDisplayname,
      'offer_id': offerId,
      'response_timstamp':
          responseTimstamp == null ? '' : responseTimstamp!.toIso8601String(),
      'complete_send_to_backend': completeSendToBackend,
      'transaction_code': transactionCode,
      'payment_channel': paymentChannelStr,
      'transaction_status_rcved': transactionStatusRcved,
      'conversion_ratio': conversionRatio,
      'audit_number': auditNumber,
      'is_dedicated': isDedicated,
    };
  }

  static List<dynamic> getKeyList() {
    return [
      'transaction_id',
      'transaction_timestamp',
      'topup_amt',
      'gst',
      'net_amt',
      'payment_mode',
      'transaction_status',
      'currency',
      'meter_displayname',
      'offer_id',
      'response_timstamp',
      'complete_send_to_backend',
      'transaction_code',
      'payment_channel',
      'transaction_status_rcved',
      'conversion_ratio',
      'audit_number',
      'is_dedicated',
    ];
  }

  List<dynamic> getValueStringList() {
    return [
      transactionId,
      DateFormat('yyyy-MM-dd HH:mm:ss').format(transactionLogTimestamp),
      topupAmt,
      gst,
      netAmt,
      paymentModeStr ?? '',
      transactionStatusStr ?? '',
      currency,
      meterDisplayname,
      offerId,
      responseTimstamp == null
          ? ''
          : DateFormat('yyyy-MM-dd HH:mm:ss').format(responseTimstamp!),
      completeSendToBackend,
      transactionCode ?? '',
      paymentChannelStr ?? '',
      transactionStatusRcved ?? '',
      conversionRatio ?? '',
      auditNumber ?? '',
      isDedicated ?? '',
    ];
  }
}
