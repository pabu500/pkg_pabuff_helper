import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_meter_group.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/pag_app_context_list.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_item_type_selector.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/wgt/app/am/wgt_create_gateway.dart';
import 'package:buff_helper/pag_helper/wgt/app/am/wgt_create_mcu.dart';
import 'package:buff_helper/pag_helper/wgt/app/am/wgt_create_meter.dart';
import 'package:buff_helper/pag_helper/wgt/app/am/wgt_create_motherboard.dart';
import 'package:buff_helper/pag_helper/wgt/app/am/wgt_create_sim.dart';
import 'package:provider/provider.dart';

import '../../../model/mdl_pag_app_config.dart';
import 'wgt_create_meter_group.dart';

class WgtCreateDevice extends StatefulWidget {
  const WgtCreateDevice({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.itemTypeEnum,
    this.showTitle = true,
    this.showPortalType = true,
    this.showEnabled = true,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final PagDeviceCat? itemTypeEnum;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;

  final Function? onCreated;

  @override
  State<WgtCreateDevice> createState() => _CreateItemState();
}

class _CreateItemState extends State<WgtCreateDevice> {
  // late MdlPagUser? _loggedInUser;

  dynamic _selectedItemType;

  @override
  void initState() {
    super.initState();

    // _loggedInUser =
    //     Provider.of<PagUserProvider>(context, listen: false).currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceTiny,
          WgtItemTypeSelector(
            pagAppContext: appCtxAm,
            appConfig: widget.appConfig,
            itemKind: PagItemKind.device,
            enabledItemTypeList: widget.itemTypeEnum?.value != null
                ? [widget.itemTypeEnum!.value]
                : [
                    PagDeviceCat.meter.value,
                    PagDeviceCat.meterGroup.value,
                    PagDeviceCat.gateway.value,
                    PagDeviceCat.mcu.value,
                    PagDeviceCat.sim.value,
                    PagDeviceCat.motherboard.value,
                  ],
            prefKey: 'create_device_item_type',
            onItemTypeSelected: (itemType) {
              setState(() {
                _selectedItemType = itemType;
              });
            },
          ),
          verticalSpaceSmall,
          getCreateDeviceForm(itemType: _selectedItemType),
          verticalSpaceMedium,
        ],
      ),
    );
  }

  Widget getCreateDeviceForm({required dynamic itemType}) {
    if (itemType == null) {
      return const SizedBox.shrink();
    }
    if (itemType is! PagDeviceCat) {
      return const SizedBox.shrink();
    }
    if (itemType == PagDeviceCat.meter) {
      return WgtCreateMeter(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagDeviceCat.meterGroup) {
      return WgtCreateMeterGroup(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        serviceType: MeterGroupServiceType.comm,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagDeviceCat.gateway) {
      return WgtCreateGateway(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagDeviceCat.mcu) {
      return WgtCreateMcu(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagDeviceCat.sim) {
      return WgtCreateSim(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagDeviceCat.motherboard) {
      return WgtCreateMotherboard(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagDeviceCat.sensor) {
      return const SizedBox.shrink();
    } else if (itemType == PagDeviceCat.lock) {
      return const SizedBox.shrink();
    } else if (itemType == PagDeviceCat.camera) {
      return const SizedBox.shrink();
    } else {
      return const SizedBox.shrink();
    }
  }
}
