/// How a staff member earns on the cars they wash.
enum CommissionType {
  none('none'),
  perCar('per_car'),
  percent('percent');

  const CommissionType(this.apiValue);

  final String apiValue;

  static CommissionType fromApi(String value) => values.firstWhere((type) => type.apiValue == value);
}

/// A staff member as an employee: pay terms, advances not deducted yet, and whether they are at work now.
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.roles,
    required this.monthlySalary,
    required this.commissionType,
    required this.commissionValue,
    required this.outstandingAdvances,
    required this.clockedInAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    name: json['name'] as String,
    roles: [for (final role in json['roles'] as List) role as String],
    monthlySalary: json['monthly_salary'] as int,
    commissionType: CommissionType.fromApi(json['commission_type'] as String),
    commissionValue: json['commission_value'] as int,
    outstandingAdvances: json['outstanding_advances'] as int,
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
  final int outstandingAdvances;

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
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    userName: (json['user'] as Map<String, dynamic>)['name'] as String,
    branchId: (json['branch'] as Map<String, dynamic>)['id'] as String,
    branchName: (json['branch'] as Map<String, dynamic>)['name'] as String,
    clockInAt: DateTime.parse(json['clock_in_at'] as String),
    clockOutAt: json['clock_out_at'] == null ? null : DateTime.parse(json['clock_out_at'] as String),
    minutes: json['minutes'] as int,
  );

  final String userName;
  final String branchId;
  final String branchName;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final int minutes;
}

/// Money advanced to a staff member, deducted from a later payroll.
class SalaryAdvance {
  const SalaryAdvance({
    required this.userName,
    required this.amount,
    required this.givenOn,
    required this.note,
    required this.isDeducted,
  });

  factory SalaryAdvance.fromJson(Map<String, dynamic> json) => SalaryAdvance(
    userName: (json['user'] as Map<String, dynamic>)['name'] as String,
    amount: json['amount'] as int,
    givenOn: DateTime.parse(json['given_on'] as String),
    note: json['note'] as String?,
    isDeducted: json['is_deducted'] as bool,
  );

  final String userName;
  final int amount;
  final DateTime givenOn;
  final String? note;
  final bool isDeducted;
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
          advances: line['advances'] as int,
          net: line['net'] as int,
        ),
    ],
  );

  final String id;
  final int year;
  final int month;
  final bool isPaid;
  final int totalNet;
  final List<({String name, int baseSalary, int carsCount, int commission, int advances, int net})> lines;
}
