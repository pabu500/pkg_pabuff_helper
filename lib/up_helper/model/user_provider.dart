import 'package:flutter/material.dart';
import 'mdl_user.dart';

class UserProvider extends ChangeNotifier {
  Evs2User? _currentUser;

  Evs2User? get currentUser => _currentUser;

  set currentUser(Evs2User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void iniUser(Evs2User user) {
    _currentUser = user;
  }
}
