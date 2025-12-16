import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../pagrid_helper/batch_op_helper/wgt_confirm_box.dart';
import '../../../up_helper/enum/enum_item.dart';
import '../../../util/util.dart';
import '../../comm/comm_pag_item.dart';
import '../../def_helper/dh_device.dart';
import '../../def_helper/dh_scope.dart';
import '../../def_helper/pag_item_helper.dart';
import '../../model/acl/mdl_pag_svc_claim.dart';
import '../../model/mdl_pag_user.dart';
import '../../model/provider/pag_user_provider.dart';
import 'dart:developer' as dev;

class WgtItemDeleteOp extends StatefulWidget {
  const WgtItemDeleteOp({
    super.key,
    required this.appConfig,
    required this.itemKind,
    required this.itemType,
    required this.itemIndexStr,
    required this.itemDeleteRef,
    this.listController,
    required this.onDeleting,
    required this.onDeleted,
  });
  final dynamic appConfig;
  final PagItemKind itemKind;
  final dynamic itemType;
  final String itemIndexStr;
  final dynamic itemDeleteRef;
  final dynamic listController;
  final Function onDeleting;
  final void Function(Map<String, dynamic> result) onDeleted;

  @override
  State<WgtItemDeleteOp> createState() => _WgtItemDeleteOpState();
}

class _WgtItemDeleteOpState extends State<WgtItemDeleteOp> {
  late MdlPagUser? _loggedInUser;
  bool _isDeleting = false;
  bool isEditableByAcl = false;
  bool isDeleteableByAcl = false;
  bool isDeleteableItem = false;
  String _deleteResultText = '';

  Future<dynamic> _doDelete() async {
    if (_isDeleting) {
      return {};
    }
    setState(() {
      _isDeleting = true;
    });
    widget.onDeleting.call();

    await Future.delayed(const Duration(milliseconds: 500));

    Map<String, dynamic> result = {};

    try {
      String itemTypeStr = '';
      if (widget.itemType is PagScopeType) {
        itemTypeStr = (widget.itemType as PagScopeType).name;
      } else if (widget.itemType is PagDeviceCat) {
        itemTypeStr = (widget.itemType as PagDeviceCat).name;
      }
      Map<String, dynamic> queryMap = {
        'scope': _loggedInUser!.selectedScope.toScopeMap(),
        'id': widget.itemIndexStr,
        'item_kind': widget.itemKind.name,
        'item_type': itemTypeStr,
        'item_id_type': ItemIdType.id.name,
        'item_id_key': 'id',
        'item_id_value': widget.itemIndexStr,
        'item_name': widget.itemDeleteRef,
      };
      if (widget.listController != null) {
        queryMap['item_table_name'] = widget.listController!.rootTableName;
      }

      dynamic data = await doPagDelete(
        widget.appConfig,
        _loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      result = data;

      if (result['error'] != null) {
        setState(() {
          _deleteResultText = result['error'];
        });
      } else {
        setState(() {
          _deleteResultText = 'Item deleted';
        });
      }
    } catch (e) {
      dev.log(e.toString());

      result = {
        'error': explainException(e, defaultMsg: 'Error deleting item')
      };
    } finally {
      setState(() {
        _isDeleting = false;
      });
      widget.onDeleted.call(result);
    }
  }

  @override
  void initState() {
    super.initState();

    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    bool isAtProjectLevel =
        _loggedInUser!.selectedScope.isAtScopeType(PagScopeType.project);
    bool isAdmin = _loggedInUser!.selectedRole?.isAdmin() ?? false;

    isEditableByAcl = isAdmin || isAtProjectLevel;

    isDeleteableItem = false;
    switch (widget.itemKind) {
      case PagItemKind.device:
        if (widget.itemType is PagDeviceCat) {
          if (widget.itemType == PagDeviceCat.meter) {
            isDeleteableItem = true;
          }
        }
        break;
      case PagItemKind.bill:
        isDeleteableItem = true;
        break;
      default:
        break;
    }

    isDeleteableByAcl = isAtProjectLevel && isAdmin;
  }

  @override
  Widget build(BuildContext context) {
    return _isDeleting
        ? const WgtPagWait()
        : _deleteResultText.isNotEmpty
            ? Text(
                _deleteResultText,
                style: const TextStyle(color: Colors.red),
              )
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return WgtConfirmBox(
                        title: 'Delete Confirmation',
                        message1:
                            'This operation will delete the selected item',
                        message2:
                            'It\'s recommended to double check before proceeding',
                        opName: 'item_delete',
                        // keyInConfirmStrList: [
                        //   'delete',
                        //   widget.itemDeleteRef,
                        // ],
                        itemCount: 1,
                        onConfirm: () async {
                          await _doDelete();
                        },
                      );
                    },
                  );
                },
              );
  }
}
