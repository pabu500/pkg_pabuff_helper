import 'package:flutter/material.dart';

import '../../../../../xt_ui/xt_helpers.dart';
import '../../../../model/mdl_pag_app_config.dart';

class WgtCreatePermission extends StatefulWidget {
  const WgtCreatePermission({
    super.key,
    required this.appConfig,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final Function? onCreated;

  @override
  State<WgtCreatePermission> createState() => _WgtCreatePermissionState();
}

class _WgtCreatePermissionState extends State<WgtCreatePermission> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceTiny,
          Text('Create Permission Form'),
          verticalSpaceMedium,
        ],
      ),
    );
  }
}
