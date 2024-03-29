class xt_util_FormCorrdinator {
  Map<Enum, String> formData = {};
  Map<Enum, String?> formErrors = {};
  Map<Enum, Function> fieldValidators = {};
  Map<Enum, Function> fieldUpdateErrors = {};
  Map<Enum, Function> fieldToggleDisalbed = {};
  Map<Enum, Function> fieldOnChangedValidators = {};
  Map<Enum, Function> fieldCheckUnique = {};
  Map<Enum, Function> toggleWait = {};
  Map<Enum, Function> fieldSave = {};
  Map<Enum, Function> fieldClearText = {};

  void regFieldUpdateErrorText(Enum fieldKey, Function udpateErrorText) {
    fieldUpdateErrors[fieldKey] = udpateErrorText;
  }

  void regFieldValidator(Enum fieldKey, Function validator) {
    fieldValidators[fieldKey] = validator;
  }

  void regFieldCheckUnique(Enum fieldKey, Function hdlCheckUnique) {
    fieldCheckUnique[fieldKey] = hdlCheckUnique;
  }

  void regFieldToggleDisabled(Enum fieldKey, Function toggleDisabled) {
    fieldToggleDisalbed[fieldKey] = toggleDisabled;
  }

  void regToggleWait(Enum fieldKey, Function funcWait) {
    toggleWait[fieldKey] = funcWait;
  }

  void regClearText(Enum fieldKey, Function funcClearText) {
    fieldClearText[fieldKey] = funcClearText;
  }

  void regFieldSave(Enum fieldKey, Function hdlSave) {
    fieldSave[fieldKey] = hdlSave;
  }

  bool precheckAll() {
    for (Enum key in formErrors.keys) {
      if (formErrors[key] != null) {
        return false;
      }
    }
    return true;
  }

  void toggleDisabledAll(bool disabled) {
    for (Enum key in fieldToggleDisalbed.keys) {
      fieldToggleDisalbed[key]!(disabled);
    }
  }

  void clearTextAll() {
    for (Enum key in fieldClearText.keys) {
      fieldClearText[key]!();
    }
  }

  Future<void> checkUniques() async {
    //Future.forEach will execute the functions sequentially, i.e. wait for each to complete before starting the next
    //Future.wait will execute the functions in parallel
    await Future.wait(
      fieldCheckUnique.keys.map((key) async {
        if (formData[key] != null) {
          Function? func = fieldCheckUnique[key];
          if (func != null) {
            await func(key, formData[key]);
          }
        }
      }),
    );
  }

  bool validateAll() {
    for (Enum key in fieldValidators.keys) {
      Function? func = fieldValidators[key];
      if (func != null) {
        String? result = func(formData[key] ?? '');
        if (result != null) {
          formErrors[key] = result;
          fieldUpdateErrors[key]!(result);
          return false;
        }
      }
    }

    for (Enum key in formErrors.keys) {
      if (formErrors[key] != null) {
        return false;
      }
    }

    return true;
  }

  void saveAll() {
    // for (Enum key in fieldSave.keys) {
    //   Function? func = fieldSave[key];
    //   if (func != null) {
    //     func(formData[key]);
    //   }
    // }
    fieldSave.forEach((key, func) => {func()});
  }
}
