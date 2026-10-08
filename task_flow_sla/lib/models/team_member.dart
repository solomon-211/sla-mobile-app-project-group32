class TeamMember {
  final int? id;
  final String name;
  final String role;
  final String email;

  /// Index into [AppColors.avatarPalette].
  final int colorIndex;

  const TeamMember({
    this.id,
    required this.name,
    required this.role,
    required this.email,
    this.colorIndex = 0,
  });

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// "Amina K." -> "AK"
  String get initials {
    final parts = name
        .replaceAll('.', '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  TeamMember copyWith({int? id, String? name, String? role, String? email}) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      colorIndex: colorIndex,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'role': role,
      'email': email,
      'color_index': colorIndex,
    };
  }

  factory TeamMember.fromMap(Map<String, Object?> map) {
    return TeamMember(
      id: map['id'] as int,
      name: map['name'] as String,
      role: map['role'] as String,
      email: map['email'] as String,
      colorIndex: map['color_index'] as int,
    );
  }
}
