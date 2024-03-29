import 'package:flutter/material.dart';
import 'mdl_user.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  set currentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void iniUser(User user) {
    _currentUser = user;
  }
}
