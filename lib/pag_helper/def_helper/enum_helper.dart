T? enumByLabel<T extends Enum>(
    String? label, List<T> values, String Function(T) labelSelector) {
  if (label == null) return null;
  for (T value in values) {
    if (labelSelector(value) == label) {
      return value;
    }
  }
  return null;
}
