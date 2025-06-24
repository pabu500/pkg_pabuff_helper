import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:flutter/material.dart';

enum PagTopStatType {
  EMPTY,
  CONSOLE_HOME_PROJECT_COUNT,
  CONSOLE_HOME_TOTAL_SITE_COUNT,
  CONSOLE_HOME_PROJECT_SITE_COUNT,
  EMS_USAGE_TOTAL_E,
  EMS_USAGE_TOTAL_E_MAIN,
  EMS_USAGE_TOTAL_E_SUB,
  EMS_USAGE_TOTAL_W,
  EMS_USAGE_TOTAL_B,
  EMS_USAGE_TOTAL_G,
  EMS_USAGE_TOTAL_N,
  ESM_USAGE_TOTAL_BIDIR,
  EMS_RECEIVED_TOTAL,
  EMS_DELIVERED_TOTAL,
  MM_METER_COUNT_E,
  MM_METER_COUNT_W,
  MM_METER_COUNT_B,
  MM_METER_COUNT_G,
  MM_METER_COUNT_N,
  MM_METER_COUNT_BIDIR,
  SM_SENSOR_COUNT,
  LM_LOCK_COUNT,
  PTW_EVENT_COUNT,
  PTW_APPLICATION_COUNT,
  VM_CAMERA_COUNT,
  VM_EVENT_COUNT,
  VM_TOP_STAT1,
  VM_TOP_STAT2,
  VM_TOP_STAT3,
  GM_GATEWAY_COUNT,
}

enum PagProportionStatType {
  EMPTY,
  MM_METER_HEALTH,
  SM_SENSOR_HEALTH,
  LM_LOCK_HEALTH,
  VM_CAMERA_HEALTH,
  VM_EVENT_TYPE,
  GM_GATEWAY_HEALTH,
}

enum PagTrendingStatType {
  EMPTY,
  EMS_USAGE_HISTORY,
}

enum PagRankingStatType {
  EMPTY,
  EMS_USAGE_RANKING,
}

String getTopStatLabel(PagTopStatType topStatType, {String suffix = ''}) {
  String label = '';
  switch (topStatType) {
    case PagTopStatType.EMPTY:
      label = '';
      break;
    case PagTopStatType.CONSOLE_HOME_PROJECT_COUNT:
      label = 'Projects';
      break;
    case PagTopStatType.CONSOLE_HOME_TOTAL_SITE_COUNT:
      label = 'Total Sites';
      break;
    case PagTopStatType.CONSOLE_HOME_PROJECT_SITE_COUNT:
      label = 'Project Sites';
      break;
    case PagTopStatType.GM_GATEWAY_COUNT:
      label = 'Gateway Count';
      break;
    case PagTopStatType.EMS_RECEIVED_TOTAL:
      label = 'Received Total';
      break;
    case PagTopStatType.EMS_DELIVERED_TOTAL:
      label = 'Delivered Total';
      break;
    case PagTopStatType.EMS_USAGE_TOTAL_E:
      label = 'E Usage';
      break;
    case PagTopStatType.EMS_USAGE_TOTAL_E_MAIN:
      label = 'E Usage Main';
      break;
    case PagTopStatType.EMS_USAGE_TOTAL_E_SUB:
      label = 'E Usage Sub';
      break;
    case PagTopStatType.EMS_USAGE_TOTAL_W:
      label = 'W Usage';
      break;
    case PagTopStatType.EMS_USAGE_TOTAL_B:
      label = 'B Usage';
      break;
    case PagTopStatType.EMS_USAGE_TOTAL_G:
      label = 'G Usage';
      break;
    case PagTopStatType.EMS_USAGE_TOTAL_N:
      label = 'N Usage';
      break;
    case PagTopStatType.ESM_USAGE_TOTAL_BIDIR:
      label = 'S Usage';
      break;
    case PagTopStatType.MM_METER_COUNT_E:
      label = 'E Meter Count';
      break;
    case PagTopStatType.MM_METER_COUNT_W:
      label = 'W Meter Count';
      break;
    case PagTopStatType.MM_METER_COUNT_B:
      label = 'B Meter Count';
      break;
    case PagTopStatType.MM_METER_COUNT_G:
      label = 'G Meter Count';
      break;
    case PagTopStatType.MM_METER_COUNT_N:
      label = 'N Meter Count';
      break;
    case PagTopStatType.MM_METER_COUNT_BIDIR:
      label = 'S Meter Count';
      break;
    case PagTopStatType.SM_SENSOR_COUNT:
      label = 'Sensor Count';
      break;
    case PagTopStatType.LM_LOCK_COUNT:
      label = 'Lock Count';
      break;
    case PagTopStatType.PTW_EVENT_COUNT:
      label = 'PTW Event Count';
      break;
    case PagTopStatType.PTW_APPLICATION_COUNT:
      label = 'PTW Application Count';
      break;
    case PagTopStatType.VM_CAMERA_COUNT:
      label = 'Camera Count';
      break;
    case PagTopStatType.VM_EVENT_COUNT:
      label = 'VM Event Count';
      break;
    case PagTopStatType.VM_TOP_STAT1:
      label = 'VM_TOP_STAT1';
      break;
    case PagTopStatType.VM_TOP_STAT2:
      label = 'VM_TOP_STAT2';
      break;
    case PagTopStatType.VM_TOP_STAT3:
      label = 'VM_TOP_STAT3';
      break;

    default:
      label = '';
      break;
  }

  return label + suffix;
}

BoxDecoration getTopStatBoxDecoration(BuildContext context) {
  return BoxDecoration(
    border: Border(
      left: BorderSide(
        color: Theme.of(context).colorScheme.onSurface,
        width: 3.5,
      ),
    ),
  );
}

const BoxDecoration topStatBoxDecoration = BoxDecoration(
  border: Border(
    left: BorderSide(
      color: pagNeo,
      width: 3.5,
    ),
  ),
);

final BoxDecoration mainPanelBoxDecoration = BoxDecoration(
    // border: Border(
    //   left: BorderSide(
    //     color: pagNeo.withOpacity(0.08),
    //     width: 3.5,
    //   ),
    // ),
    );

final cornerColor = pagNeo.withOpacity(0.34);
