enum PagPanelType {
  topStat('top_stat'),
  propStat('prop_stat'),
  geoPane('geo_pane'),
  rankingStat('ranking_stat'),
  trendingStat('trending_stat'),
  none('none'),
  ;

  final String label;

  const PagPanelType(this.label);

  static PagPanelType byLabel(String? label) =>
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
  if (label == null) return null;
  for (var value in values) {
    if (value is PagPanelType && value.label == label) {
      return value as T;
    }
  }
  return null;
}
