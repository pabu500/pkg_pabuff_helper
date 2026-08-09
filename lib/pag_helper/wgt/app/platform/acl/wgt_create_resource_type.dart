import 'package:flutter/material.dart';

import '../../../../../xt_ui/xt_helpers.dart';
import '../../../../model/mdl_pag_app_config.dart';

class WgtCreateResourceType extends StatefulWidget {
  const WgtCreateResourceType({
    super.key,
    required this.appConfig,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final Function? onCreated;

  @override
  State<WgtCreateResourceType> createState() => _WgtCreateResourceTypeState();
}

class _WgtCreateResourceTypeState extends State<WgtCreateResourceType> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceTiny,
          Text('Create Resource Type Form'),
          verticalSpaceMedium,
        ],
      ),
    );
  }
}
