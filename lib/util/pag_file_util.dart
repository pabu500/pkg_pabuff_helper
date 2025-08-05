import 'package:csv/csv.dart';
import 'package:download/download.dart';

Future<String> downloadPagCSV(List<Map<String, dynamic>> table,
    List<Map<String, dynamic>> listConfig, String filename) async {
  List<List<dynamic>> csvList = [];

  List<String> header = [];
  for (var i = 0; i < listConfig.length; i++) {
    if (i == 0) continue;
    header.add(listConfig[i]['col_key']);
    header.add('${listConfig[i]['col_key']}_error');
  }
  csvList.add(header);

  for (var i = 0; i < table.length; i++) {
    Map<String, dynamic> rowToSave = {};

    for (var j = 0; j < listConfig.length; j++) {
      if (j == 0) continue;
      rowToSave[listConfig[j]['col_key']] =
          '${table[i][listConfig[j]['col_key']]}';
      rowToSave['${listConfig[j]['col_key']}_error'] =
          table[i]['${listConfig[j]['col_key']}_error'] ?? '';
    }
    csvList.add(rowToSave.values.toList());
  }

  String csv = const ListToCsvConverter().convert(csvList);
  final stream = Stream.fromIterable(csv.codeUnits);

  await download(stream, filename);
  return filename;
}
