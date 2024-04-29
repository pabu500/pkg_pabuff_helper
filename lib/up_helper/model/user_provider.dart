import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'mdl_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  Evs2User? _currentUser;
  User? firebaseUser;

  UserProvider({this.firebaseUser});

  Evs2User? get currentUser => _currentUser;

  set currentUser(Evs2User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void iniUser(Evs2User user) {
    _currentUser = user;
  }
}
