import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WgtPagTableImporter extends StatefulWidget {
  const WgtPagTableImporter({
    super.key,
    this.opKey,
    required this.onImport,
    this.targetOpColConfig = const [],
    // target val is from the csv, not from populate
    this.isImportTargetVal = true,
    this.includeAddressCat = true,
    this.ignoreEmptyValue = false,
    this.listItemType = ListItemType.Meter,
    this.requiredFields = const [],
    this.identityField,
  });

  final Function(List<Map<String, dynamic>>, List<Map<String, dynamic>>, int)
      onImport;
  final List<Map<String, dynamic>> targetOpColConfig;
  final UniqueKey? opKey;
  final bool isImportTargetVal;
  final bool ignoreEmptyValue;
  final bool includeAddressCat;
  final ListItemType listItemType;
  final List<String> requiredFields;
  final String? identityField;

  @override
  State<WgtPagTableImporter> createState() => _WgtPagTableImporterState();
}

class _WgtPagTableImporterState extends State<WgtPagTableImporter> {
  final int maxBatchSize = 100;
  final List<List<dynamic>> _rawList = [];
  final List<Map<String, dynamic>> _opList = [];
  final List<Map<String, dynamic>> _listConfigBase = [];
  final List<Map<String, dynamic>> _listConfigFull = [];
  final List<Map<String, String>> _meterColsMapper = [];
  final List<String> _submittedListHeaders = [];
  String _checkHeaderMapperMessage = '';
  int _totalCsvErrorCount = 0;
  int _totalDbErrorCount = 0;
  String _missingColName = '';
  UniqueKey? _opKey;
  String _identityColName = '';

  Future<void> _getMeterList(List<List<dynamic>> entityList) async {
    if (entityList.length > maxBatchSize + 1) {
      showSnackBar(context, 'Maximum $maxBatchSize items at a time');
      return;
    }

    //clear _meterColsMapper
    for (Map<String, String> colMapper in _meterColsMapper) {
      colMapper['colHeader'] = '';
    }

    //get headers
    _submittedListHeaders.clear();
    _submittedListHeaders.addAll(entityList[0].map((e) => e.toString()));

    if ((widget.isImportTargetVal && _submittedListHeaders.length < 2) ||
        _submittedListHeaders.isEmpty) {
      showSnackBar(context, 'Missing item id column');
      return;
    }
    if (_submittedListHeaders.length > 13) {
      showSnackBar(context, 'Table format error');
      return;
    }
    // if (widget.requiredFields.isNotEmpty) {
    //   for (String requiredField in widget.requiredFields) {
    //     if (!_submittedListHeaders.contains(requiredField)) {
    //       showSnackBar(context, 'Missing required field: $requiredField');
    //       return;
    //     }
    //   }
    // }

    _listConfigFull.clear();
    // _listConfigFull.addAll(_listConfigBase);
    if (widget.includeAddressCat) {
      _listConfigFull.addAll(_listConfigBase);
    } else {
      _listConfigFull.addAll(
          _listConfigBase.where((element) => element['fieldCat'] != 'address'));
    }
    if (widget.targetOpColConfig.isEmpty) {
    } else {
      // _listConfigFull.clear();
      // _listConfigFull.addAll(_listConfigBase);
      // _listConfigFull.addAll(widget.targetOpColConfig);
      for (var element in widget.targetOpColConfig) {
        var colName = element['fieldKey'];
        if (_listConfigFull
            .where((element) => element['fieldKey'] == colName)
            .isEmpty) {
          // if (!widget.isImportTargetVal) {
          //   element['fieldKey'] = '${element['fieldKey']}_populated';
          // }
          _listConfigFull.add(element);
        } else {
          //set validator
          for (var configItem in _listConfigFull) {
            if (configItem['fieldKey'] == colName) {
              configItem['validator'] = element['validator'];
              break;
            }
          }
        }
      }
    }

    _meterColsMapper.clear();
    _meterColsMapper.addAll(_listConfigFull
        .map((e) => {
              'colName': e['fieldKey'] as String,
              'colHeader': '',
            })
        .toList());

    _prePop(_submittedListHeaders);

    _checkHeaderMapperMessage = _checkMapper();

    // if (_checkHeaderMapperMessage.isEmpty) {
    _rawList.clear();
    _rawList.addAll(entityList);
    // }

    setState(() {
      _submittedListHeaders;
    });
  }

  void _prePop(List<String> colHeaders) {
    List<String> availableHeaders = [];
    for (String header in colHeaders) {
      availableHeaders.add(header);
    }
    for (Map<String, String> colMapper in _meterColsMapper) {
      String colName = colMapper['colName']!.toLowerCase();
      String matchedHeader = _guessMatchedHeader(colName, availableHeaders);
      if (matchedHeader.isNotEmpty) {
        colMapper['colHeader'] = matchedHeader;
        availableHeaders.remove(matchedHeader);
      }
    }
  }

  String _guessMatchedHeader(String colName, List<String> colHeaders) {
    String matchedHeader = '';
    for (String header in colHeaders) {
      String cleanHeader = header
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('/', '')
          .replaceAll('_', '');
      String cleanColName = colName
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('/', '')
          .replaceAll('_', '');
      if (cleanHeader.contains(cleanColName) ||
          cleanColName.contains(cleanHeader) ||
          (cleanColName.contains('sn') && cleanHeader.contains('sn'))) {
        matchedHeader = header;
        break;
      }
    }
    return matchedHeader;
  }

  String _checkMapper() {
    String msg = '';
    _missingColName = '';
    _identityColName = '';
    // check for the following:
    // for the 1st 2 cols, at least 1 must be mapped
    // for the rest, at least 1 must be mapped
    // if widget.targetOpColConfig is not empty, all must be mapped
    if (widget.identityField != null) {
      _identityColName = widget.identityField!;
    }

    int mappedCount = 0;
    int i = 0;
    for (Map<String, String> colMapper in _meterColsMapper) {
      if (colMapper['colHeader']!.isNotEmpty) {
        mappedCount++;
      }
      i++;
      if (i == 2 && mappedCount == 0) {
        // showSnackBar(context, 'Missing item id column');
        return 'Missing item id column';
      } else {
        //1st col as identity col unless it's in opColsConfig
        if ((i == 1 || i == 2) &&
            _identityColName.isEmpty &&
            widget.targetOpColConfig
                .where((element) => element['fieldKey'] == colMapper['colName'])
                .isEmpty) {
          if (colMapper['colHeader'] != null &&
              colMapper['colHeader']!.isNotEmpty) {
            _identityColName = colMapper['colName']!;
          }
        }
      }
    }
    if (widget.isImportTargetVal) {
      if (mappedCount < 2) {
        // showSnackBar(context, 'Value column(s) not mapped');
        return 'Value column(s) not mapped';
      }
    }
    if (widget.requiredFields.isNotEmpty) {
      for (String requiredField in widget.requiredFields) {
        //if requiredField is not mapped
        if (_meterColsMapper
            .where((element) =>
                element['colName'] == requiredField &&
                element['colHeader']!.isNotEmpty)
            .isEmpty) {
          return 'Missing required field: $requiredField';
        }
      }
    }

    if (widget.isImportTargetVal) {
      if (widget.targetOpColConfig.isNotEmpty) {
        List<String> targetOpColNames = widget.targetOpColConfig
            .map((e) => e['fieldKey'] as String)
            .toList();
        for (String colName in targetOpColNames) {
          if (_meterColsMapper
              .where((element) =>
                  element['colName'] == colName &&
                  element['colHeader']!.isNotEmpty)
              .isEmpty) {
            setState(() {
              _missingColName = colName;
            });
            return 'Missing column: $colName';
          }
        }
      }
    } else {}

    return msg;
  }

  String _import() {
    String msg = '';
    _totalCsvErrorCount = 0;

    //get data
    _opList.clear();
    for (int i = 1; i < _rawList.length; i++) {
      List<dynamic> row = _rawList[i];
      Map<String, dynamic> rowMap = {};
      for (int j = 0; j < row.length; j++) {
        // rowMap[_submittedListHeaders[j]] = row[j].toString();
        String header = _submittedListHeaders[j];

        // rawList has more cols than _meterColsMapper
        var headerMap = _meterColsMapper.firstWhere(
            (element) => element['colHeader'] == header,
            orElse: () => {'': ''});
        String? headerKey = headerMap['colName'];
        if (headerKey == null) continue;
        if (!widget.isImportTargetVal &&
            widget.targetOpColConfig
                .where((element) => element['fieldKey'] == headerKey)
                .isNotEmpty) {
          continue;
        }
        rowMap[headerKey] = row[j].toString();
      }
      _opList.add(rowMap);
    }

    // update _listConfig title
    for (Map<String, String> colMapper in _meterColsMapper) {
      String colName = colMapper['colName']!;
      String colHeader = colMapper['colHeader'] ?? colName;
      //update _listConfig title
      for (Map<String, dynamic> configItem in _listConfigFull) {
        if (configItem['fieldKey'] == colName) {
          if (configItem['title'].isNotEmpty && colHeader.isEmpty) {
          } else {
            configItem['title'] = colHeader;
          }
          break;
        }
      }
    }

    // check col values
    for (int k = 0; k < _opList.length; k++) {
      Map<String, dynamic> opItem = _opList[k];
      Map<String, String> error = {};
      for (var header in _meterColsMapper) {
        String colHeader = header['colHeader']!;
        // if colHeader is empty, csv col is not mapped/not imported
        // no need to check value
        if (colHeader.isEmpty) {
          continue;
        }

        String colName = header['colName']!;

        if (widget.targetOpColConfig.isNotEmpty) {
          if (widget.targetOpColConfig
              .where((element) => element['fieldKey'] == colName)
              .isEmpty) {
            continue;
          }
        }

        String value = opItem[colName] ?? '';

        if (widget.isImportTargetVal) {
          if (value.isEmpty && !widget.ignoreEmptyValue) {
            error[colName] = 'Missing value';
            opItem['${colName}_error'] = 'Missing value';
            opItem['error'] = error;
            continue;
          }
        }

        var colConfig = _listConfigFull.firstWhere(
            (element) =>
                element['fieldKey'].toString().toLowerCase() ==
                colName.toLowerCase(),
            orElse: () => {'': ''});

        //validator
        var validator = colConfig['validator'];
        if (validator != null) {
          String? result = validator(value);
          if (result != null) {
            error.putIfAbsent(colName, () => result);
          }
        }
        if (error.isNotEmpty) {
          opItem['error'] = error;
        }
        //dbStrMapper
        var dbStrMapper = colConfig['dbStrMapper'];
        if (dbStrMapper != null && error.isEmpty) {
          String? result = dbStrMapper(value);
          if (result != null) {
            opItem[colName] = result;
          }
        }

        bool allowDuplicates = colConfig['allowDuplicates'] ?? true;

        if (!allowDuplicates && value.isNotEmpty) {
          //if it's checked, check for duplicates in the rest of the list
          if ((opItem['checked'] ?? true) == true) {
            for (int m = 1; m < _opList.length; m++) {
              Map<String, dynamic> otherOpItem = _opList[m];
              if ((otherOpItem['checked'] ?? true) &&
                  m != k &&
                  otherOpItem[colName] == value) {
                error[colName] = 'Duplicate value';
                opItem['error'] = error;
                break;
              }
            }
          }
        }
      }

      if (opItem['error'] == null) {
        opItem['checked'] = true;
        opItem['status'] = 'pending db check';
      } else {
        opItem['checked'] = false;
        opItem['status'] = 'csv check error';
        _totalCsvErrorCount++;
      }
    }

    // // if 2nd - last cols are empty, uncheck the row
    // for (int k = 0; k < _opList.length; k++) {
    //   Map<String, dynamic> opItem = _opList[k];
    //   bool allEmpty = true;
    //   for (int i = 2; i < _meterColsMapper.length; i++) {
    //     String colName = _meterColsMapper[i]['colName']!;
    //     String value = opItem[colName] ?? '';
    //     if (value.isNotEmpty) {
    //       allEmpty = false;
    //       break;
    //     }
    //   }
    //   if (allEmpty) {
    //     opItem['checked'] = false;
    //     opItem['status'] = 'not selected';
    //   }
    // }

    // if targetOpColConfig is cols values are all empty, uncheck the row
    if (widget.isImportTargetVal) {
      for (int k = 0; k < _opList.length; k++) {
        Map<String, dynamic> opItem = _opList[k];
        bool allEmpty = true;
        for (int i = 0; i < widget.targetOpColConfig.length; i++) {
          String colName = widget.targetOpColConfig[i]['fieldKey']!;
          String value = opItem[colName] ?? '';
          if (value.isNotEmpty) {
            allEmpty = false;
            break;
          }
        }
        if (widget.targetOpColConfig.isNotEmpty && allEmpty) {
          opItem['checked'] = false;
          opItem['status'] = 'not selected';
        }
      }
    }

    //remove all the cols that are not mapped
    _listConfigFull.removeWhere((element) => _meterColsMapper
        .where((e) =>
            e['colName'] == element['fieldKey'] &&
            (e['colHeader'] != null && e['colHeader']!.isNotEmpty))
        .isEmpty);

    //if _listConfigFull has no targetOpColConfig fieldKey column,
    //insert it at the end
    for (var element in widget.targetOpColConfig) {
      var colName = element['fieldKey'];
      if (_listConfigFull
          .where((element) => element['fieldKey'] == colName)
          .isEmpty) {
        _listConfigFull.add(element);
      } else {
        //set validator
        for (var configItem in _listConfigFull) {
          if (configItem['fieldKey'] == colName) {
            configItem['color'] = element['color'];
            configItem['validator'] = element['validator'];
            break;
          }
        }
      }
    }

    widget.onImport(_listConfigFull, _opList, _totalCsvErrorCount);

    return msg;
  }

  void _getColConfig() {
    _meterColsMapper.clear();
    _listConfigBase.clear();
    _listConfigFull.clear();

    List<String> meterCols = [];

    _listConfigBase.clear();
    if (widget.listItemType == ListItemType.User) {
      // for (var element in userColConfig) {
      //   //skip enabled from csv, use popluate
      //   if (element['fieldKey'] == 'enabled') {
      //     continue;
      //   }
      //   _listConfigBase.add({
      //     'fieldKey': element['fieldKey'],
      //     'title': element['title'],
      //     'width': element['width'],
      //     'allowDuplicates': element['allowDuplicates'] ?? true,
      //     'validator': element['validator'],
      //     'disableIf': element['disableIf'],
      //   });
      // }

      // for (var element in _listConfigBase) {
      //   meterCols.add(element['fieldKey']!);
      // }

      // for (String colName in meterCols) {
      //   _meterColsMapper.add({
      //     'colName': colName,
      //     'colHeader': '',
      //   });
      // }
    } else if (widget.listItemType == ListItemType.Concentrator) {
      _listConfigBase.add({
        'title': 'Conc ID',
        'fieldKey': 'concentrator_id',
        'width': 100,
        'allowDuplicates': false,
        'validator': null,
        'disableIf': null,
      });
      _listConfigBase.add({
        'title': 'Tariff',
        'fieldKey': 'tariff_price',
        'width': 100,
        'allowDuplicates': true,
        'validator': null,
        'disableIf': null,
      });

      for (var element in _listConfigBase) {
        meterCols.add(element['fieldKey']!);
      }

      for (String colName in meterCols) {
        _meterColsMapper.add({
          'colName': colName,
          'colHeader': '',
        });
      }
    } else {
      // if (activePortalProjectScope == ProjectScope.EMS_CW_NUS) {
      //   // _listConfig.addAll(meterColsIwowConfig);
      //   //use deep copy
      //   for (var element in meterColsConfigIwow) {
      //     _listConfigBase.add({
      //       'fieldKey': element['fieldKey'],
      //       'title': element['title'],
      //       'width': element['width'],
      //       'allowDuplicates': element['allowDuplicates'] ?? true,
      //       'validator': element['validator'],
      //       'dbStrMapper': element['dbStrMapper'],
      //     });
      //   }

      //   for (var element in _listConfigBase) {
      //     meterCols.add(element['fieldKey']!);
      //   }
      //   for (String colName in meterCols) {
      //     _meterColsMapper.add({
      //       'colName': colName,
      //       'colHeader': '',
      //     });
      //   }
      // } else if (activePortalProjectScope == ProjectScope.EMS_SMRT) {
      //   // _listConfig.addAll(meterColsSmrtConfig);
      //   for (var element in meterColsConfigSmrt) {
      //     _listConfigBase.add({
      //       'fieldKey': element['fieldKey'],
      //       'title': element['title'],
      //       'width': element['width'],
      //       'allowDuplicates': element['allowDuplicates'] ?? true,
      //       'validator': element['validator'],
      //     });
      //   }

      //   for (var element in _listConfigBase) {
      //     meterCols.add(element['fieldKey']!);
      //   }
      //   for (String colName in meterCols) {
      //     _meterColsMapper.add({
      //       'colName': colName,
      //       'colHeader': '',
      //     });
      //   }
      // } else {
      //   // _listConfig.addAll(meterColsMmsConfig);
      //   for (var element in meterColsConfigMms) {
      //     if (!widget.includeAddressCat && element['fieldCat'] == 'address') {
      //       continue;
      //     }
      //     //skip concentrator_id from csv, use popluate
      //     if (element['fieldKey'] == 'concentrator_id' ||
      //         element['fieldKey'] == 'site_tag') {
      //       continue;
      //     }

      //     _listConfigBase.add({
      //       'fieldKey': element['fieldKey'],
      //       'title': element['title'],
      //       'width': element['width'],
      //       'allowDuplicates': element['allowDuplicates'] ?? true,
      //       'validator': element['validator'],
      //       'fieldCat': element['fieldCat'],
      //     });
      //   }

      //   for (var element in _listConfigBase) {
      //     meterCols.add(element['fieldKey']!);
      //   }

      //   for (String colName in meterCols) {
      //     _meterColsMapper.add({
      //       'colName': colName,
      //       'colHeader': '',
      //     });
      //   }
      // }
    }
  }

  @override
  void initState() {
    super.initState();

    _getColConfig();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.opKey != null && _opKey != widget.opKey) {
      _opKey = widget.opKey;
      _opList.clear();
      _missingColName = '';
      _checkHeaderMapperMessage = '';
      _submittedListHeaders.clear();

      _getColConfig();
      _listConfigFull.clear();
      _listConfigFull.addAll(_listConfigBase);
      _listConfigFull.addAll(widget.targetOpColConfig);
    }

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      getTitleRow(),
      if (_submittedListHeaders.isNotEmpty) verticalSpaceSmall,
      getListImporter(),
      if (_submittedListHeaders.isNotEmpty) verticalSpaceSmall,
      getImportButton(),
    ]);
  }

  Widget getTitleRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Upload Op List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        horizontalSpaceTiny,
        WgtSubmitTable(
          getList: (opList) {
            _getMeterList(opList);
          },
          fileExtensions: ['csv'],
        ),
      ],
    );
  }

  Widget getListImporter() {
    return _submittedListHeaders.isEmpty
        ? Container()
        : Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).hintColor),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            child: Column(
              children: [
                const Text(
                  'Set Column Headers',
                  style: TextStyle(),
                ),
                verticalSpaceSmall,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: getColumnSetter(),
                ),
              ],
            ),
          );
  }

  List<Widget> getColumnSetter() {
    List<Widget> colSetters = [];
    for (Map<String, String> colMapper in _meterColsMapper) {
      String colName = colMapper['colName']!;
      bool highlightUpdateCol = widget.isImportTargetVal &&
          widget.targetOpColConfig.isNotEmpty &&
          widget.targetOpColConfig
              .where((element) => element['fieldKey'] == colName)
              .isNotEmpty;
      colSetters.add(
        Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Column(
            children: [
              colName == _identityColName
                  ? const Text(
                      'identity column',
                      style: TextStyle(color: Colors.brown),
                    )
                  : highlightUpdateCol
                      ? const Text('update column',
                          style: TextStyle(color: Colors.blue))
                      : const Text(''),
              verticalSpaceTiny,
              Container(
                width: 145,
                decoration: BoxDecoration(
                  border: colName == _identityColName
                      ? Border.all(color: Colors.brown, width: 2)
                      : highlightUpdateCol
                          ? Border.all(color: Colors.blue, width: 2)
                          : Border.all(
                              color:
                                  Theme.of(context).hintColor.withOpacity(0.7),
                              width: 0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: [
                    Tooltip(
                      message: 'Internal column name',
                      waitDuration: const Duration(milliseconds: 500),
                      child: Text(
                        colName,
                        style: TextStyle(
                          fontSize: 13,
                          color: colName == _missingColName ? Colors.red : null,
                          // fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    //dropdown of the imported headers
                    if (_submittedListHeaders.isNotEmpty)
                      Tooltip(
                        message: 'Matched csv column header',
                        waitDuration: const Duration(milliseconds: 500),
                        child: DropdownButton<String>(
                          value: colMapper['colHeader'] == null ||
                                  colMapper['colHeader']!.isEmpty
                              ? null
                              : colMapper['colHeader'],
                          onChanged: (String? newValue) {
                            setState(() {
                              colMapper['colHeader'] = newValue!;
                              // if newValue already exists in other colMapper, remove it
                              for (Map<String, String> otherColMapper
                                  in _meterColsMapper) {
                                if (otherColMapper['colHeader'] == newValue &&
                                    otherColMapper != colMapper) {
                                  otherColMapper['colHeader'] = '';
                                }
                              }
                              if (_checkHeaderMapperMessage.isNotEmpty) {
                                _checkHeaderMapperMessage = _checkMapper();
                                if (kDebugMode) {
                                  print(_checkHeaderMapperMessage);
                                }

                                // if (_checkHeaderMapperMessage.isEmpty) {
                                //   _rawList.clear();
                                //   _rawList.addAll(entityList);
                                // }
                              }
                            });
                          },
                          items: _submittedListHeaders
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: 13,
                                  // fontWeight: FontWeight.w500,
                                  color: //if the value is already used by other colMapper, grey it out
                                      _meterColsMapper
                                              .where((element) =>
                                                  element['colHeader'] == value)
                                              .isNotEmpty
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return colSetters;
  }

  Widget getImportButton() {
    return _submittedListHeaders.isNotEmpty && _checkHeaderMapperMessage.isEmpty
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _import();
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary),
                ),
                child: const Text(
                  'Import',
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          )
        : _checkHeaderMapperMessage.isNotEmpty
            ? Text(
                _checkHeaderMapperMessage,
                style: const TextStyle(color: Colors.red),
              )
            : Container();
  }
}
