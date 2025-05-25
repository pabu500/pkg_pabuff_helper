import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../comm/comm_pag_job.dart';
import '../../model/mdl_pag_app_config.dart';
import 'job_def.dart';

class WgtPagPostJob extends StatefulWidget {
  const WgtPagPostJob({
    super.key,
    required this.loggedInUser,
    required this.pagAppConfig,
    this.tooltip,
    this.title,
    this.iconSize,
    this.iconColor,
    this.enabled = true,
    required this.jobRequest,
    this.opList = const [],
    this.onPosted,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig pagAppConfig;
  final String? title;
  final String? tooltip;
  final bool enabled;
  final double? iconSize;
  final Color? iconColor;
  final Map<String, String> jobRequest;
  final List<Map<String, dynamic>> opList;
  final Function? onPosted;

  @override
  State<WgtPagPostJob> createState() => _WgtPagPostJobState();
}

class _WgtPagPostJobState extends State<WgtPagPostJob> {
  Future<dynamic> _postJob() async {
    try {
      Map<String, dynamic> jobRequest = widget.jobRequest;
      jobRequest['job_task_type'] = PagJobTaskType.itemHistory.name;

      if ((widget.loggedInUser.emailVerified ?? false) &&
          widget.loggedInUser.email != null) {
        jobRequest['recipient_email'] = widget.loggedInUser.email!;
        jobRequest['recipient_name'] = widget.loggedInUser.username!;
      }

      Map<String, dynamic> requestMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'job_request': jobRequest,
        'op_list': widget.opList,
      };

      Map<String, dynamic> result = await doPagPostJob(
        widget.pagAppConfig,
        widget.loggedInUser,
        requestMap,
        MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: '',
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
        color: widget.iconColor ?? Theme.of(context).hintColor.withAlpha(130),
        size: widget.iconSize,
        // size: 16,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      tooltip: widget.tooltip ?? 'Post Job',
    );
  }
}
