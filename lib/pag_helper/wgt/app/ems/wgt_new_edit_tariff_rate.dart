import 'package:buff_helper/pag_helper/comm/comm_app.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/mdl_pag_app_config.dart';
import '../../datetime/wgt_pag_date_range_picker2.dart';

class WgtNewEditTariffRate extends StatefulWidget {
  const WgtNewEditTariffRate({
    super.key,
    required this.appConfig,
    required this.groupItemId,
    required this.tariffPackageMeterType,
    this.initialValueMap,
    this.compactViewOnly = false,
    this.readOnly = false,
    this.onInsert,
    this.onClose,
    this.onUpdate,
    this.onRemove,
    this.rateDecimal = 4,
    this.width = 360,
  });

  final MdlPagAppConfig appConfig;
  final String groupItemId;
  final String tariffPackageMeterType;
  final bool readOnly;
  final Function? onInsert;
  final Function? onClose;
  final Function? onUpdate;
  final Function? onRemove;
  final Map<String, dynamic>? initialValueMap;
  final bool compactViewOnly;
  final int rateDecimal;
  final double width;

  @override
  State<WgtNewEditTariffRate> createState() => _WgtNewEditTariffRateState();
}

class _WgtNewEditTariffRateState extends State<WgtNewEditTariffRate> {
  late MdlPagUser? _loggedInUser;

  late final String? iniMonthStr;

  late final isUpdate = widget.initialValueMap != null;

  String? _rate;
  String? _gstStr;
  String? _monthStr;
  DateTime? _fromDateTime;
  DateTime? _toDateTime;
  String? _remark;

  bool _isEditing = false;
  bool _isRateValidated = false;
  bool _isGstValidated = false;
  bool _isMonthValidated = false;
  bool _isRemarkValidated = false;

  String _errorText = '';

  String _resultStatusErrorText = '';

  bool _gettingGstRate = false;
  int _pullFailed = 0;

  Future<dynamic> _getGstRate() async {
    setState(() {
      _gettingGstRate = true;
    });
    try {
      dynamic data = await getPagSysVar(
          widget.appConfig,
          {
            'name': 'gst',
            'from_timestamp': _fromDateTime?.toIso8601String() ?? '',
            'to_timestamp': _toDateTime?.toIso8601String() ?? '',
          },
          MdlPagSvcClaim(
            scope: '',
            target: '',
            operation: '',
          ));
      if (data == null) {
        throw Exception('Invalid GST rate');
      }

      if (data['sys_var'] == null) {
        throw Exception('Invalid GST rate');
      }

      final sysVal = data['sys_var'];
      if (sysVal is! Map) {
        throw Exception('Invalid GST rate');
      }
      if (sysVal['gst'] == null) {
        throw Exception('Invalid GST rate');
      }

      if (sysVal['gst'] == null) {
        throw Exception('Invalid GST rate');
      }
      _gstStr = sysVal['gst'];
    } catch (e) {
      _pullFailed++;
      if (kDebugMode) {
        print('Error: $e');
      }
    } finally {
      setState(() {
        _gettingGstRate = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    if (widget.initialValueMap == null) {
      iniMonthStr = '-';
    } else {
      _rate = widget.initialValueMap?['rate'];
      _gstStr = widget.initialValueMap?['gst'];
      _fromDateTime = widget.initialValueMap?['from_datetime'];
      _toDateTime = widget.initialValueMap?['to_datetime'];
      _monthStr = '${_fromDateTime!.year}-${_fromDateTime!.month}';
      iniMonthStr = _monthStr!;

      _remark = widget.initialValueMap?['remark'];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pullFailed > 3) {
      return getErrorTextPrompt(
          context: context, errorText: 'Failed to get GST rate');
    }

    if (_fromDateTime == null || _toDateTime == null) {
      return getErrorTextPrompt(
          context: context, errorText: 'Invalid date range');
    }

    double? initialRate =
        double.tryParse(widget.initialValueMap?['rate'] ?? '');

    String? billingRecTariffRateIdStr = widget.initialValueMap?[
        'br_id_tariff_rate_id_${widget.tariffPackageMeterType.toLowerCase()}'];
    bool isRateApplied = billingRecTariffRateIdStr != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          horizontalSpaceSmall,
          SizedBox(
            width: 80,
            child: Tooltip(
              message: isRateApplied ? 'Rate is applied for billing' : '',
              waitDuration: const Duration(milliseconds: 500),
              child: WgtTextField(
                enabled: !widget.readOnly && !isRateApplied,
                appConfig: widget.appConfig,
                hintText: 'Rate',
                labelText: 'Rate',
                initialValue: initialRate?.toStringAsFixed(widget.rateDecimal),
                // maxLength: 8,
                validator: validateTariffPrice,
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _rate) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _rate = val;
                      double? rate = double.tryParse(val);
                      _rate = rate?.toStringAsFixed(widget.rateDecimal);
                    });
                  }

                  return null;
                },
                onEditingComplete: () {
                  setState(() {
                    _isEditing = false;
                  });
                  widget.onUpdate?.call(
                    {
                      'rate': _rate,
                      'gst': _gstStr,
                      'from_datetime': _fromDateTime,
                      'to_datetime': _toDateTime,
                      'from_timestamp': _fromDateTime?.toIso8601String(),
                      'to_timestamp': _toDateTime?.toIso8601String(),
                      'remark': _remark,
                    },
                  );
                },
                onValidate: (String? result) {
                  setState(() {
                    if (result == null) {
                      _isRateValidated = true;
                    } else {
                      _isRateValidated = false;
                    }
                  });
                },
              ),
            ),
          ),
          horizontalSpaceTiny,
          SizedBox(
            width: 50,
            child: _gstStr == null && !_gettingGstRate
                ? FutureBuilder(
                    future: _getGstRate(),
                    builder: (context, snapshot) {
                      if (_gettingGstRate) {
                        return const Center(child: WgtPagWait(size: 21));
                      }
                      return completedGstWidget();
                    },
                  )
                : completedGstWidget(),
          ),
          // WgtMonthPicker(
          //   readOnly: true,
          //   initialDate:
          //       widget.initialValueMap?['from_timestamp'] ?? widget.initialDate,
          //   onSet: (DateTime? startDate, DateTime? endDate) {
          //     if (kDebugMode) {
          //       print('Date: $startDate - $endDate');
          //     }
          //     // widget.onMonthPickerUpdated?.call(startDate, endDate);
          //   },
          // ),
          WgtPagDateRangePicker2(
            layout: 'vertical',
            isReadOnly: true,
            timezone: _loggedInUser!.selectedScope.getProjectTimezone(),
            startDateTime: _fromDateTime,
            endDateTime: _toDateTime,
            populateDefaultRange: true,
            onSet: (startDate, endDate) {},
          ),
          SizedBox(
            width: 150,
            child: WgtTextField(
              enabled: !widget.readOnly,
              appConfig: widget.appConfig,
              hintText: 'Remark',
              labelText: 'Remark',
              // key: _emailResetKey,
              initialValue: widget.initialValueMap?['remark'],
              // maxLength: 55,
              // validator: null,
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _remark) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _remark = val;
                  });
                }

                return null;
              },
              onEditingComplete: () {
                setState(() {
                  _isEditing = false;
                });
                widget.onUpdate?.call(
                  {
                    'rate': _rate,
                    'gst': _gstStr,
                    'from_datetime': _fromDateTime,
                    'to_datetime': _toDateTime,
                    'from_timestamp': _fromDateTime?.toIso8601String(),
                    'to_timestamp': _toDateTime?.toIso8601String(),
                    'remark': _remark,
                  },
                );
              },
              onValidate: (String? result) {
                setState(() {
                  if (result == null) {
                    _isRemarkValidated = true;
                  } else {
                    _isRemarkValidated = false;
                  }
                });
              },
            ),
          ),
          // verticalSpaceSmall,
          // getOpButton(),
        ],
      ),
    );
  }

  Widget getOpButton() {
    bool enableAdd = _rate != null &&
        _rate!.isNotEmpty &&
        _gstStr != null &&
        _gstStr!.isNotEmpty &&
        _remark != null &&
        _remark!.isNotEmpty;

    bool enableUpdate = _rate != widget.initialValueMap?['rate'] ||
        _gstStr != widget.initialValueMap?['gst'] ||
        _monthStr != iniMonthStr ||
        _remark != widget.initialValueMap?['remark'];

    bool enableOp = isUpdate ? enableUpdate : enableAdd;

    return Row(
      children: [
        Expanded(child: Container()),
        if (!widget.readOnly)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: !enableOp
                  ? Theme.of(context).colorScheme.secondary.withAlpha(55)
                  : Theme.of(context).colorScheme.secondary,
            ),
            child: InkWell(
              onTap: !enableOp
                  ? null
                  : () {
                      Map<String, dynamic> subInfo = {
                        'rate': _rate,
                        'gst': _gstStr,
                        'month': _monthStr,
                        'remark': _remark,
                      };
                      if (isUpdate) {
                        widget.onUpdate?.call(subInfo);
                      } else {
                        widget.onInsert?.call(subInfo);
                      }
                    },
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(isUpdate ? 'Update' : 'Add')),
            ),
          ),
        horizontalSpaceSmall,
        IconButton(
          onPressed: () {
            widget.onClose?.call();
          },
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget completedGstWidget() {
    return WgtTextField(
      appConfig: widget.appConfig,
      enabled: false,
      labelText: 'GST',
      initialValue: _gstStr.toString(),
      // widget.initialValueMap?['gst'] == null
      //     ? defaultGstRate.toString()
      //     : widget.initialValueMap?['gst'].toString(),
      showClearButton: false,
      validator: (String? value) {
        if ((value ?? '').isEmpty) {
          return null;
        }
        // numeric only and between 0 and 100
        double? val = double.tryParse(value!);
        if (val == null) {
          return 'numeric only';
        }
        if (val < 0 || val > 1000) {
          return '0 to 20 only';
        }
      },
      onChanged: (String value) {
        _gstStr = value;
        widget.onUpdate?.call(
          {
            'rate': _rate,
            'gst': _gstStr,
            'from_timestamp': _fromDateTime,
            'to_timestamp': _toDateTime,
          },
        );
      },
      onEditingComplete: () {
        widget.onUpdate?.call(
          {
            'rate': _rate,
            'gst': _gstStr,
            'from_timestamp': _fromDateTime,
            'to_timestamp': _toDateTime,
          },
        );
      },
    );
  }
}
