import 'package:buff_helper/xt_ui/wdgt/info/empty_result.dart';
import 'package:buff_helper/xt_ui/wdgt/xtInfoBox.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';

Widget getTypeTag(BuildContext context, String type) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withAlpha(128),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(type),
  );
}

Widget getTenantInfoBox(
  BuildContext context,
  int totalTenantCount,
  bool queryTenantsComplete,
  List<Map<String, dynamic>> tenentInfoList,
) {
  return !queryTenantsComplete
      ? Container()
      : totalTenantCount == 0
          ? const EmptyResult(message: 'No tenant found')
          : totalTenantCount > 1
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).hintColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: xtInfoBox(
                    icon: Icon(
                      Icons.info,
                      color: Theme.of(context).hintColor,
                    ),
                    text:
                        'More than 1 tenant found, please refine your search.',
                    textStyle: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).hintColor.withAlpha(55),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      child: Row(
                        children: [
                          getTypeTag(context, 'Tenant'),
                          horizontalSpaceSmall,
                          Text(
                              '${tenentInfoList.first['name']} - ${tenentInfoList.first['label']}'),
                        ],
                      ),
                    ),
                  ],
                );
}
