String? validateDesignation(String? value) {
  if (value == null) {
    return null;
  }

  if (value != null && value.length > 55) {
    return 'Designation must be at most 55 characters';
  }
  return null;
}

String? validateUserRemark(String? value) {
  if (value == null) {
    return null;
  }

  if (value != null && value.length > 55) {
    return 'Remark must be at most 55 characters';
  }
  return null;
}
