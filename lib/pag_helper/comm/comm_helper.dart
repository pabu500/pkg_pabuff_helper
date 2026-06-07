import 'dart:convert';

dynamic getResult(String responseBody) {
  final respJson = jsonDecode(responseBody);
  if (respJson['error'] != null) {
    throw Exception(respJson['error']['message']);
  }
  final data = respJson['data'];
  if (data == null) {
    throw Exception('Failed to get response data');
  }
  final result = data['result'];
  if (result == null) {
    throw Exception("No result found in the response");
  }
  String? resultKey = data['result_key'];
  if (resultKey == null || resultKey.isEmpty) {
    throw Exception("Error: $resultKey");
  }
  if (result[resultKey] == null) {
    throw Exception("No data found in the response");
  }
  return result[resultKey];
}
