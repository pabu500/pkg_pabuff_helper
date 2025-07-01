import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';

class WgtTenantSoA extends StatefulWidget {
  const WgtTenantSoA({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.teneantInfo,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> teneantInfo;

  @override
  State<WgtTenantSoA> createState() => _WgtTenantSoAState();
}

class _WgtTenantSoAState extends State<WgtTenantSoA> {
  @override
  Widget build(BuildContext context) {
    String tenantName = widget.teneantInfo['name'] ?? '';
    String tenantLabel = widget.teneantInfo['label'] ?? '';
    if (tenantName.isEmpty || tenantLabel.isEmpty) {
      return getErrorTextPrompt(
          context: context, errorText: 'Error: Misising tenant name or label');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Statement of Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tenant: $tenantName ($tenantLabel)',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // Add more widgets to display SoA details here
      ],
    );
  }
}
