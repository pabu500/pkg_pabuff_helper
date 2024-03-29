enum comm_tasks { login, register, forgotPassword }

String? errorFilter(String? err, comm_tasks task) {
  if (err == null) return null;

  if (err.length < 13) return err;

  String? _err;

  if (err.contains('retrieving user')) {
    _err = 'Error retriving user info';
    if (task == comm_tasks.login) _err = 'Invalid username or password';
  } else if (err.contains('Bad credentials')) {
    _err = 'Invalid username or password';
  } else if (err.contains('portal')) {
    _err = 'Incorrect portal';
  } else if (err.contains('scope')) {
    _err = 'Error getting scope info';
  } else {
    _err = 'Service Error';
  }

  return _err;
}
