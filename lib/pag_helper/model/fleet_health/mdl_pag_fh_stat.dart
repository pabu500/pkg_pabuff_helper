import 'package:buff_helper/pag_helper/def_helper/def_fleet_health.dart';

class MdlPagFhStat {
  PagFleetHealthIssueType type;
  List<Map<String, dynamic>> fhList = [];
  int unknownCount = 0;
  int normalCount = 0;
  int typeIssueCount = 0;

// constructor
  MdlPagFhStat({
    required this.type,
    required this.fhList,
    required this.unknownCount,
    required this.normalCount,
    required this.typeIssueCount,
  });

  //factory constructor
  factory MdlPagFhStat.fromJson(Map<String, dynamic> json) {
    String fhTypeStr = json['fh_type'] ?? 'unknown';
    PagFleetHealthIssueType fhType =
        PagFleetHealthIssueType.values.byName(fhTypeStr);

    List<Map<String, dynamic>> fhList = [];
    int unknownCount = 0;
    int normalCount = 0;
    int typeIssueCount = 0;
    if (json['fh_list'] != null) {
      for (var fh in json['fh_list']) {
        String healthStr = fh['health'] ?? 'unknown';
        if (healthStr == 'unknown') {
          unknownCount++;
        } else if (healthStr == 'normal') {
          normalCount++;
        } else if (healthStr == fhType.label) {
          typeIssueCount++;
        }
        fhList.add(fh);
      }
    }
    return MdlPagFhStat(
      type: fhType,
      fhList: fhList,
      unknownCount: unknownCount,
      normalCount: normalCount,
      typeIssueCount: typeIssueCount,
    );
  }
}
