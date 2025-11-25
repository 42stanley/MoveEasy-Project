class Route {
  final String id;
  final String name;
  final String code;
  final List<RouteStop> stops;
  final double baseFare;
  final bool active;
  final int estimatedDuration; // in minutes

  Route({
    required this.id,
    required this.name,
    required this.code,
    required this.stops,
    required this.baseFare,
    this.active = true,
    required this.estimatedDuration,
  });

  factory Route.fromFirestore(Map<String, dynamic> data, String id) {
    return Route(
      id: id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      stops: (data['stops'] as List<dynamic>?)
              ?.map((stop) => RouteStop.fromMap(stop as Map<String, dynamic>))
              .toList() ??
          [],
      baseFare: (data['baseFare'] ?? 0).toDouble(),
      active: data['active'] ?? true,
      estimatedDuration: data['estimatedDuration'] ?? 30,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'stops': stops.map((stop) => stop.toMap()).toList(),
      'baseFare': baseFare,
      'active': active,
      'estimatedDuration': estimatedDuration,
    };
  }
}

class RouteStop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int order;

  RouteStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
  });

  factory RouteStop.fromMap(Map<String, dynamic> data) {
    return RouteStop(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'order': order,
    };
  }
}
