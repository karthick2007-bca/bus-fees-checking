class Route {
  final String id;
  final String name;
  final double fee;

  Route({
    required this.id,
    required this.name,
    required this.fee,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fee': fee,
    };
  }

  factory Route.fromMap(Map<String, dynamic> map) {
    return Route(
      id: map['id'],
      name: map['name'],
      fee: (map['fee'] as num).toDouble(),
    );
  }
}