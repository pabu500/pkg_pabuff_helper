import 'package:flutter/material.dart';
import '../../../comm/comm_fin_ops.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';

class BillPaymentHoldController extends ChangeNotifier {
  BillPaymentHoldController(this.appConfig, this.user) {
    reason.addListener(notifyListeners);
  }
  final MdlPagAppConfig appConfig;
  final MdlPagUser user;
  final reason = TextEditingController();
  bool authorized = false, enabled = false, selected = false, _disposed = false;
  String accessError = '';
  bool get valid =>
      !selected || (authorized && enabled && reason.text.trim().isNotEmpty);
  Map<String, dynamic> get requestFields => selected
      ? {
          'bypass_payment_hold': true,
          'hold_override_reason': reason.text.trim(),
        }
      : {};
  void select(bool value) {
    selected = value && authorized && enabled;
    notifyListeners();
  }

  void reset() {
    selected = false;
    reason.clear();
    notifyListeners();
  }

  Future<void> fetchAccess() async {
    try {
      final access = await getPaymentHoldAccess(
        appConfig,
        {'scope': user.selectedScope.toScopeMap()},
        MdlPagSvcClaim(userId: user.id, username: user.username),
        loginToken: user.loginToken,
      );
      if (_disposed) return;
      authorized = access['is_authorized'] == true;
      enabled = access['enabled'] == true;
      accessError = '';
      if (!authorized || !enabled) selected = false;
    } catch (e) {
      if (_disposed) return;
      authorized = false;
      selected = false;
      accessError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    reason.dispose();
    super.dispose();
  }
}
