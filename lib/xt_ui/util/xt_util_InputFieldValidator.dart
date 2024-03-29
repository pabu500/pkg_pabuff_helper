import '../../up_helper/globals.dart';

String? validateOnChanged(String? val, String regNG, String callout,
    {Map<Enum, String?>? formErrors, Enum? filedKey}) {
  if (val == null) {
    return null;
  }
  RegExp reg = RegExp(regNG);
  String? result;
  if (reg.hasMatch(val)) {
    result = callout;
  }

  if (formErrors != null && filedKey != null) {
    formErrors[filedKey] = result;
  }

  return result;
}

String? validateFullName(String? value,
    {String? emptyCallout, Map<Enum, String?>? formErrors, Enum? filedKey}) {
  RegExp regex = RegExp(glb_reg_fullName);

  String? result;

  if (value == null) {
    result = 'Please enter your full name';
    if (emptyCallout != null) {
      result = emptyCallout;
    }
  } else {
    if (value.isEmpty) {
      result = 'Please enter your full name';
      if (emptyCallout != null) {
        result = emptyCallout;
      }
    } else {
      if (!regex.hasMatch(value)) {
        result = glb_fullName_callout;
      } else {
        result = null;
      }
    }
  }

  if (formErrors != null && filedKey != null) {
    formErrors[filedKey] = result;
  }

  return result;
}

String? validateUsername(String? value,
    {Map<Enum, String?>? formErrors,
    Enum? filedKey,
    Function? additonalValidator}) {
  RegExp regex = RegExp(glb_reg_loginName);

  String? result;

  if (value == null) {
    result = 'Please enter your username';
  } else {
    if (value.isEmpty) {
      result = 'Please enter your username';
    } else {
      if (!regex.hasMatch(value)) {
        result = glb_loginName_callout;
      } else {
        result = null;
      }
    }
  }
  if (result == null) {
    if (additonalValidator != null) {
      result = additonalValidator(value);
    }
  }

  if (formErrors != null && filedKey != null) {
    formErrors[filedKey] = result;
  }
  return result;
}

String? validateEmail(String? value, {String? emptyCallout}) {
  String? result;
  RegExp regex = RegExp(glb_reg_email);

  if (value == null) {
    result = 'Please enter email';
    if (emptyCallout != null) {
      result = emptyCallout;
    }
    return result;
  }

  if (value.isEmpty) {
    result = "Your email is required";
    if (emptyCallout != null) {
      result = emptyCallout;
    }
  } else {
    if (!regex.hasMatch(value)) {
      result = glb_email_callout;
    } else {
      result = null;
    }
  }
  return result;
}

String? validatePhone(String? value,
    {String? emptyCallout, Map<Enum, String?>? formErrors, Enum? filedKey}) {
  final phoneRegExp = RegExp(glb_reg_phone);

  String? result;
  if (value == null) {
    result = 'Please enter phone number';
    if (emptyCallout != null) {
      result = emptyCallout;
    }
  } else {
    if (value.isEmpty) {
      result = 'Please enter phone number';
      if (emptyCallout != null) {
        result = emptyCallout;
      }
    } else {
      if (!phoneRegExp.hasMatch(value)) {
        result = glb_phone_callout;
      } else {
        result = null;
      }
    }
  }

  if (formErrors != null && filedKey != null) {
    formErrors[filedKey] = result;
  }

  return result;
}

String? validatePassword(String? value,
    {Map<Enum, String?>? formErrors, Enum? filedKey}) {
  RegExp regex = RegExp(glb_reg_password);

  String? result;

  if (value == null) {
    result = 'Please enter password';
  } else {
    if (value.isEmpty) {
      result = 'Please enter password';
    } else {
      if (!regex.hasMatch(value)) {
        result = glb_password_callout;
      } else {
        result = null;
      }
    }
  }

  if (formErrors != null && filedKey != null) {
    formErrors[filedKey] = result;
  }

  return result;
}

String? validateConfirmPassword(String? value, String? password,
    {Map<Enum, String?>? formErrors, Enum? filedKey}) {
  String? result;
  if (password == null) {
    result = 'Please enter your password';
  } else if (value == null) {
    result = 'Please confirm your password';
  } else {
    if (value.isEmpty) {
      result = 'Please confirm your password';
    } else {
      if (value != password) {
        result = 'Password mismatch';
      } else {
        result = null;
      }
    }
  }

  if (formErrors != null && filedKey != null) {
    formErrors[filedKey] = result;
  }

  return result;
}

String? validateDateTime(String? value,
    {String? emptyCallout, Map<Enum, String?>? formErrors, Enum? filedKey}) {
  String? result;
  // if (value == null) {
  //   result = 'Please enter date';
  //   if (emptyCallout != null) {
  //     result = emptyCallout;
  //   }
  // } else {
  //   if (value.isEmpty) {
  //     result = 'Please enter date';
  //     if (emptyCallout != null) {
  //       result = emptyCallout;
  //     }
  //   } else {
  //     result = null;
  //   }
  // }

  //validate date format
  try {
    DateTime.parse(value ?? '');
  } catch (e) {
    result = 'Invalid date format';
  }

  if (formErrors != null && filedKey != null) {
    formErrors[filedKey] = result;
  }

  return result;
}
