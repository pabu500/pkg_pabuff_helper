import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../../../../up_helper/enum/enum_item.dart';
import '../../../../util/util.dart';
import '../../../../xt_ui/wdgt/input/wgt_view_edit_field.dart';
import '../../../comm/comm_batch_op.dart';
import '../../../def_helper/pag_item_helper.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';

class WgtBillLineItemLabel extends StatefulWidget {
  const WgtBillLineItemLabel({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    required this.strBillingRecId,
    required this.itemKeyName,
    required this.lineItem,
    required this.width,
    required this.isEditableByAcl,
    this.onUpdate,
    this.initialCurrentField,
    this.initialErrorText,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final String strBillingRecId;
  final String itemKeyName;
  final Map<String, dynamic> lineItem;
  final double width;
  final bool isEditableByAcl;
  final VoidCallback? onUpdate;
  final String? initialCurrentField;
  final String? initialErrorText;

  @override
  State<WgtBillLineItemLabel> createState() => _LineItemsNotSubjectToTaxState();
}

class _LineItemsNotSubjectToTaxState extends State<WgtBillLineItemLabel> {
  // late final String strBillingRecId;

  String _label = '';
  String _currentField = '';
  bool _fieldUpdated = false;
  String _errorText = '';

  Future<List<Map<String, dynamic>>> _updateProfile(String key, String value,
      {String? oldVal, String? scopeProfileIdColName}) async {
    try {
      Map<String, dynamic> opItem = {
        'id': widget.strBillingRecId,
        key: value,
        'checked': true,
      };

      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'id': widget.strBillingRecId,
        'item_kind': PagItemKind.bill.name,
        'item_id_type': ItemIdType.id.name,
        'item_id_key': 'id',
        'item_id': widget.strBillingRecId,
        // 'key1, key2, key3, ...'
        'update_key_str': key,
        'op_name': 'multi_key_val_update',
        'op_list': [opItem],
      };

      List<Map<String, dynamic>> result = await doPagOpMultiKeyValUpdate(
        widget.appConfig,
        widget.loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser!.username,
          userId: widget.loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      return result;
    } catch (e) {
      dev.log(e.toString());

      //return a Map
      Map<String, dynamic> result = {};
      result['error'] = explainException(e, defaultMsg: 'Error updating field');

      //result is a List
      return [result];
    }
  }

  String? lineItemLabelValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Label cannot be empty';
    }
    if (value.length > 50) {
      return 'Label cannot exceed 50 characters';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final lineItem = widget.lineItem;

    if (lineItem.isEmpty) {
      return Container();
    }

    final String label = _label.isNotEmpty ? _label : lineItem['label'] ?? '';

    bool isEditableByAcl = true; // Replace with actual ACL check logic

    return SizedBox(
      width: widget.width,
      child: WgtViewEditField(
        width: 250,
        editable: isEditableByAcl,
        showCopy: false,
        useDatePicker: false,
        showLabel: true,
        labelWidth: 0,
        hintText: 'line item label',
        labelText: '',
        originalValue: label,
        onFocus: (hasFocus) {
          setState(() {
            _currentField = widget.itemKeyName;
          });
        },
        hasFocus: _currentField == widget.itemKeyName,
        onSetValue: (newValue) async {
          List<Map<String, dynamic>> result = await _updateProfile(
            widget.itemKeyName,
            newValue,
          );
          Map<String, dynamic> resultMap = result[0];
          if (resultMap['error'] == null) {
            setState(() {
              _label = newValue;

              _fieldUpdated = true;
              widget.onUpdate?.call();
            });
          } else {
            Map<String, dynamic> errorMap = resultMap['error'] is Map?
                ? resultMap['error']
                : {'status': resultMap['error'].toString()};
            String? status = errorMap['status'];
            dev.log('Status: $status');
            setState(() {
              _errorText = 'Error updating field';
            });
          }

          return resultMap;
        },
        validator: lineItemLabelValidator,
        textStyle: null,
      ),
    );
  }
}
