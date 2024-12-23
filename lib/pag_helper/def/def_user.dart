enum PagPortalType {
  pag('e@g'),
  emsTp('ems-tp'),
  evsCp('evs-cp'),
  none('none'),
  ;

  const PagPortalType(
    this.label,
  );

  final String label;

  static PagPortalType byLabel(
    String? label,
  ) =>
      enumByLabel(
        label,
        values,
      ) ??
      none;
}

T? enumByLabel<T extends Enum>(
  String? label,
  List<T> values,
) {
  return label == null ? null : values.asNameMap()[label];
}
