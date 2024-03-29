class ValidationModel {
  String? value;
  String? error;
  // bool dbUnique = false;
  // bool enableDBcheck = true;

  ValidationModel(this.value, this.error);

  void update(String? val, String? err) {
    value = val;
    error = err;
  }
}
