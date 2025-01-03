class MdlPagPageConfigItem {
  String name;
  String label;
  String type;
  int? rowIndex;
  int? colIndex;
  int? gridTopLeftY;
  int? gridTopLeftX;
  int? gridWidth;
  int? gridHeight;
  String? decorationStr;

  MdlPagPageConfigItem({
    required this.name,
    required this.label,
    required this.type,
    this.rowIndex,
    this.colIndex,
    this.gridTopLeftY,
    this.gridTopLeftX,
    this.gridWidth,
    this.gridHeight,
    this.decorationStr,
  });

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

    dynamic gridTop = json['grid_top'];
    if (gridTop is String) {
      gridTop = int.tryParse(gridTop);
    }
    dynamic gridLeft = json['grid_left'];
    if (gridLeft is String) {
      gridLeft = int.tryParse(gridLeft);
    }
    dynamic gridW = json['grid_width'];
    if (gridW is String) {
      gridW = int.tryParse(gridW);
    }
    dynamic gridH = json['grid_height'];
    if (gridH is String) {
      gridH = int.tryParse(gridH);
    }

    return MdlPagPageConfigItem(
      name: json['name'],
      label: json['label'],
      type: json['type'],
      rowIndex: json['row_index'],
      colIndex: json['col_index'],
      gridTopLeftY: gridTop,
      gridTopLeftX: gridLeft,
      gridWidth: gridW,
      gridHeight: gridH,
      decorationStr: json['decoration_str'],
    );
  }
}
