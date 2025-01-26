import 'package:buff_helper/pag_helper/def/def_panel.dart';
import 'package:flutter/foundation.dart';

class MdlPagPageConfigItem {
  String name;
  String label;
  PagPanelType type;
  int? rowIndex;
  int? colIndex;
  // int? gridTopLeftY;
  // int? gridTopLeftX;
  // int? gridWidth;
  // int? gridHeight;
  String? decorationStr;
  List<Map<String, dynamic>> layoutList;
  String selectedLayoutKey = '';

  MdlPagPageConfigItem({
    required this.name,
    required this.label,
    required this.type,
    this.rowIndex,
    this.colIndex,
    // this.gridTopLeftY,
    // this.gridTopLeftX,
    // this.gridWidth,
    // this.gridHeight,
    this.decorationStr,
    this.layoutList = const [],
  });

  Map<String, dynamic> getSelectedLayout() {
    if (selectedLayoutKey.isEmpty) {
      return layoutList.first;
    }
    for (Map<String, dynamic> layout in layoutList) {
      if (layout['layout_key'] == selectedLayoutKey) {
        return layout;
      }
    }
    // throw Exception('Invalid selectedLayoutKey: $selectedLayoutKey');
    // if (kDebugMode) {
    //   print('Invalid selectedLayoutKey: $selectedLayoutKey');
    // }
    return layoutList.first;
  }

  factory MdlPagPageConfigItem.fromJson(Map<String, dynamic> json) {
    if (json['name'] == null) {
      throw Exception('Invalid name');
    }
    if (json['label'] == null) {
      throw Exception('Invalid label');
    }
    if (json['type'] == null) {
      throw Exception('Invalid type');
    }

    PagPanelType type = PagPanelType.none;
    try {
      type = PagPanelType.byLabel(json['type']);
    } catch (e) {
      throw Exception(
          'MdlPagPageConfigItem.fromJson: Invalid type: ${json['type']}');
    }

    List<Map<String, dynamic>> layoutList = [];

    if (type != PagPanelType.topStat) {
      if (json['layout_list'] == null) {
        throw Exception('Invalid layout_list');
      }
    }
    for (Map<String, dynamic> layoutMap in json['layout_list'] ?? []) {
      // Map<String, dynamic> layout = {};

      String? layoutKey = layoutMap['layout_key'];
      if (layoutKey == null) {
        throw Exception('Invalid layout_key');
      }

      dynamic gridTop = layoutMap['grid_top'];
      if (gridTop is String) {
        gridTop = int.tryParse(gridTop);
      }
      dynamic gridLeft = layoutMap['grid_left'];
      if (gridLeft is String) {
        gridLeft = int.tryParse(gridLeft);
      }
      dynamic gridW = layoutMap['grid_width'];
      if (gridW is String) {
        gridW = int.tryParse(gridW);
      }
      dynamic gridH = layoutMap['grid_height'];
      if (gridH is String) {
        gridH = int.tryParse(gridH);
      }

      layoutList.add({
        'layout_key': layoutKey,
        'grid_top': gridTop,
        'grid_left': gridLeft,
        'grid_width': gridW,
        'grid_height': gridH,
      });
    }

    if (type != PagPanelType.topStat) {
      assert(layoutList.isNotEmpty);
    }
    if (type == PagPanelType.topStat) {
      layoutList.add({});
    }

    // dynamic gridTop = json['grid_top'];
    // if (gridTop is String) {
    //   gridTop = int.tryParse(gridTop);
    // }
    // dynamic gridLeft = json['grid_left'];
    // if (gridLeft is String) {
    //   gridLeft = int.tryParse(gridLeft);
    // }
    // dynamic gridW = json['grid_width'];
    // if (gridW is String) {
    //   gridW = int.tryParse(gridW);
    // }
    // dynamic gridH = json['grid_height'];
    // if (gridH is String) {
    //   gridH = int.tryParse(gridH);
    // }

    return MdlPagPageConfigItem(
      name: json['name'],
      label: json['label'],
      type: type,
      rowIndex: json['row_index'],
      colIndex: json['col_index'],
      // gridTopLeftY: gridTop,
      // gridTopLeftX: gridLeft,
      // gridWidth: gridW,
      // gridHeight: gridH,
      layoutList: layoutList,
      decorationStr: json['decoration_str'],
    );
  }
}
