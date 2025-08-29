class MdlPagLocation {
  int id;
  String name;
  String label;
  double? lat;
  double? lng;

  MdlPagLocation({
    required this.id,
    required this.name,
    required this.label,
    this.lat,
    this.lng,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MdlPagLocation && other.id == id && other.name == name;
  }

  factory MdlPagLocation.fromJson(Map<String, dynamic> json) {
    dynamic id = json['id'] ?? json['location_id'];
    if (id is String) {
      id = int.tryParse(id);
      if (id == null) {
        throw Exception('Invalid id: $id');
      }
    } else if (id is double) {
      id = id.toInt();
    }

    assert(json['name'] != null);
    String name = json['name'];

    dynamic lat = json['lat'];
    if (lat is String) {
      lat = double.tryParse(lat);
      if (lat == null) {
        throw Exception('Invalid lat: $lat');
      }
    } else if (lat is int) {
      lat = lat.toDouble();
    }

    dynamic lng = json['lng'];
    if (lng is String) {
      lng = double.tryParse(lng);
      if (lng == null) {
        throw Exception('Invalid lng: $lng');
      }
    } else if (lng is int) {
      lng = lng.toDouble();
    }

    return MdlPagLocation(
      id: id,
      name: name,
      label: json['label'] ?? '',
      lat: lat,
      lng: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'lat': lat,
      'lng': lng,
    };
  }
}
