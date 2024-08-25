import 'package:flutter/material.dart';

import '../../../util/util.dart';
import '../../xt_helpers.dart';
import '../file/wgt_save_table.dart';

Widget getPagenationBar(
    BuildContext context,
    int? rowsThisPage,
    int? rowsPerPage,
    int? totalRows,
    int? currentPage,
    Function? onPrev,
    Function? onNext,
    Function? onClickPage,
    {bool narrow = false,
    List<Map<String, dynamic>>? rows,
    required Function getCsv,
    String listPrefix = ''}) {
  if (rowsPerPage == null || totalRows == null || currentPage == null) {
    return Container();
  }
  if (totalRows == 0) return Container();

  return SizedBox(
    height: 55,
    child: narrow
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, -5),
                child: IconButton(
                  icon: const Icon(Icons.navigate_before),
                  onPressed: currentPage == 1
                      ? null
                      : () {
                          if (onPrev != null) {
                            onPrev();
                          }
                        },
                ),
              ),
              //currentPage/totalPages
              Text(
                '$currentPage/${(totalRows / rowsPerPage).ceil()}',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).hintColor,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -5),
                child: IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: currentPage == (totalRows / rowsPerPage).ceil()
                      ? null
                      : () {
                          if (onNext != null) {
                            onNext();
                          }
                        },
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // horizontalSpaceTiny,
              WgtSaveTable(
                iconSize: 21,
                tooltip: 'Download list to CSV file',
                getList: getCsv,
                fileName: makeReportName(listPrefix, null, null, null),
              ),
              horizontalSpaceTiny,
              Text(
                '${rowsThisPage ?? ''} / $totalRows',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).hintColor,
                ),
              ),
              Expanded(child: Container()),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: IconButton(
                      icon: const Icon(Icons.navigate_before),
                      onPressed: currentPage == 1
                          ? null
                          : () {
                              if (onPrev != null) {
                                onPrev();
                              }
                            },
                    ),
                  ),
                  // Text(
                  //   '$currentPage',
                  //   style: TextStyle(
                  //     fontSize: 15,
                  //     color: Theme.of(context).hintColor,
                  //   ),
                  // ),
                  getPageLinkRow(context, rowsPerPage, totalRows, currentPage,
                      onClickPage),
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: IconButton(
                      icon: const Icon(Icons.navigate_next),
                      onPressed: currentPage == (totalRows / rowsPerPage).ceil()
                          ? null
                          : () {
                              if (onNext != null) {
                                onNext();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
  );
}

Widget getPageLinkRow(BuildContext context, int rowsPerPage, int totalRows,
    int currentPage, Function? onClickPage) {
  List<Widget> pagesNumbers = [];
  int pages = (totalRows / rowsPerPage).ceil();
  // show link for first and last 3 pages
  // fill the middle with ...
  for (int i = 1; i <= pages; i++) {
    if (i == 1 ||
        i == pages ||
        (i >= currentPage - 2 && i <= currentPage + 2)) {
      pagesNumbers.add(
        InkWell(
          onTap: i == currentPage
              ? null
              : () {
                  if (onClickPage != null) {
                    onClickPage(i);
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13.0, vertical: 1),
                child: SizedBox(
                  height: 35,
                  child: Text(
                    '$i',
                    style: TextStyle(
                      fontSize: 16,
                      color: i == currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (pagesNumbers.isNotEmpty &&
        pagesNumbers.last.runtimeType != Text) {
      pagesNumbers.add(
        Text(
          '...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.withOpacity(0.7),
          ),
        ),
      );
    }
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: pagesNumbers,
  );
}
