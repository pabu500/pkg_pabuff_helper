import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/util/date_time_util.dart';
import 'package:flutter/material.dart';

Widget getJobScheduledBox(
    BuildContext context, String jobPrefix, DateTime scheduledTime) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(5),
    ),
    child: xtInfoBox(
        icon: Icon(Icons.check_circle,
            color: Theme.of(context).colorScheme.primary),
        iconTextSpace: 3,
        text:
            '$jobPrefix scheduled at ${getDateTimeStrFromDateTime(scheduledTime)}'),
  );
}
