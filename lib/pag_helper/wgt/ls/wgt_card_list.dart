import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../util/string_util.dart';
import '../../../xt_ui/style/xt_styles.dart';
import '../../../xt_ui/wdgt/list/get_pagenation_bar.dart';
import '../../../xt_ui/xt_helpers.dart';
import '../../def_helper/dh_pag_acl.dart';
import '../../def_helper/dh_device.dart';
import '../../def_helper/dh_pag_bill.dart';
import '../../def_helper/dh_pag_finance.dart';
import '../../def_helper/dh_pag_tenant.dart';
import '../../def_helper/pag_item_helper.dart';
import '../../model/list/mdl_list_col_controller.dart';
import '../../model/list/mdl_list_controller.dart';
import '../../model/mdl_pag_app_config.dart';
import '../../model/mdl_pag_user.dart';

class WgtCardList extends StatefulWidget {
  const WgtCardList({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.listPrefix,
    required this.listController,
    required this.itemList,
    this.itemType,
    this.width,
    this.cardHeight,
    this.maxRowsPerPage,
    this.totalCount = 0,
    this.currentPage,
    this.narrowPaginationBar = true,
    this.onPreviousPage,
    this.onNextPage,
    this.onClickPage,
    this.onSort,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final String listPrefix;
  final MdlPagListController listController;
  final List<Map<String, dynamic>> itemList;
  final dynamic itemType;
  final double? width;
  final double? cardHeight;
  final int? maxRowsPerPage;
  final int totalCount;
  final int? currentPage;
  final bool narrowPaginationBar;
  final Function? onPreviousPage;
  final Function? onNextPage;
  final Function? onClickPage;
  final Function? onSort;

  @override
  State<WgtCardList> createState() => _WgtCardListState();
}

class _WgtCardListState extends State<WgtCardList> {
  late final double width;
  late final double cardHeight;
  late final double listHeight;
  late final bool showPagination;

  UniqueKey _listKey = UniqueKey();

  late final TextStyle _listItemStyle = TextStyle(
    fontSize: 13.5,
    color: Theme.of(context).hintColor,
  );

  List<List<dynamic>> _getCsvList() {
    return [];
  }

  @override
  void initState() {
    super.initState();
    width = widget.width ?? 360;
    cardHeight = widget.cardHeight ?? 150;
    showPagination = widget.totalCount > 0;
    listHeight =
        widget.itemList.length * cardHeight + (showPagination ? 55 : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: listHeight,
      width: width,
      decoration: panelBoxDecor(Theme.of(context).hintColor),
      child: ListView.separated(
        key: _listKey,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.itemList.length + (showPagination ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
          } else if (index == widget.itemList.length) {
            return showPagination
                ? Column(
                    children: [
                      Divider(
                          color: Theme.of(context).hintColor.withAlpha(130),
                          height: 8,
                          indent: 5,
                          endIndent: 8),
                      getPagenationBar(
                        context,
                        widget.itemList.length,
                        widget.maxRowsPerPage, //_rows.length,
                        widget.totalCount,
                        widget.currentPage,
                        widget.onPreviousPage,
                        widget.onNextPage,
                        widget.onClickPage,
                        narrow: widget.narrowPaginationBar,
                        rows: widget.itemList,
                        getCsv: _getCsvList,
                        listPrefix: widget.listPrefix,
                      ),
                    ],
                  )
                : Container();
          }

          final item = widget.itemList[index];
          return _buildListItem(index, item, {}, widget.itemList);
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            height: 5,
            indent: 5,
            endIndent: 5,
            color: Colors.transparent,
            // color: Colors.grey,
          );
        },
      ),
    );
  }

  Widget _buildListItem(int index, Map<String, dynamic> row,
      Map<String, dynamic> modifiedRow, List<Map<String, dynamic>>? fullList) {
    List<MdlListColController> colontrollersRow1 = [];
    List<MdlListColController> colontrollersRow2 = [];
    List<MdlListColController> colontrollersRow3 = [];
    for (var ctrlItem in widget.listController.listColControllerList) {
      if (!ctrlItem.showColumn) {
        continue;
      }
      if (!ctrlItem.showOnCard) {
        continue;
      }
      if (ctrlItem.rowOnCard == 1) {
        colontrollersRow1.add(ctrlItem);
      } else if (ctrlItem.rowOnCard == 2) {
        colontrollersRow2.add(ctrlItem);
      } else if (ctrlItem.rowOnCard == 3) {
        colontrollersRow3.add(ctrlItem);
      }
    }
    // sort by rowOrder
    colontrollersRow1.sort((a, b) => a.rowOrder.compareTo(b.rowOrder));
    colontrollersRow2.sort((a, b) => a.rowOrder.compareTo(b.rowOrder));
    colontrollersRow3.sort((a, b) => a.rowOrder.compareTo(b.rowOrder));

    List<List<MdlListColController>> rowControllerList = [];
    rowControllerList.add(colontrollersRow1);
    rowControllerList.add(colontrollersRow2);
    rowControllerList.add(colontrollersRow3);

    List<Widget> listItemRow1 = [];
    List<Widget> listItemRow2 = [];
    List<Widget> listItemRow3 = [];

    for (List<MdlListColController> rowControllers in rowControllerList) {
      for (var ctrlItem in rowControllers) {
        if (!ctrlItem.showColumn) {
          continue;
        }
        if (!ctrlItem.showOnCard) {
          continue;
        }

        bool unique = ctrlItem.isUnique;
        List<String> listValues = [];
        if (unique) {
          for (Map<String, dynamic> row in fullList!) {
            listValues.add(row[ctrlItem.colKey] ?? '');
          }
        }

        //check width
        double width = ctrlItem.colWidth;

        String originalFullText = '';
        if (row[ctrlItem.colKey] != null) {
          originalFullText = row[ctrlItem.colKey].toString();
        }

        if (ctrlItem.useComma || ctrlItem.decimal != null) {
          originalFullText = getCommaNumberStr(
              double.tryParse(originalFullText),
              decimal: ctrlItem.decimal ?? 2);
          originalFullText += ' ';
        }

        if (ctrlItem.filterGroupType == PagFilterGroupType.datetime) {
          if (ctrlItem.showTimestampAsDate && row[ctrlItem.colKey] != null) {
            DateTime? dateTime = DateTime.tryParse(row[ctrlItem.colKey]);
            if (dateTime != null) {
              originalFullText =
                  '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
            }
          }
        }

        bool showTag = true;
        String tagText = '';
        String? tagTooltip;
        Color? tagColor;

        if (ctrlItem.getTag != null) {
          Map<String, dynamic> tagInfo = ctrlItem.getTag!(row, ctrlItem.colKey);
          if (tagInfo.isNotEmpty) {
            showTag = true;
            tagText = tagInfo['tag'];
            tagColor = tagInfo['color'];
            tagTooltip = tagInfo['tooltip'];
          }
        }

        int onRowNumber = ctrlItem.rowOnCard;

        List<Widget> listItem = [];
        if (onRowNumber == 1) {
          listItem = listItemRow1;
        } else if (onRowNumber == 2) {
          listItem = listItemRow2;
        } else if (onRowNumber == 3) {
          listItem = listItemRow3;
        }

        TextStyle listItemStyle = _listItemStyle;
        if (onRowNumber == 1) {
          listItemStyle = _listItemStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface);
        }

        listItem.add(
          ctrlItem.colWidgetType == PagColWidgetType.TEXT
              ? Tooltip(
                  message: originalFullText,
                  waitDuration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: ctrlItem.align == 'right'
                        ? const EdgeInsets.only(right: 0.0)
                        : const EdgeInsets.only(left: 0.0),
                    child: getCellText(
                      colTitle: ctrlItem.colTitle,
                      originalFullText: originalFullText,
                      width: width,
                      style: listItemStyle,
                      clickCopy: true,
                      alignment: ctrlItem.align == 'right'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                    ),
                  ),
                )
              : ctrlItem.colWidgetType == PagColWidgetType.TAG && showTag
                  ? SizedBox(
                      width: width,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          getTag2(
                            row: row,
                            configItem: ctrlItem.toJson(),
                            width: width,
                            tagColor: tagColor,
                            tagText: tagText.isNotEmpty
                                ? tagText
                                : row[ctrlItem.colKey] ?? '',
                            tagTooltip: tagTooltip,
                          ),
                        ],
                      ),
                    )
                  : ctrlItem.colWidgetType == PagColWidgetType.TAG_LIST
                      ? getTagList(
                          row: row,
                          configItem: ctrlItem.toJson(),
                          width: width,
                          tagColor: tagColor,
                          tagText: row[ctrlItem.colKey] ?? '',
                          tagTooltip: tagTooltip,
                        )
                      : Container(
                          width: width /*+ 10*/,
                          alignment: Alignment.centerLeft,
                          child:
                              ctrlItem.colWidgetType == PagColWidgetType.CUSTOM
                                  ? Container(
                                      decoration: (row['is_selected'] ?? false)
                                          ? BoxDecoration(
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .highlightColor,
                                                // Theme.of(context).colorScheme.primary,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            )
                                          : null,
                                      child: ctrlItem.getCustomWidget
                                          ?.call(row, widget.itemList))
                                  : Container(),
                        ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withAlpha(25),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: listItemRow1,
          ),
          if (listItemRow2.isNotEmpty)
            Column(
              children: [
                Divider(
                    color: Theme.of(context).hintColor.withAlpha(130),
                    height: 13),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: listItemRow2,
                ),
              ],
            ),
          if (listItemRow3.isNotEmpty)
            Column(
              children: [
                Divider(
                    color: Theme.of(context).hintColor.withAlpha(130),
                    height: 13),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: listItemRow3,
                ),
              ],
            ),
          verticalSpaceSmall,
        ],
      ),
    );
  }

  Widget getCellText({
    required String colTitle,
    required String originalFullText,
    required double width,
    required TextStyle style,
    Alignment alignment = Alignment.centerLeft,
    bool clickCopy = false,
  }) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignment,
        child: Column(
          crossAxisAlignment: alignment == Alignment.centerRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(colTitle,
                style: style.copyWith(
                    fontSize: 13.5, color: style.color!.withAlpha(150))),
            InkWell(
              onTap: !clickCopy
                  ? null
                  : () {
                      Clipboard.setData(
                        ClipboardData(text: originalFullText),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
              child: Text(
                originalFullText,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getTagList({
    required Map<String, dynamic> row,
    required Map<String, dynamic> configItem,
    required String tagText,
    Color? tagColor,
    String? tagTooltip,
    required double width,
  }) {
    List<String> tagList = tagText.split(',');
    List<Widget> tagWidgets = [];
    for (String tag in tagList) {
      tagWidgets.add(
        getTag2(
          row: row,
          configItem: configItem,
          tagText: tag,
          tagColor: tagColor,
          tagTooltip: tagTooltip,
          width: width,
        ),
      );
    }
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tagWidgets,
      ),
    );
  }

  Widget getTag2({
    required Map<String, dynamic> row,
    required Map<String, dynamic> configItem,
    required String tagText,
    Color? tagColor,
    String? tagTooltip,
    required double width,
  }) {
    String tagLabel = '';
    Color tagColor = Colors.grey;
    if (configItem['col_key'] == 'portal_type_str') {
      PagPortalType portalType = PagPortalType.byValue(tagText);
      tagLabel = portalType.tag;
      tagColor = portalType.color;
    } else if (configItem['col_key'] == 'soa_type') {
      PaymentSoaType soaType = PaymentSoaType.byValue(tagText);
      tagLabel = soaType.tag;
      tagColor = soaType.color.withAlpha(130);
    } else if (configItem['col_key'] == 'lc_status') {
      if (widget.itemType is PagDeviceCat) {
        PagDeviceLsStatus deviceLsStatus = PagDeviceLsStatus.byTag(tagText);
        tagLabel = deviceLsStatus.tag;
        tagColor = deviceLsStatus.color.withAlpha(130);
      } else if (widget.itemType is PagFinanceType) {
        PagPaymentLcStatus financeLcStatus =
            PagPaymentLcStatus.byValue(tagText);
        tagLabel = financeLcStatus.tag;
        tagColor = financeLcStatus.color.withAlpha(130);
      } else if (widget.itemType is PagItemKind) {
        if (widget.itemType == PagItemKind.bill) {
          PagBillingLcStatus billingLcStatus =
              PagBillingLcStatus.byValue(tagText);
          tagLabel = billingLcStatus.tag ?? '';
          tagColor = billingLcStatus.color?.withAlpha(130) ??
              Colors.grey.withAlpha(130);
        }
        if (widget.itemType == PagItemKind.tenant) {
          PagTenantLcStatus tenantLcStatus = PagTenantLcStatus.byValue(tagText);
          tagLabel = tenantLcStatus.tag;
          tagColor = tenantLcStatus.color.withAlpha(130);
        }
      }
    } else if (widget.itemType == PagItemKind.bill) {
      if (configItem['col_key'] == 'payment_status') {
        PagBillPaymentStatus billPaymentStatus =
            PagBillPaymentStatus.byValue(tagText);
        tagLabel = billPaymentStatus.tag ?? '';
        tagColor = billPaymentStatus.color?.withAlpha(130) ??
            Colors.grey.withAlpha(130);
      } else if (configItem['col_key'] == 'due_status') {
        PagBillDueStatus billDueStatus = PagBillDueStatus.byValue(tagText);
        tagLabel = billDueStatus.tag ?? '';
        tagColor =
            billDueStatus.color?.withAlpha(130) ?? Colors.grey.withAlpha(130);
      } else if (configItem['col_key'] == 'gen_type') {
        if (widget.itemType == PagItemKind.bill) {
          PagBillGenType billingGenType = PagBillGenType.byValue(tagText);
          tagLabel = billingGenType.tag ?? '';
          tagColor = billingGenType.color?.withAlpha(130) ??
              Colors.grey.withAlpha(130);
        }
      }
    } else if (configItem['col_key'] == 'entry_type') {
      PagSoaEntryType entryType = PagSoaEntryType.byValue(tagText);
      tagLabel = entryType.tag;
      tagColor = entryType.color;
    } else if (configItem['col_key'] == 'comm_type') {
      PagMeterCommType commType = PagMeterCommType.byValue(tagText);
      tagLabel = commType.tag;
      tagColor = commType.color.withAlpha(130);
    } else if (configItem['col_key'] == 'payment_method') {
      PagPaymentMethod paymentMethod = PagPaymentMethod.byValue(tagText);
      tagLabel = paymentMethod.tag;
      tagColor = paymentMethod.color.withAlpha(130);
    } else {
      tagLabel = tagText;
    }
    return Tooltip(
      message: tagTooltip ??
          configItem['getTooltip']?.call(row[configItem['fieldKey']]) ??
          '',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        height: 23,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        margin: const EdgeInsets.only(right: 1),
        decoration: BoxDecoration(
          color: tagColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(tagLabel,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13.5)),
      ),
    );
  }

  Widget getTag({
    required Map<String, dynamic> row,
    required Map<String, dynamic> configItem,
    required String tagText,
    Color? tagColor,
    String? tagTooltip,
    required double width,
  }) {
    return Tooltip(
      message: tagTooltip ??
          configItem['getTooltip']?.call(row[configItem['fieldKey']]) ??
          '',
      waitDuration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: width,
        child: Stack(
          children: [
            Container(
              // width: width,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: tagColor ??
                    configItem['getColor']?.call(row[configItem['fieldKey']]),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(tagText,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }
}
