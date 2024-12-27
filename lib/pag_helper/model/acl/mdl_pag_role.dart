import 'package:buff_helper/pag_helper/def/def_role.dart';

class MdlPagRole {
  int id;
  String name;
  String? label;
  int rank;
  PagPortalType portalType;

  MdlPagRole({
    required this.id,
    required this.name,
    this.label,
    this.rank = -1,
    this.portalType = PagPortalType.none,
  });

  factory MdlPagRole.fromJson(Map<String, dynamic> json) {
    dynamic id = json['id'];
    if (id is String) {
      id = int.parse(id);
    }

    dynamic rank = json['rank'] ?? -1;
    if (rank is String) {
      rank = int.tryParse(rank);
    }

    PagPortalType portalType = PagPortalType.byLabel(json['portal_type']);

    return MdlPagRole(
      id: id,
      name: json['name'],
      label: json['label'],
      rank: rank,
      portalType: portalType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'label': label,
      'rank': rank,
      'portal_type': portalType.label,
    };
  }
}
