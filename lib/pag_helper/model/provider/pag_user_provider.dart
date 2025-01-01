import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PagUserProvider extends ChangeNotifier {
  MdlPagUser? _currentUser;
  User? firebaseUser;

  PagUserProvider({this.firebaseUser});

  MdlPagUser? get currentUser => _currentUser;

  set currentUser(MdlPagUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setCurrentUser(MdlPagUser user) {
    _currentUser = user;
  }
}
