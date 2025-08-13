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

enum PingStatus {
  yes,
  no,
  timeout,
  unknown,
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
  String? commType;
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
      this.commType,
      this.rlsHistory});

  factory MeterInfoModel.fromJson(Map<String, dynamic> json) {
    return MeterInfoModel(
      meterSn: json['meter_sn'],
      meterDisplayname: json['meter_displayname'],
      address: json['address'],
      status: json['status'] ?? '',
      rlsStatus: json['rls_status'] ?? '',
      kwhTimestamp: json['kwh_timestamp'] ?? '',
      kwhReading: double.parse(json['kwh_reading'] ?? '0'),
      readingInterval: json['read_interval'] ?? 30,
      current: double.parse(json['current'] ?? '0'),
      voltage: double.parse(json['voltage'] ?? '0'),
      commType: json['comm_type'] ?? 'mms',
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
      'comm_type': commType,
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
