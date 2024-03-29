enum MeterRlsStatus { ON, OFF, UNKN }

enum MeterCommStatus {
  OK,
  TIMEOUT,
  UNKN,
  ERR1,
  ERR2,
  ERR3,
  ERR4,
  ERR5,
  ERR6,
  ERR7,
  ERR8,
  ERR9,
}

class MeterInfoModel {
  String? meterSn;
  String? meterDisplayname;
  String? address;
  String? status;
  String? rlsStatus;
  String? kwhTimestamp;
  double? kwhReading;
  int? readingInterval;
  double? current;
  double? voltage;
  List<int>? rlsHistory = [];

  MeterInfoModel(
      {this.meterSn,
      this.meterDisplayname,
      this.address,
      this.status,
      this.rlsStatus,
      this.kwhTimestamp,
      this.kwhReading,
      this.readingInterval,
      this.current,
      this.voltage,
      this.rlsHistory});

  factory MeterInfoModel.fromJson(Map<String, dynamic> json) {
    return MeterInfoModel(
      meterSn: json['meter_sn'],
      meterDisplayname: json['meter_displayname'],
      address: json['address'],
      status: json['status'],
      rlsStatus: json['rls_status'],
      kwhTimestamp: json['kwh_timestamp'],
      kwhReading: double.parse(json['kwh_reading']),
      readingInterval: json['read_interval'] ?? 0,
      current: double.parse(json['current']),
      voltage: double.parse(json['voltage']),
      rlsHistory: json['rls_history'] == null
          ? []
          : List<int>.from(json['rls_history'].map((x) => x)),
    );
  }

  bool isEmpty() => meterSn == null || meterSn!.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'meter_sn': meterSn,
      'meter_displayname': meterDisplayname,
      'address': address,
      'status': status,
      'rls_status': rlsStatus,
      'kwh_timestamp': kwhTimestamp,
      'kwh_reading': kwhReading,
      'reading_interval': readingInterval,
      'current': current,
      'voltage': voltage,
      'rls_history': rlsHistory,
    };
  }
}
