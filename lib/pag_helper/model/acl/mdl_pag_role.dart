import 'package:buff_helper/pag_helper/def_helper/def_role.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';

class MdlPagRole {
  int id;
  String name;
  String? label;
  String? tag;
  int rank;
  PagPortalType portalType;
  PagScopeType scopeType;
  String scopeLabel;

  MdlPagRole({
    required this.id,
    required this.name,
    this.label,
    this.tag,
    this.rank = -1,
    this.portalType = PagPortalType.none,
    this.scopeType = PagScopeType.none,
    this.scopeLabel = '',
  });

  bool isAdmin() {
    return label?.toLowerCase().contains('admin') ?? false;
  }

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

    // get scope type
    String? sgId = json['sg_id'];
    String? sId = json['s_id'];
    String? bId = json['b_id'];
    String? lgId = json['lg_id'];
    PagScopeType sType = PagScopeType.none;
    if (lgId != null) {
      sType = PagScopeType.locationGroup;
    } else if (bId != null) {
      sType = PagScopeType.building;
    } else if (sId != null) {
      sType = PagScopeType.site;
    } else if (sgId != null) {
      sType = PagScopeType.siteGroup;
    }

    return MdlPagRole(
      id: id,
      name: json['name'],
      label: json['label'],
      tag: json['tag'],
      rank: rank,
      portalType: portalType,
      scopeType: sType,
      scopeLabel: json['scope_label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'label': label,
      'tag': tag,
      'rank': rank,
      'portal_type_label': portalType.label,
      'portal_type_name': portalType.name,
      'scope_type_label': scopeType.label,
      'scope_label': scopeLabel,
    };
  }
}
