enum PagFleetHealthType {
  lrt('lrt_too_old'),
  unknown('unknown'),
  ;

  final String label;

  const PagFleetHealthType(this.label);

  static PagFleetHealthType byLabel(String? label) =>
      enumByLabel(label, values) ?? unknown;
}

T? enumByLabel<T extends Enum>(String? label, List<T> values) {
  return label == null ? null : values.asNameMap()[label];
}
