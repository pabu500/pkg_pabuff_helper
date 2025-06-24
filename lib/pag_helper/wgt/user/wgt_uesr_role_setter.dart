import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';

import '../../model/mdl_pag_app_config.dart';

class WgtUesrRoleSetter extends StatefulWidget {
  const WgtUesrRoleSetter({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.userIndexStr,
    this.width = 395,
    this.height,
    this.onUserRoleListLoaded,
    this.onUserRoleListSet,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final String userIndexStr;
  final double width;
  final double? height;
  final Function(List<Map<String, dynamic>>)? onUserRoleListLoaded;
  final Function(List<Map<String, dynamic>>)? onUserRoleListSet;

  @override
  State<WgtUesrRoleSetter> createState() => _WgtUesrRoleSetterState();
}

class _WgtUesrRoleSetterState extends State<WgtUesrRoleSetter> {
  final List<Map<String, dynamic>> _userRoleListOriginal = [];
  final List<Map<String, dynamic>> _userRoleList = [];
  String _errorTextRoleList = '';

  bool _isEditing = false;
  bool _isCommitting = false;
  bool _isModified = false;
  bool _showCommitted = true;
  String _committedMessage = '';
  String _committErrorText = '';
  UniqueKey? _listRefreshKey;

  Future<Map<String, dynamic>> _commit() async {
    _committErrorText = '';
    _isCommitting = true;

    Map<String, dynamic> result = {};
    try {
      Map<String, dynamic> querrMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'user_id': widget.userIndexStr,
        'user_role_list': _userRoleList,
      };

      result = await commitUserRoleList(
        widget.appConfig,
        widget.loggedInUser,
        querrMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'update',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      result['message'] = e.toString();
      _committErrorText = 'Error committing changes';
    } finally {
      _isCommitting = false;
      _showCommitted = true;
      _updateOriginal();
      widget.onUserRoleListSet?.call(_userRoleList);
    }

    return result;
  }

  Future<dynamic> _getUserRoleList() async {
    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'user_id': widget.userIndexStr,
    };

    _errorTextRoleList = '';

    try {
      var result = await doGetUserRoleList(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      if (result['user_role_list'] != null) {
        _userRoleList.clear();
        for (MdlPagRole item in result['user_role_list']) {
          _userRoleList.add(item.toJson());
        }
        _updateOriginal();
      }
    }
    // catch (e) {
    //   if (kDebugMode) {
    //     print('error: $e');
    //   }
    // }
    finally {
      _errorTextRoleList = 'Error getting role list';
      widget.onUserRoleListLoaded?.call(_userRoleList);
    }
  }

  void _updateOriginal() {
    _userRoleListOriginal.clear();
    _userRoleListOriginal.addAll(_userRoleList);
  }

  void _restoreOriginal() {
    setState(() {
      _isModified = false;
      _isEditing = false;
      _userRoleList.clear();
      _userRoleList.addAll(_userRoleListOriginal);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool pull = false;

    if (_userRoleList.isEmpty && !_isEditing) {
      pull = true;
    }
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).hintColor.withAlpha(50),
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pull
          ? FutureBuilder(
              future: _getUserRoleList(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const Center(child: WgtPagWait(size: 21));
                  default:
                    if (snapshot.hasError) {
                      if (kDebugMode) {
                        print(snapshot.error);
                      }
                      return getErrorTextPrompt(
                          context: context, errorText: _errorTextRoleList);
                    } else {
                      if (kDebugMode) {
                        print('FutureBuilder -> getCompletedVisibleRoleList');
                      }
                      return getCompletedUserRoleList();
                    }
                }
              },
            )
          : getCompletedUserRoleList(),
    );
  }

  Widget getCompletedUserRoleList() {
    List<Widget> roleList = [];
    List<Map<String, dynamic>> roleInfoList = [];
    for (var role
        in widget.loggedInUser.selectedScope.projectProfile!.visibleRoleList) {
      roleInfoList.add(role.toJson());
    }
    for (var role in roleInfoList) {
      for (var userRoleInfo in _userRoleList) {
        if (role['name'] == userRoleInfo['name']) {
          role['selected'] = true;
        }
      }
      roleList.add(Row(
        children: [
          Checkbox(
            value: role['selected'] ?? false,
            onChanged: !(_isEditing || _isCommitting)
                ? null
                : (bool? newValue) {
                    setState(() {
                      role['selected'] = newValue!;
                      if (newValue) {
                        _userRoleList.add(role);
                      } else {
                        _userRoleList.removeWhere((element) {
                          return element['name'] == role['name'];
                        });
                      }
                      // _listRefreshKey = UniqueKey();

                      //compare the original list with the modified list
                      if (_userRoleListOriginal.length !=
                          _userRoleList.length) {
                        _isModified = true;
                      }
                    });
                  },
          ),
          horizontalSpaceTiny,
          Text(
            role['label'] ?? role['name'],
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ));
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('Roles', style: TextStyle(color: Theme.of(context).hintColor)),
          verticalSpaceTiny,
          ...roleList,
          getControl(),
          if (_committErrorText.isNotEmpty)
            getErrorTextPrompt(context: context, errorText: _committErrorText),
        ],
      ),
    );
  }

  Widget getControl({String errorText = ''}) {
    if (_committErrorText.isNotEmpty) {
      return Container();
    }

    bool enableCommit = false;
    bool showClear = false;

    if (_isModified || _isEditing) {
      enableCommit = true;
      showClear = true;
    }

    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          horizontalSpaceSmall,
          SizedBox(
            width: 35,
            child: showClear
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _restoreOriginal();
                    },
                  )
                : Container(),
          ),
          Expanded(child: Container()),
          if (_showCommitted)
            Row(
              children: [
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _committedMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          Expanded(child: Container()),
          _isEditing
              ? IconButton(
                  icon: Icon(Icons.check,
                      color: enableCommit
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  onPressed: !enableCommit || _isCommitting
                      ? null
                      : () async {
                          if (!_isModified) {
                            setState(() {
                              _isEditing = false;
                            });
                            return;
                          }

                          Map<String, dynamic>? result = await _commit();

                          setState(() {
                            _isEditing = false;
                            _isModified = false;

                            _committedMessage =
                                result['message'] ?? 'Change committed';
                          });
                        },
                )
              : IconButton(
                  icon: Icon(Icons.edit, color: Theme.of(context).hintColor),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _showCommitted = false;
                    });
                  },
                ),
          horizontalSpaceSmall,
        ],
      ),
    );
  }
}
