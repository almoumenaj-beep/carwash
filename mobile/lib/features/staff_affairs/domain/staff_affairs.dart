/// How a staff member earns on the cars they wash.
enum CommissionType {
  none('none'),
  perCar('per_car'),
  percent('percent');

  const CommissionType(this.apiValue);

  final String apiValue;

  static CommissionType fromApi(String value) => values.firstWhere((type) => type.apiValue == value);
}

/// A staff member as an employee: pay terms and whether they are at work now.
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.roles,
    required this.monthlySalary,
    required this.commissionType,
    required this.commissionValue,
    required this.clockedInAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    name: json['name'] as String,
    roles: [for (final role in json['roles'] as List) role as String],
    monthlySalary: json['monthly_salary'] as int,
    commissionType: CommissionType.fromApi(json['commission_type'] as String),
    commissionValue: json['commission_value'] as int,
    clockedInAt: json['clocked_in_at'] == null ? null : DateTime.parse(json['clocked_in_at'] as String),
  );

  final String id;
  final String name;
  final List<String> roles;

  /// Minor units.
  final int monthlySalary;
  final CommissionType commissionType;

  /// Minor units per car, or basis points of the car's value.
  final int commissionValue;

  /// Set while they are clocked in.
  final DateTime? clockedInAt;
}

/// A staff member's time at a branch.
class AttendanceRecord {
  const AttendanceRecord({
    required this.userName,
    required this.branchId,
    required this.branchName,
    required this.clockInAt,
    required this.clockOutAt,
    required this.minutes,
    this.autoClockedOut = false,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    userName: (json['user'] as Map<String, dynamic>)['name'] as String,
    branchId: (json['branch'] as Map<String, dynamic>)['id'] as String,
    branchName: (json['branch'] as Map<String, dynamic>)['name'] as String,
    clockInAt: DateTime.parse(json['clock_in_at'] as String),
    clockOutAt: json['clock_out_at'] == null ? null : DateTime.parse(json['clock_out_at'] as String),
    minutes: json['minutes'] as int,
    autoClockedOut: json['auto_clocked_out'] as bool? ?? false,
  );

  final String userName;
  final String branchId;
  final String branchName;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final int minutes;

  /// Clocked out by the system at the branch's closing time because they forgot.
  final bool autoClockedOut;
}

/// A branch's attendance over a period, per staff member. Does not affect pay.
class AttendanceSummary {
  const AttendanceSummary({required this.from, required this.to, required this.totalMinutes, required this.staff});

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) => AttendanceSummary(
    from: DateTime.parse(json['from'] as String),
    to: DateTime.parse(json['to'] as String),
    totalMinutes: json['total_minutes'] as int,
    staff: [
      for (final member in json['staff'] as List) AttendanceStaffSummary.fromJson(member as Map<String, dynamic>),
    ],
  );

  final DateTime from;
  final DateTime to;
  final int totalMinutes;
  final List<AttendanceStaffSummary> staff;
}

/// One staff member's days, hours and records at a branch over a period.
class AttendanceStaffSummary {
  const AttendanceStaffSummary({
    required this.userName,
    required this.days,
    required this.minutes,
    required this.autoClockedOutCount,
    required this.records,
  });

  factory AttendanceStaffSummary.fromJson(Map<String, dynamic> json) => AttendanceStaffSummary(
    userName: (json['user'] as Map<String, dynamic>)['name'] as String,
    days: json['days'] as int,
    minutes: json['minutes'] as int,
    autoClockedOutCount: json['auto_clocked_out'] as int,
    records: [for (final record in json['records'] as List) AttendanceRecord.fromJson(record as Map<String, dynamic>)],
  );

  final String userName;
  final int days;
  final int minutes;
  final int autoClockedOutCount;
  final List<AttendanceRecord> records;
}

/// A month's pay, drafted until paid.
class PayrollRun {
  const PayrollRun({
    required this.id,
    required this.year,
    required this.month,
    required this.isPaid,
    required this.totalNet,
    required this.lines,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> json) => PayrollRun(
    id: json['id'] as String,
    year: json['year'] as int,
    month: json['month'] as int,
    isPaid: json['status'] == 'paid',
    totalNet: json['total_net'] as int,
    lines: [
      for (final line in json['lines'] as List)
        (
          name: ((line as Map<String, dynamic>)['user'] as Map<String, dynamic>)['name'] as String,
          baseSalary: line['base_salary'] as int,
          carsCount: line['cars_count'] as int,
          commission: line['commission'] as int,
          net: line['net'] as int,
        ),
    ],
  );

  final String id;
  final int year;
  final int month;
  final bool isPaid;
  final int totalNet;
  final List<({String name, int baseSalary, int carsCount, int commission, int net})> lines;
}
