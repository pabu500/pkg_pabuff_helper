String? validatorLat(String val) {
  if (val.isEmpty) return null;
  final double? latitude = double.tryParse(val);
  if (latitude == null || latitude < -90 || latitude > 90) {
    return 'Invalid latitude value. Must be between -90 and 90.';
  }
  return null;
}

String? validatorLng(String val) {
  if (val.isEmpty) return null;
  final double? longitude = double.tryParse(val);
  if (longitude == null || longitude < -180 || longitude > 180) {
    return 'Invalid longitude value. Must be between -180 and 180.';
  }
  return null;
}
