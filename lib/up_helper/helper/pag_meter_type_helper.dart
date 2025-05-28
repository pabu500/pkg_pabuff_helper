import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

Widget getPagMeterTypeWidget(MeterType meterType, BuildContext context,
    {String? displayContextStr}) {
  Color iconColor = Theme.of(context).hintColor.withAlpha(130);
  return Row(
    children: [
      Text(
        getMeterTypeTag(meterType),
        style: TextStyle(
            color: Theme.of(context).hintColor,
            fontWeight: FontWeight.bold,
            fontSize: 21),
      ),
      getDeviceTypeIcon(meterType, iconSize: 34, iconColor: iconColor),
      Text(
        getDeivceTypeUnit(meterType, displayContextStr: displayContextStr),
        style: defStatStyle,
      ),
    ],
  );
}
