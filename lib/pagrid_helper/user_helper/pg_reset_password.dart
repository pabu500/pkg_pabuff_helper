import 'dart:async';

import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../pag_helper/comm/comm_user_service.dart';
import '../../pag_helper/wgt/user/wgt_update_password.dart';

class PgResetPassword extends StatefulWidget {
  const PgResetPassword({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser? loggedInUser;

  @override
  State<PgResetPassword> createState() => _PgResetPasswordState();
}

class _PgResetPasswordState extends State<PgResetPassword> {
  late MdlPagUser? loggedInUser;

  final double _width = 360;

  @override
  void initState() {
    super.initState();
    loggedInUser = widget.loggedInUser;
  }

  @override
  Widget build(BuildContext context) {
    if (loggedInUser == null) {
      Timer(const Duration(milliseconds: 100), () {
        context.go('/login');
      });
    }
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.primary, width: 1),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 34),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reset Password',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor),
              ),
              verticalSpaceSmall,
              Container(
                height: 330,
                padding: const EdgeInsets.only(right: 40),
                child: WgtPagUpdatePassword(
                  appConfig: widget.appConfig,
                  width: _width,
                  padding: EdgeInsets.zero,
                  showUsername: false,
                  showBorder: false,
                  sideExpanded: false,
                  loggedInUser: loggedInUser!,
                  changeTargetUserId: loggedInUser!.id!,
                  // requestByUsername:loggedInUser!.username!,
                  // userId:loggedInUser!.id!,
                  updatePassword: doUpdateUserKeyValue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
