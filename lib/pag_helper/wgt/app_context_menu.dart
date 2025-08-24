import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/app/mdl_project_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:buff_helper/pag_helper/def_helper/def_page_route.dart';
import 'package:provider/provider.dart';

class WgtAppContextMenu extends StatefulWidget {
  const WgtAppContextMenu({
    super.key,
    required this.width,
    required this.title,
    // required this.routeList,
    required this.loggedInUser,
    required this.appContext,
    // this.routeList2 = const [],
    this.tileColor,
  });

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
  late final List<PagPageRoute> routeList;

  Offset _position = Offset(0, 0);

  RenderBox? _renderBox;

  @override
  void initState() {
    super.initState();

    routeList = widget.appContext.routeList!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderBox = context.findRenderObject() as RenderBox;
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

    PagAppProvider appModel = Provider.of<PagAppProvider>(context);

    if (kDebugMode) {
      print(_position.dy);
    }

    return AnimatedPositioned(
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
        if (!_isPhone) getDragHandle(),
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
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [..._buildMenuItemList(appModel)],
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
        bool isDisabled = false;
        bool show = true;

        if (appModel.appName == 'pag_ems_tp') {
          if (pr == PagPageRoute.consoleHomeTaskManager ||
                  pr == PagPageRoute.emsDashboard ||
                  pr == PagPageRoute.meterGroupManager ||
                  // pr == PagPageRoute.billingManager ||
                  pr == PagPageRoute.tenantManager ||
                  pr == PagPageRoute.tariffManager ||
                  pr == PagPageRoute.paymentManager ||
                  pr == PagPageRoute.landlordManager
              // pr == PagPageRoute.meterManager
              ) {
            isDisabled = true;
            show = false;
          }
        }

        if (appModel.appName == 'pag_ems_op') {
          if (pr == PagPageRoute.consoleHomeAcl ||
              pr == PagPageRoute.consoleHomeSettings ||
              pr == PagPageRoute.billingManager ||
              pr == PagPageRoute.tariffManager ||
              pr == PagPageRoute.paymentManager ||
              pr == PagPageRoute.landlordManager) {
            if (!widget.loggedInUser.selectedScope
                .isAtScopeType(PagScopeType.project)) {
              isDisabled = true;
            }
          }
        }

        if (widget.loggedInUser.selectedRole?.name
                .contains('project-billing-') ??
            false) {
          if (pr != PagPageRoute.consoleHomeTaskManager &&
              pr != PagPageRoute.meterGroupManager &&
              pr != PagPageRoute.billingManager &&
              pr != PagPageRoute.paymentManager &&
              pr != PagPageRoute.tenantManager &&
              pr != PagPageRoute.tariffManager &&
              pr != PagPageRoute.landlordManager &&
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
              width: 35,
              height: 35,
              margin: EdgeInsets.only(
                  left: 8, right: 8, top: 8, bottom: _isPhone ? 8 : 0),
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
