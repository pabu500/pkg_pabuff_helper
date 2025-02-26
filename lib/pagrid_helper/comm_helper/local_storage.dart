import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const secStorage = FlutterSecureStorage();

void saveToSecuredStorage(String key, String val) async {
  await secStorage.write(key: key, value: val);
}

void saveToSecuredStorage2(String key, Map<String, dynamic> val) async {
  await secStorage.write(key: key, value: jsonEncode(val));
}

Future<String> readFromSecuredStorage(String key) async {
  String? val = await secStorage.read(key: key);
  return val ?? '';
}

Future<Map<String, dynamic>> readFromSecuredStorage2(String key) async {
  String? val = await secStorage.read(key: key);
  try {
    return jsonDecode(val ?? '{}');
  } catch (err) {
    return {};
  }
}

Future<void> removeFromSecuredStorage(String key) async {
  await secStorage.delete(key: key);
}

Future<void> saveToSharedPref(String key, dynamic val,
    {bool removeBeforeSave = false}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // if val is map, need to remove before save
  // ohterwise, some key-value pairs may not be updated
  if (removeBeforeSave) {
    await prefs.remove(key);
  }

// // Save an integer value to 'counter' key.
//   await prefs.setInt('counter', 10);
// // Save an boolean value to 'repeat' key.
//   await prefs.setBool('repeat', true);
// // Save an double value to 'decimal' key.
//   await prefs.setDouble('decimal', 1.5);
// // Save an String value to 'action' key.
//   await prefs.setString('action', 'Start');
// // Save an list of strings to 'items' key.
//   await prefs.setStringList('items', <String>['Earth', 'Moon', 'Sun']);
  if (val is int) {
    await prefs.setInt(key, val);
  } else if (val is bool) {
    await prefs.setBool(key, val);
  } else if (val is double) {
    await prefs.setDouble(key, val);
  } else if (val is String) {
    await prefs.setString(key, val);
  } else if (val is List<String>) {
    await prefs.setStringList(key, val);
  } else if (val is Map<String, dynamic>) {
    await prefs.setString(key, jsonEncode(val));
  } else {
    await prefs.setString(key, val.toString());
  }
}

late final SharedPreferences prefs;
Future<void> iniSharedPref() async {
  prefs = await SharedPreferences.getInstance();
}

dynamic readFromSharedPref(String key) {
  return prefs.get(key);
}

//remove by type
Future<dynamic> readFromSharedPref2(String key, String type) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (type == 'int') {
    return prefs.getInt(key);
  } else if (type == 'bool') {
    return prefs.getBool(key);
  } else if (type == 'double') {
    return prefs.getDouble(key);
  } else if (type == 'String') {
    return prefs.getString(key);
  } else if (type == 'List<String>') {
    return prefs.getStringList(key);
  } else {
    return prefs.getString(key);
  }
}

Future<void> removeFromSharedPref(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
