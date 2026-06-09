import 'dart:convert';

dynamic getResult(String responseBody,
    {String defualtErrorMsg = 'Failed to get response data'}) {
  final respJson = jsonDecode(responseBody);
  if (respJson['error'] != null) {
    throw Exception(respJson['error']['message']);
  }
  final data = respJson['data'];
  if (data == null) {
    throw Exception(defualtErrorMsg);
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
    throw Exception("No data found for key: $resultKey");
  }
  return result[resultKey];
}
