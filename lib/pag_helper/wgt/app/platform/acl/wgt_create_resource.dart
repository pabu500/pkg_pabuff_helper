import 'package:flutter/material.dart';

import '../../../../../xt_ui/xt_helpers.dart';
import '../../../../model/mdl_pag_app_config.dart';
import '../../../../model/mdl_pag_user.dart';

class WgtCreateResource extends StatefulWidget {
  const WgtCreateResource({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
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
