import 'package:buff_helper/pag_helper/def_helper/def_panel.dart';

import 'mdl_page_config_item.dart';

const int defaultPageGridWidthGrid = 128;
const int defaultPageGridWidthList = 85;

const int defaultTopStatCount = 6;
const int defaultMainPanelRowCount = 3;

const int defaultTopStatGridWidth = 21;
const int defaultTopStatGridHeight = 11;

const int defaultMainPanelGridWidth = 63;
const int defaultMainPanelGridHeight = 28;

// const int geoPaneGridWidth = 63;
// const int geoPaneGridHeight = 34;

// const int emsRankingGridWidth = 63;
// const int emsRankingGridHeight = 34;

class MdlPagPageConfig {
  String name;

  // int pageGridWidth = defaultPageGridWidth;
  int topStatCount = defaultTopStatCount;
  int mainPanelRowCount = defaultMainPanelRowCount;

  List<MdlPagPageConfigItem>? panelList;

  MdlPagPageConfig({
    required this.name,
    // this.pageGridWidth = defaultPageGridWidth,
    this.topStatCount = defaultTopStatCount,
    this.mainPanelRowCount = defaultMainPanelRowCount,
    this.panelList,
  });

  void updateSelectedPageLayout(String layoutKey) {
    for (MdlPagPageConfigItem panelConfig in panelList!) {
      panelConfig.selectedLayoutKey = layoutKey;
    }
  }

  factory MdlPagPageConfig.fromJson(Map<String, dynamic> json) {
    if (json['name'] == null) {
      throw Exception('Invalid name');
    }

    String pageName = json['name'];

    // dynamic pageGridWidth = json['page_grid_width'] ?? defaultPageGridWidth;
    // if (pageGridWidth is String) {
    //   pageGridWidth = int.tryParse(pageGridWidth);
    // }
    dynamic topStatCount = json['top_stat_count'] ?? defaultTopStatCount;
    if (topStatCount is String) {
      topStatCount = int.tryParse(topStatCount);
    }
    dynamic mainPanelColCount =
        json['main_panel_col_count'] ?? defaultMainPanelRowCount;
    if (mainPanelColCount is String) {
      mainPanelColCount = int.tryParse(mainPanelColCount);
    }

    List<MdlPagPageConfigItem> panelConfigList = [];

    // plotting topleft x and y for each panel
    if (json['panel_config_list'] != null) {
      int indexTopStat = 0;
      int indexMainPanel = 0;
      for (Map<String, dynamic> panelConfigMap in json['panel_config_list']) {
        MdlPagPageConfigItem panelConfig =
            MdlPagPageConfigItem.fromJson(panelConfigMap);

        // assign row and column index for top_stat type
        if (panelConfig.type == PagPanelType.topStat) {
          panelConfig.rowIndex = 0;
          panelConfig.colIndex = indexTopStat;
          indexTopStat++;
        } else {
          panelConfig.rowIndex = 1;
          panelConfig.colIndex = indexMainPanel;
          indexMainPanel++;
        }
        panelConfigList.add(panelConfig);
      }

      // calculate grid position for top_stat
      int totalTopStatWidth = 0;
      int topStatGridHeight = 0;
      for (MdlPagPageConfigItem panelConfig in panelConfigList) {
        if (panelConfig.type != PagPanelType.topStat) {
          continue;
        }

        for (Map<String, dynamic> layout in panelConfig.layoutList) {
          dynamic pageGridWidth =
              json['page_grid_width'] ?? defaultPageGridWidthGrid;
          if (layout['layout_key'] == 'list') {
            pageGridWidth = json['page_grid_width'] ?? defaultPageGridWidthList;
          }
          if (pageGridWidth is String) {
            pageGridWidth = int.tryParse(pageGridWidth);
          }

          layout['grid_width'] =
              layout['grid_width'] ?? defaultTopStatGridWidth;
          layout['grid_height'] =
              layout['grid_height'] ?? defaultTopStatGridHeight;

          layout['row_index'] = panelConfig.rowIndex;
          layout['col_index'] = panelConfig.colIndex;
          assert(layout['col_index'] != null);
          assert(layout['row_index'] != null);

          layout['grid_top'] = 0;
          layout['grid_left'] = (layout['col_index'] *
                  (layout['grid_width'] ?? defaultTopStatGridWidth))
              .toInt();

          topStatGridHeight = layout['grid_height'];
          totalTopStatWidth += layout['grid_width'] as int;
        }
        // panelConfig.gridWidth = panelConfig.gridWidth ?? defaultTopStatGridWidth;
        // panelConfig.gridHeight = panelConfig.gridHeight ?? defaultTopStatGridHeight;

        // assert(panelConfig.colIndex != null);
        // assert(panelConfig.rowIndex != null);

        // panelConfig.gridTopLeftY = 0;
        // panelConfig.gridTopLeftX = (panelConfig.colIndex! * (panelConfig.gridWidth ?? defaultTopStatGridWidth)).toInt();

        // topStatGridHeight = panelConfig.gridHeight!;
        // totalTopStatWidth += panelConfig.gridWidth!;
      }

      // if total top stat width exceed page grid width, update page grid width
      // if (totalTopStatWidth > pageGridWidth) {
      //   pageGridWidth = totalTopStatWidth;
      // }

      // calculate grid position for main_panel
      // int currentRowIndex = 0;
      // if (indexTopStat > 0) {
      //   currentRowIndex = 1;
      // }
      // int currentColIndex = 0;
      // int currentMainGridWidth = 0;
      // int currentMainGridTopLeftY = 0;
      // if (indexTopStat > 0) {
      //   currentMainGridTopLeftY = topStatGridHeight;
      // }

      // get list of layout keys for main panel
      List<String> layoutKeys = [];
      for (MdlPagPageConfigItem panelConfig in panelConfigList) {
        if (panelConfig.type == PagPanelType.topStat) {
          continue;
        }

        for (Map<String, dynamic> layout in panelConfig.layoutList) {
          if (!layoutKeys.contains(layout['layout_key'])) {
            layoutKeys.add(layout['layout_key']);
          }
        }
      }

      for (String layoutKey in layoutKeys) {
        int currentRowIndex = 0;
        if (indexTopStat > 0) {
          currentRowIndex = 1;
        }
        int currentColIndex = 0;
        int currentMainGridWidth = 0;
        int currentMainGridTopLeftY = 0;
        if (indexTopStat > 0) {
          currentMainGridTopLeftY = topStatGridHeight;
        }

        for (MdlPagPageConfigItem panelConfig in panelConfigList) {
          if (panelConfig.type == PagPanelType.topStat) {
            continue;
          }

          // find layout with layout key
          Map<String, dynamic> layout = {};
          for (Map<String, dynamic> layoutMap in panelConfig.layoutList) {
            if (layoutMap['layout_key'] == layoutKey) {
              layout = layoutMap;
              break;
            }
          }

          dynamic pageGridWidth =
              json['page_grid_width'] ?? defaultPageGridWidthGrid;
          if (layoutKey == 'list') {
            pageGridWidth = json['page_grid_width'] ?? defaultPageGridWidthList;
          }
          if (pageGridWidth is String) {
            pageGridWidth = int.tryParse(pageGridWidth);
          }

          // if total top stat width exceed page grid width, update page grid width
          if (totalTopStatWidth > pageGridWidth) {
            pageGridWidth = totalTopStatWidth;
          }

          layout['grid_width'] =
              layout['grid_width'] ?? defaultMainPanelGridWidth;
          layout['grid_height'] =
              layout['grid_height'] ?? defaultMainPanelGridHeight;

          layout['row_index'] = panelConfig.rowIndex;
          layout['col_index'] = panelConfig.colIndex;
          assert(layout['col_index'] != null);
          assert(layout['row_index'] != null);

          layout['grid_top'] = currentMainGridTopLeftY;
          layout['grid_left'] = (layout['col_index'] *
                  (layout['grid_width'] ?? defaultMainPanelGridWidth))
              .toInt();

          // move row index and column index to next row if exceed page grid width
          currentMainGridWidth += layout['grid_width'] as int;
          bool widthExceed = currentMainGridWidth > pageGridWidth;
          bool mainColExceed = currentColIndex > mainPanelColCount;
          if (widthExceed || mainColExceed) {
            currentRowIndex++;
            currentColIndex = 0;
            currentMainGridWidth = layout['grid_width'];

            layout['row_index'] = currentRowIndex;
            layout['col_index'] = currentColIndex;

            currentMainGridTopLeftY += layout['grid_height'] as int;
          }

          layout['grid_top'] = currentMainGridTopLeftY;
          layout['grid_left'] = currentColIndex *
              (layout['grid_width'] ?? defaultMainPanelGridWidth);

          currentColIndex++;
        }

        // panelConfig.gridWidth = panelConfig.gridWidth ?? defaultMainPanelGridWidth;
        // panelConfig.gridHeight = panelConfig.gridHeight ?? defaultMainPanelGridHeight;

        // assert(panelConfig.gridWidth != null);
        // assert(panelConfig.gridHeight != null);

        // move row index and column index to next row if exceed page grid width
        // currentMainGridWidth += panelConfig.gridWidth!;
        // bool widthExceed = currentMainGridWidth > pageGridWidth;
        // bool mainColExceed = currentColIndex > mainPanelColCount;
        // if (widthExceed || mainColExceed) {
        //   currentRowIndex++;
        //   currentColIndex = 0;
        //   currentMainGridWidth = 0;

        //   panelConfig.rowIndex = currentRowIndex;
        //   panelConfig.colIndex = currentColIndex;

        //   currentMainGridTopLeftY += panelConfig.gridHeight!;
        // }

        // panelConfig.gridTopLeftY = currentMainGridTopLeftY;
        // panelConfig.gridTopLeftX = currentColIndex * panelConfig.gridWidth!;

        // currentColIndex++;
      }
    }

    return MdlPagPageConfig(
      name: pageName,
      panelList: panelConfigList,
    );
  }
}
