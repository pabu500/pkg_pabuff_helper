import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/app/mdl_project_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_page_route.dart';
import 'package:provider/provider.dart';

import '../model/mdl_pag_app_config.dart';

class WgtAppContextMenu extends StatefulWidget {
  const WgtAppContextMenu({
    super.key,
    required this.appConfig,
    required this.width,
    required this.title,
    // required this.routeList,
    required this.loggedInUser,
    required this.appContext,
    // this.routeList2 = const [],
    this.tileColor,
  });

  final MdlPagAppConfig appConfig;
  final double width;
  final String title;
  final MdlPagAppContext appContext;
  // final List<Map<String, dynamic>> routeList;
  // final List<PagPageRoute>? routeList2;
  final MdlPagUser loggedInUser;
  final Color? tileColor;

  @override
  State<WgtAppContextMenu> createState() => _WgtAppContextMenuState();
}

class _WgtAppContextMenuState extends State<WgtAppContextMenu> {
  bool _isPhone = false;
  String _dragStatus = '';
  final Map<PagPageRoute, bool> _aclGrantedByRoute = {};
  bool _aclCheckCompleted = false;
  int _aclRequestGeneration = 0;
  String? _aclRequestSignature;

  List<PagPageRoute> get routeList => widget.appContext.routeList ?? [];

  Offset _position = const Offset(0, 0);

  RenderBox? _renderBox;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _renderBox = context.findRenderObject() as RenderBox;
      await _checkMenuAcl();
    });
  }

  @override
  void didUpdateWidget(covariant WgtAppContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_aclRequestSignature != _getAclRequestSignature()) {
      _checkMenuAcl();
    }
  }

  List<String> _getMenuResLabels(PagPageRoute pageRoute) {
    return <String>[
      '${widget.appContext.name}.${pageRoute.name}',
      ...pageRoute.pageSectionList.map((pageSection) =>
          getResNameByPageRouteSection(
              widget.appContext, pageRoute, pageSection)!),
    ];
  }

  String _getAclRequestSignature() {
    final routeNames = routeList.map((route) => route.name).join(',');
    final scope = jsonEncode(widget.loggedInUser.selectedScope.toScopeMap());
    return '${widget.loggedInUser.id}|'
        '${widget.loggedInUser.selectedRole?.id}|'
        '${widget.appContext.name}|$routeNames|$scope';
  }

  Future<void> _checkMenuAcl() async {
    final routes = List<PagPageRoute>.from(routeList);
    final requestSignature = _getAclRequestSignature();
    final requestGeneration = ++_aclRequestGeneration;
    _aclRequestSignature = requestSignature;

    if (mounted) {
      setState(() {
        _aclCheckCompleted = false;
        _aclGrantedByRoute.clear();
      });
    }

    if (routes.isEmpty) {
      if (!mounted || requestGeneration != _aclRequestGeneration) return;
      setState(() {
        _aclCheckCompleted = true;
      });
      return;
    }

    final operation = AclOperation.read.name;
    final resourceLabelsByRoute = <PagPageRoute, List<String>>{
      for (final route in routes) route: _getMenuResLabels(route),
    };
    final permissionRequests = <Map<String, dynamic>>[
      for (final resourceLabels in resourceLabelsByRoute.values)
        for (final resourceLabel in resourceLabels)
          {
            'res_label': resourceLabel,
            'operation': operation,
          },
    ];

    final aclResultList = await checkAcl2(
      widget.appConfig,
      widget.appContext,
      widget.loggedInUser,
      permissionRequests,
    );

    if (!mounted ||
        requestGeneration != _aclRequestGeneration ||
        requestSignature != _getAclRequestSignature()) {
      return;
    }

    final grantedByResource = <String, bool>{};
    if (aclResultList is List) {
      for (final resultValue in aclResultList) {
        if (resultValue is! Map) continue;

        final result = Map<String, dynamic>.from(resultValue);
        final resLabel = result['res_label']?.toString();
        final resultOperation = result['operation']?.toString();
        if (resLabel == null || resultOperation != operation) continue;

        grantedByResource[resLabel] = result['result'] == 'granted';
      }
    }

    setState(() {
      for (final route in routes) {
        _aclGrantedByRoute[route] = resourceLabelsByRoute[route]!
            .any((resLabel) => grantedByResource[resLabel] ?? false);
      }
      _aclCheckCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isPhone = context.isPhone;
    // if (_renderBox == null) {
    //   return const SizedBox();
    // }
    // if (!_renderBox!.hasSize) {
    //   return const SizedBox();
    // }

    // PagAppProvider appModel = Provider.of<PagAppProvider>(context);

    // if (kDebugMode) {
    //   print(_position.dy);
    // }

    return _isPhone
        ? Container(
            // padding: const EdgeInsets.only(top: 20),
            child: getMenu(),
          )
        : AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _position.dy,
            right: 0,
            child: getDraggable(),
          );
  }

  Widget getDraggable() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 20),
          child: getMenu(),
        ),
        getDragHandle(),
      ],
    );
  }

  Widget getDragHandle() {
    // if (_renderBox == null) {
    //   return const SizedBox();
    // }
    return Opacity(
      opacity: _dragStatus == 'dragging' ? 0.21 : 1,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (_renderBox == null) {
            return;
          }
          setState(() {
            _position = Offset(_position.dx /* + details.delta.dx*/,
                _position.dy + details.delta.dy);
          });
        },
        child: Container(
          width: 50,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withAlpha(55),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSecondary.withAlpha(130),
            ),
          ),
        ),
      ),
    );
  }

  Widget getMenu() {
    PagAppProvider appModel = Provider.of<PagAppProvider>(context);
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: _dragStatus == 'dragging' ? 0.21 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: widget.tileColor ?? Theme.of(context).colorScheme.surface,
            border:
                Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
            borderRadius: BorderRadius.circular(5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: _isPhone
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ..._buildMenuItemList(appModel),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildMenuItemList(appModel),
                    verticalSpaceTiny,
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItemList(PagAppProvider appModel) {
    List<Widget> tiles = [];

    if (routeList.isNotEmpty) {
      for (PagPageRoute pr in routeList) {
        // uncomment the following line to enable ACL check
        // bool isDisabled =
        //     !_aclCheckCompleted || !(_aclGrantedByRoute[pr] ?? false);
        bool isDisabled = false;

        bool show = true;

        if (appModel.appName == 'pag_ems_tp') {
          if (pr == PagPageRoute.platformTaskManager ||
                  pr == PagPageRoute.emsDashboard ||
                  pr == PagPageRoute.emsMeterGroupManager ||
                  // pr == PagPageRoute.billingManager ||
                  pr == PagPageRoute.tenantManager ||
                  pr == PagPageRoute.tariffManager ||
                  pr == PagPageRoute.paymentManager ||
                  // pr == PagPageRoute.amgrManager ||
                  // pr == PagPageRoute.landlordManager
                  pr == PagPageRoute.amOrgManager
              // pr == PagPageRoute.meterManager
              ) {
            isDisabled = true;
            show = false;
          }
        }

        if (appModel.appName == 'pag_ems_op') {
          if (pr == PagPageRoute.platformAcl ||
              pr == PagPageRoute.platformSettings ||
              pr == PagPageRoute.billingManager ||
              pr == PagPageRoute.tariffManager ||
              pr == PagPageRoute.paymentManager ||
              // pr == PagPageRoute.amgrManager ||
              // pr == PagPageRoute.landlordManager
              pr == PagPageRoute.amOrgManager) {
            if (!widget.loggedInUser.selectedScope
                .isAtScopeType(PagScopeType.project)) {
              isDisabled = true;
            }
          }
        }

        if (widget.loggedInUser.selectedRole?.name
                .contains('project-billing-') ??
            false) {
          if (pr != PagPageRoute.platformTaskManager &&
              pr != PagPageRoute.emsMeterGroupManager &&
              pr != PagPageRoute.billingManager &&
              pr != PagPageRoute.paymentManager &&
              pr != PagPageRoute.tenantManager &&
              pr != PagPageRoute.tariffManager &&
              // pr != PagPageRoute.amgrManager &&
              // pr != PagPageRoute.landlordManager &&
              // pr != PagPageRoute.amOrgManager &&
              pr != PagPageRoute.meterManager) {
            isDisabled = true;
          }
        }

        if (widget.loggedInUser.selectedRole?.name.contains('project-ops-') ??
            false) {
          if (pr != PagPageRoute.platformTaskManager &&
              // pr != PagPageRoute.meterGroupManager &&
              pr != PagPageRoute.billingManager &&
              // pr != PagPageRoute.paymentManager &&
              pr != PagPageRoute.tenantManager &&
              pr != PagPageRoute.tariffManager &&
              // pr != PagPageRoute.amOrgManager &&
              pr != PagPageRoute.meterManager) {
            isDisabled = true;
          }
        }

        for (MdlPagProjectConfig appConfig in widget
            .loggedInUser.selectedScope.projectProfile!.appContextConfigList) {
          if (appConfig.appContextName != widget.appContext.name) {
            continue;
          }
          if (appConfig.ctxMenuVisibleScopeList.isEmpty) {
            continue;
          }
          for (Map<String, dynamic> menuItemConfig
              in appConfig.ctxMenuVisibleScopeList) {
            if (menuItemConfig['route'] != pr) {
              continue;
            }
            Map<String, dynamic>? ctxMenuConfig = menuItemConfig['config'];
            if (ctxMenuConfig == null) {
              continue;
            }

            if (ctxMenuConfig['visible_at_scope'] != null) {
              List<PagScopeType> visibleAtScopeList =
                  ctxMenuConfig['visible_at_scope'];
              if (visibleAtScopeList.isNotEmpty) {
                if (visibleAtScopeList.contains(
                    widget.loggedInUser.selectedScope.getScopeType())) {
                  // NOTE: do not set isDisabled to false here
                  // it may overwrite the previous isDisabled value
                  // isDisabled = false;
                } else {
                  isDisabled = true;
                }
              }
            }
          }
        }

        if (!show) {
          continue;
        }
        tiles.add(Tooltip(
          message: pr.label,
          waitDuration: const Duration(milliseconds: 500),
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    context.go('/${pr.route}');
                  },
            child: Container(
              width: _isPhone ? 50 : 35,
              height: _isPhone ? 50 : 35,
              margin: EdgeInsets.only(
                  left: 5, right: 5, top: 5, bottom: _isPhone ? 8 : 0),
              decoration: BoxDecoration(
                color: getToggledTileColor(pr, isDisabled),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                pr.iconData,
                size: 25,
                color: isDisabled
                    ? Theme.of(context).colorScheme.onSecondary.withAlpha(130)
                    : Theme.of(context)
                        .colorScheme
                        .onSecondary, //getTileTextStyle(pr).color,
              ),
            ),
          ),
        ));
      }
    }

    return tiles;
  }

  TextStyle getTileTextStyle(PagPageRoute pr) {
    PagAppProvider appModel = Provider.of<PagAppProvider>(context);

    if (kDebugMode) {
      print('prCur: ${appModel.prCur}');
    }

    return appModel.prCur == pr
        ? TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          )
        : TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(200));
  }

  Color getToggledTileColor(PagPageRoute pr, bool isDisabled) {
    PagAppProvider appModel = Provider.of<PagAppProvider>(context);

    return appModel.prCur == pr
        ? pag3.withAlpha(200)
        : isDisabled
            ? Theme.of(context).colorScheme.secondary.withAlpha(130)
            : Theme.of(context).colorScheme.secondary.withAlpha(210);
  }
}
