class MdlPagRole {
  int id;
  String name;
  String? label;
  int rank;

  MdlPagRole({
    required this.id,
    required this.name,
    this.label,
    this.rank = -1,
  });

  factory MdlPagRole.fromJson(Map<String, dynamic> json) {
    return MdlPagRole(
      id: json['id'] ?? -1,
      name: json['name'],
      label: json['label'],
      rank: json['rank'] ?? -1,
    );
  }
}
