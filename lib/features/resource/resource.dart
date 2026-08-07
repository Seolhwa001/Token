class Resource {
  final String id;
  final String name;
  final String colorKey;
  final DateTime createdAt;

  const Resource({
    required this.id,
    required this.name,
    required this.colorKey,
    required this.createdAt,
  });

  Resource copyWith({String? name, String? colorKey}) => Resource(
        id: id,
        name: name ?? this.name,
        colorKey: colorKey ?? this.colorKey,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'colorKey': colorKey,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Resource.fromJson(Map<String, Object?> json) => Resource(
        id: json['id'] as String,
        name: json['name'] as String,
        colorKey: json['colorKey'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
