import 'package:flutter/material.dart';

import '../../../../../xt_ui/xt_helpers.dart';
import '../../../../model/mdl_pag_app_config.dart';

class WgtCreateResource extends StatefulWidget {
  const WgtCreateResource({
    super.key,
    required this.appConfig,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final Function? onCreated;

  @override
  State<WgtCreateResource> createState() => _WgtCreateResourceState();
}

class _WgtCreateResourceState extends State<WgtCreateResource> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceTiny,
          Text('Create Resource Form'),
          verticalSpaceMedium,
        ],
      ),
    );
  }
}
