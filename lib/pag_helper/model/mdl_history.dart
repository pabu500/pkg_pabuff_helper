enum PagItemHistoryType {
  DEVICE_READING,
  FLEET_HEALTH,
  meterListUsageSummary,
}

class MdlPagHistory {
  List<Map<String, dynamic>> history;
  Map<String, dynamic> historyMeta;

  MdlPagHistory({
    required this.history,
    this.historyMeta = const {},
  });

  factory MdlPagHistory.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw Exception('Empty json');
    }
    if (json['history'] == null) {
      throw Exception('History not found');
    }

    List<Map<String, dynamic>> history = [];
    if (json['history'] != null) {
      for (var item in json['history']) {
        Map<String, dynamic> historyItem = item;
        if (item['error'] != null) {
          historyItem['error'] = item['error'];
        }
        history.add(historyItem);
      }
    }

    return MdlPagHistory(
      history: history,
      historyMeta: json['history_meta'] ?? {},
    );
  }
}
