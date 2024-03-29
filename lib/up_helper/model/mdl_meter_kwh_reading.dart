class MeterKwhReading {
  // int? id;
  DateTime? kwhTimestamp;
  double? kwhTotal;

  MeterKwhReading({
    // required this.id,
    required this.kwhTimestamp,
    required this.kwhTotal,
  });

  factory MeterKwhReading.fromJson(Map<String, dynamic> json) {
    //parse the json string to DateTime
    DateTime kwhTimestamp = DateTime.parse(json['kwh_timestamp']);
    //parse the string to Float
    double kwhTotal = double.parse(json['kwh_total']);

    return MeterKwhReading(
      // id: json['id'],
      kwhTimestamp: kwhTimestamp,
      kwhTotal: kwhTotal,
      // kwhDiff: json['kwh_diff'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id,
      'kwh_timestamp': kwhTimestamp,
      'kwh_total': kwhTotal,
      // 'kwh_diff': kwhDiff,
    };
  }
}
