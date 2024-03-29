class TargetOps {
  Map<String, List<String>> targetOps;

  TargetOps({required this.targetOps});

  factory TargetOps.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> targetOps = {};
    json.forEach((key, value) {
      targetOps[key] = List<String>.from(value as List<dynamic>);
    });

    return TargetOps(targetOps: targetOps);
  }

  Map<String, List<String>> toJson() {
    return targetOps;
  }
}
