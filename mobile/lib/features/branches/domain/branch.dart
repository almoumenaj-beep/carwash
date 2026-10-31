/// Week days in display order for the Gulf (the week starts on Saturday); matches the API keys.
const weekDays = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];

/// Opening and closing time of one day as "HH:MM". A closing time before the opening time means after midnight.
class DayHours {
  const DayHours({required this.opens, required this.closes});

  factory DayHours.fromJson(Map<String, dynamic> json) =>
      DayHours(opens: json['opens'] as String, closes: json['closes'] as String);

  static const standard = DayHours(opens: '08:00', closes: '22:00');

  final String opens;
  final String closes;

  Map<String, String> toJson() => {'opens': opens, 'closes': closes};

  DayHours copyWith({String? opens, String? closes}) =>
      DayHours(opens: opens ?? this.opens, closes: closes ?? this.closes);
}

/// A branch with its weekly hours and bays, from `/branches/{id}`.
class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.phone,
    required this.address,
    required this.isActive,
    required this.openingHours,
    required this.bays,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    final hours = (json['opening_hours'] as Map<String, dynamic>?) ?? const {};

    return Branch(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool,
      openingHours: {
        for (final day in weekDays)
          day: hours[day] == null ? null : DayHours.fromJson(hours[day] as Map<String, dynamic>),
      },
      bays: [for (final bay in (json['bays'] as List?) ?? const []) Bay.fromJson(bay as Map<String, dynamic>)],
    );
  }

  final String id;
  final String name;
  final String code;
  final String? phone;
  final String? address;
  final bool isActive;

  /// Every day of [weekDays]; null means closed.
  final Map<String, DayHours?> openingHours;
  final List<Bay> bays;
}

/// A wash bay or station in a branch.
class Bay {
  const Bay({required this.id, required this.name, required this.sortOrder, required this.isActive});

  factory Bay.fromJson(Map<String, dynamic> json) => Bay(
    id: json['id'] as String,
    name: json['name'] as String,
    sortOrder: json['sort_order'] as int,
    isActive: json['is_active'] as bool,
  );

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
}
