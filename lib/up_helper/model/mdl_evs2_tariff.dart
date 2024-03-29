import 'package:intl/intl.dart';

class Evs2Tariff {
  int id;
  DateTime tariffTimestamp;
  String meterDisplayname;
  double? kwhDiff;
  double? tariffPrice;
  double? debitAmt;
  String? debitRef;
  double? creditAmt;
  String? creditRef;
  double? refBal;
  String? refBalTag;
  double? refKwhTotal;
  // int? offerId;
  // double? overUsedKwh;

  Evs2Tariff({
    required this.id,
    required this.tariffTimestamp,
    required this.meterDisplayname,
    this.kwhDiff,
    this.tariffPrice,
    this.debitAmt,
    this.debitRef,
    this.creditAmt,
    this.creditRef,
    this.refBal,
    this.refBalTag,
    this.refKwhTotal,
    // this.offerId,
    // this.overUsedKwh,
  });

  factory Evs2Tariff.fromJson(Map<String, dynamic> json) {
    return Evs2Tariff(
      id: int.parse(json['id']),
      tariffTimestamp: DateTime.parse(json['tariff_timestamp']),
      meterDisplayname: json['meter_displayname'],
      kwhDiff: json['kwh_diff'] == null ? null : double.parse(json['kwh_diff']),
      tariffPrice: json['tariff_price'] == null
          ? null
          : double.parse(json['tariff_price']),
      debitAmt:
          json['debit_amt'] == null ? null : double.parse(json['debit_amt']),
      debitRef: json['debit_ref'] ?? '',
      creditAmt:
          json['credit_amt'] == null ? null : double.parse(json['credit_amt']),
      creditRef: json['credit_ref'] ?? '',
      refBal: json['ref_bal'] == null ? null : double.parse(json['ref_bal']),
      refBalTag: json['ref_bal_tag'] ?? '',
      refKwhTotal: json['ref_kwh_total'] == null
          ? null
          : double.parse(json['ref_kwh_total']),
      // offerId: json['offerId'],
      // overUsedKwh: json['overUsedKwh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tariff_timestamp': tariffTimestamp.toIso8601String(),
      'meter_displayname': meterDisplayname,
      'kwh_diff': kwhDiff,
      'tariff_price': tariffPrice,
      'debit_amt': debitAmt,
      'debit_ref': debitRef,
      'credit_amt': creditAmt,
      'credit_ref': creditRef,
      'ref_bal': refBal,
      'ref_bal_tag': refBalTag,
      'ref_kwh_total': refKwhTotal,
      // 'offerId': offerId,
      // 'overUsedKwh': overUsedKwh,
    };
  }

  static List<dynamic> getKeyList() {
    return [
      'id',
      'tariff_timestamp',
      'meter_displayname',
      'kwh_diff',
      'tariff_price',
      'debit_amt',
      'debit_ref',
      'credit_amt',
      'credit_ref',
      'ref_bal',
      'ref_bal_tag',
      'ref_kwh_total',
    ];
  }

  List<dynamic> getValueStringList() {
    return [
      id,
      DateFormat('yyyy-MM-dd HH:mm:ss').format(tariffTimestamp),
      meterDisplayname,
      kwhDiff ?? '',
      tariffPrice ?? '',
      debitAmt ?? '',
      debitRef ?? '',
      creditAmt ?? '',
      creditRef ?? '',
      refBal ?? '',
      refBalTag ?? '',
      refKwhTotal ?? '',
    ];
  }

  bool isEmpty() {
    return id == 0;
  }
}
