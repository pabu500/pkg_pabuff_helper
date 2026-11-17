import 'package:csv/csv.dart';

/// Detect record separators outside quoted fields. Keep quoted newlines intact.
List<List<dynamic>> parseCsvTable(String source) {
  if (source.startsWith('\ufeff')) source = source.substring(1);
  var eol = '\r\n';
  var quoted = false;
  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (char == '"') {
      if (quoted && i + 1 < source.length && source[i + 1] == '"') {
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (!quoted && (char == '\r' || char == '\n')) {
      eol = char == '\r' && i + 1 < source.length && source[i + 1] == '\n'
          ? '\r\n'
          : char;
      break;
    }
  }
  return CsvToListConverter(
    shouldParseNumbers: false,
    fieldDelimiter: ',',
    eol: eol,
    allowInvalid: false,
  ).convert(source);
}
