import 'package:buff_helper/pag_helper/def_helper/def_role.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'dart:developer' as dev;

import '../../def_helper/def_page_route.dart';

class MdlPagRole {
  int id;
  String name;
  String? label;
  String? tag;
  int rank;
  PagPortalType portalType;
  PagScopeType scopeType;
  String scopeLabel;
  PagPageRoute? homePageRoute;

  MdlPagRole({
    required this.id,
    required this.name,
    this.label,
    this.tag,
    this.rank = -1,
    this.portalType = PagPortalType.none,
    this.scopeType = PagScopeType.none,
    this.scopeLabel = '',
    this.homePageRoute,
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

    PagPortalType portalType = PagPortalType.byValue(json['portal_type']);
    assert(portalType != PagPortalType.none,
        'Invalid portal type: ${json['portal_type']}');

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

    String? homePageRouteStr = json['home_pr'];
    PagPageRoute? homePageRoute;
    if (homePageRouteStr != null) {
      try {
        homePageRoute = PagPageRoute.values.byName(homePageRouteStr);
      } catch (e) {
        dev.log('Invalid home page route: $homePageRouteStr');
      }
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
      homePageRoute: homePageRoute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'label': label,
      'tag': tag,
      'rank': rank,
      // 'portal_type_label': portalType.label,
      // 'portal_type_name': portalType.name,
      'portal_type': portalType.value,
      'scope_type_label': scopeType.label,
      'scope_label': scopeLabel,
      'home_page_route': homePageRoute?.name,
    };
  }
}
