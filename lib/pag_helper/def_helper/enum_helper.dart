T? enumByLabel<T extends Enum>(
    String? label, List<T> values, String Function(T) labelSelector) {
  if (label == null) return null;
  for (T v in values) {
    if (labelSelector(v) == label) {
      return v;
    }
  }
  return null;
}

T? enumByValue<T extends Enum>(
    String? value, List<T> values, String Function(T) valueSelector) {
  if (value == null) return null;
  for (T v in values) {
    // final v = valueSelector(value);
    if (valueSelector(v) == value) {
      return v;
    }
  }
  return null;
}

T? enumByTag<T extends Enum>(
    String? tag, List<T> values, String Function(T) tagSelector) {
  if (tag == null) return null;
  for (var v in values) {
    if (tagSelector(v) == tag) {
      return v;
    }
  }
  return null;
}
