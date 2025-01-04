import 'package:buff_helper/pag_helper/model/fleet_health/mdl_pag_fh_stat.dart';

class MdlPagFleetHealth {
  List<MdlPagFhStat> fhStatList = [];

  MdlPagFleetHealth({
    required this.fhStatList,
  });

  // is empty
  get isEmpty => fhStatList.isEmpty;

  factory MdlPagFleetHealth.fromJson(Map<String, dynamic> json) {
    List<MdlPagFhStat> fhStatList = [];
    if (json['fleet_health'] != null) {
      for (var fhStat in json['fleet_health']) {
        fhStatList.add(MdlPagFhStat.fromJson(fhStat));
      }
    }
    return MdlPagFleetHealth(
      fhStatList: fhStatList,
    );
  }
}
