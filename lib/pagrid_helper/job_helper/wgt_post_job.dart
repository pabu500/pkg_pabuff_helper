import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'comm_job.dart';

class WgtPostJob extends StatefulWidget {
  const WgtPostJob({
    super.key,
    required this.appConfig,
    required this.scopeProfile,
    required this.loggedInUser,
    this.tooltip,
    this.title,
    this.iconSize,
    this.iconColor,
    this.enabled = true,
    required this.jobRequest,
    this.opList = const [],
    this.onPosted,
  });

  final PaGridAppConfig appConfig;
  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final String? title;
  final String? tooltip;
  final bool enabled;
  final double? iconSize;
  final Color? iconColor;
  final Map<String, String> jobRequest;
  final List<Map<String, dynamic>> opList;
  final Function? onPosted;

  @override
  State<WgtPostJob> createState() => _WgtPostJobState();
}

class _WgtPostJobState extends State<WgtPostJob> {
  Future<dynamic> _postJob() async {
    try {
      Map<String, String> jobRequest = widget.jobRequest;

      if ((widget.loggedInUser!.emailVerified ?? false) &&
          widget.loggedInUser!.email != null) {
        jobRequest['recipient_email'] = widget.loggedInUser!.email!;
        jobRequest['recipient_name'] = widget.loggedInUser!.username!;
      }

      Map<String, dynamic> result = await doPostJob(
        widget.appConfig,
        JobTaskType.itemHistory,
        jobRequest,
        widget.opList,
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: widget.scopeProfile.getEffectiveScopeStr(),
          target: widget.jobRequest['target']!,
          operation: widget.jobRequest['operation']!,
        ),
      );

      if (widget.onPosted != null) {
        widget.onPosted!(result);
      }

      return result;
    } catch (err) {
      if (kDebugMode) {
        print('post job error: $err');
      }
      return 'Job post failed';
    } finally {}
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.enabled ? _postJob : null,
      icon: Icon(
        Symbols.schedule_send,
        color:
            widget.iconColor ?? Theme.of(context).hintColor.withOpacity(0.55),
        size: widget.iconSize,
        // size: 16,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      tooltip: widget.tooltip ?? 'Post Job',
    );
  }
}
