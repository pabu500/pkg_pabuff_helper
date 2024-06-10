import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_helper/pagrid_app_config.dart';

class WgtBillLcStatusUpdate extends StatefulWidget {
  const WgtBillLcStatusUpdate({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.scopeProfile,
    required this.billingRec,
    required this.initialBillingLcStatusTagStr,
    required this.onUpdate,
  });

  final PaGridAppConfig appConfig;
  final Evs2User loggedInUser;
  final ScopeProfile scopeProfile;
  final Map<String, dynamic> billingRec;
  final String initialBillingLcStatusTagStr;
  final Function(String) onUpdate;

  @override
  State<WgtBillLcStatusUpdate> createState() => _WgtBillLcStatusUpdateState();
}

class _WgtBillLcStatusUpdateState extends State<WgtBillLcStatusUpdate> {
  String? _tagText;
  String _errorText = '';
  String _resultText = '';
  bool _isUpdating = false;

  Future<dynamic> _updateProfile(String key, String value,
      {String? oldVal}) async {
    if (value.isEmpty) {
      return {};
    }

    setState(() {
      _isUpdating = true;
      _errorText = '';
      _resultText = '';
    });
    try {
      List<Map<String, dynamic>> result = await doOpMultiKeyValUpdate(
        widget.appConfig,
        ItemType.billing_rec,
        ItemIdType.name,
        'multi_key_val_update',
        '',
        [
          {
            'name': widget.billingRec['name'],
            'id': widget.billingRec['id'],
            key: value,
            'checked': true,
          }
        ],
        SvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: widget.scopeProfile.getEffectiveScopeStr(),
          target: getAclTargetStr(AclTarget.bill_p_info),
          operation: AclOperation.update.name,
        ),
      );

      if (result.isNotEmpty) {
        if (result[0]['error'] != null) {
          setState(() {
            _errorText = result[0]['error'];
          });
        } else {
          setState(() {
            _resultText = 'Updated';
          });
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      String eMsg = e.toString();
      eMsg = eMsg.replaceAll('Exception: ', '');

      Map<String, dynamic> result = {};
      result['error'] = 'Error updating status';
      _errorText = result['error'];

      return result;
    } finally {
      if (_resultText.isNotEmpty) {
        widget.onUpdate(_tagText!);
      }
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tagText = widget.initialBillingLcStatusTagStr;
  }

  @override
  Widget build(BuildContext context) {
    bool updatedStatus = _tagText != widget.initialBillingLcStatusTagStr;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          for (var lcStatus in BillingLcStatus.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: InkWell(
                onTap: () {
                  // updateLcStatus(lcStatus);
                  setState(() {
                    _tagText = getBillingLcStatusTagStr(lcStatus.name);
                  });
                  // widget.onUpdate(lcStatus.name);
                },
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                    decoration: BoxDecoration(
                      color: getBillingLcStatusTagStr(lcStatus.name) == _tagText
                          ? updatedStatus
                              ? commitColor
                              : Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(getBillingLcStatusMessage(lcStatus.name))),
              ),
            ),
          if (_isUpdating) xtWait(color: Theme.of(context).colorScheme.primary),
          if (updatedStatus &&
              (_errorText.isEmpty && _resultText.isEmpty) &&
              !_isUpdating)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tagText = widget.initialBillingLcStatusTagStr;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  horizontalSpaceTiny,
                  TextButton(
                    onPressed: () async {
                      await _updateProfile(
                        'lc_status',
                        getBillingLcStatusFromTagStr(_tagText!)?.name ?? '',
                        oldVal: widget.initialBillingLcStatusTagStr,
                      );
                      // widget.onUpdate(_tagText!);
                    },
                    child: Text(
                      'Commit',
                      style: TextStyle(color: commitColor),
                    ),
                  ),
                ],
              ),
            ),
          if (_errorText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorText,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_resultText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _resultText,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}
