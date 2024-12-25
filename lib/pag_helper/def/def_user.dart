enum PagPortalType {
  pagConsole('pag-console'),
  emsTp('ems-tp'),
  evsCp('evs-cp'),
  none('none'),
  ;

  const PagPortalType(
    this.label,
  );

  final String label;

  static PagPortalType byLabel(String? label) =>
      enumByLabel(
        label,
        values,
      ) ??
      none;
}

// T? enumByLabel<T extends Enum>(
//   String? label,
//   List<T> values,
// ) {
//   return label == null ? null : values.asNameMap()[label];
// }

T? enumByLabel<T extends Enum>(
  String? label,
  List<T> values,
) {
  if (label == null) return null;
  for (var value in values) {
    if (value is PagPortalType && value.label == label) {
      return value as T;
    }
  }
  return null;
}
