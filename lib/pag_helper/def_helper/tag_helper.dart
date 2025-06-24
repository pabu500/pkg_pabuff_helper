import 'package:buff_helper/pag_helper/def_helper/def_fleet_health.dart';
import 'package:buff_helper/pag_helper/def_helper/def_role.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget getTagList({
  required BuildContext context,
  required Map<String, dynamic> row,
  required Map<String, dynamic> configItem,
  required String tagText,
  Color? tagColor,
  String? tagTooltip,
  required double width,
}) {
  List<String> tagList = tagText.split(',');
  List<Widget> tagWidgets = [];
  for (String tag in tagList) {
    tagWidgets.add(
      getTag2(
        context: context,
        row: row,
        configItem: configItem,
        tagText: tag,
        tagColor: tagColor,
        tagTooltip: tagTooltip,
        width: width,
      ),
    );
  }
  return SizedBox(
    width: width,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: tagWidgets,
    ),
  );
}

Widget getTag2({
  required BuildContext context,
  required Map<String, dynamic> row,
  required Map<String, dynamic> configItem,
  required String tagText,
  Color? tagColor,
  String? tagTooltip,
  required double width,
}) {
  try {
    String tagLabel = '';
    Color tagColor = Colors.grey;
    if (configItem['col_key'] == 'portal_type_str') {
      PagPortalType portalType = PagPortalType.byLabel(tagText);
      tagLabel = portalType.tag;
      tagColor = portalType.color;
    } else if (configItem['col_key'] == 'issue_type_name') {
      PagFleetHealthIssueType issueType =
          PagFleetHealthIssueType.values.byName(tagText);
      tagLabel = issueType.tag;
      tagColor = issueType.color;
    } else if (configItem['col_key'] == 'health') {
      PagFleetHealthStatus issueStatus = PagFleetHealthStatus.byLabel(tagText);
      tagLabel = issueStatus.tag;
      tagColor = issueStatus.color;
    } else {
      tagLabel = tagText;
      tagColor = tagColor ?? Colors.grey;
    }
    return Tooltip(
      message: tagTooltip ??
          configItem['getTooltip']?.call(row[configItem['fieldKey']]) ??
          '',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        height: 23,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        margin: const EdgeInsets.only(right: 1),
        decoration: BoxDecoration(
          color: tagColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(tagLabel,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13.5)),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error in getTag2: $e');
    }
    return Container();
  }
}
