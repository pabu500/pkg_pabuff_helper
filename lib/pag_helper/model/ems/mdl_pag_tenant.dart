class MdlPagTenant {
  int id;
  String name;
  String label;
  String accountNumber;
  String siteGroupName;

  MdlPagTenant({
    required this.id,
    required this.name,
    required this.label,
    required this.siteGroupName,
    this.accountNumber = '',
  });

  factory MdlPagTenant.fromJson(Map<String, dynamic> json) {
    dynamic id = json['id'] ?? json['tenant_id'];
    if (id is String) {
      id = int.tryParse(id);
    }
    assert(id is int);

    return MdlPagTenant(
      id: id,
      name: json['name'],
      label: json['label'],
      siteGroupName: json['site_group_name'],
      accountNumber: json['account_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'label': label,
      'site_group_name': siteGroupName,
      'account_number': accountNumber,
    };
  }
}
