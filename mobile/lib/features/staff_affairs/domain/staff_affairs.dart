/// How a staff member earns on the cars they wash.
enum CommissionType {
  none('none'),
  perCar('per_car'),
  percent('percent');

  const CommissionType(this.apiValue);

  final String apiValue;

  static CommissionType fromApi(String value) => values.firstWhere((type) => type.apiValue == value);
}

/// How a staff member's pay works out: a monthly salary goes into the month's payroll; a daily-paid
/// staff member is paid ad-hoc wages, each recorded as an expense.
enum SalaryType {
  monthly('monthly'),
  daily('daily');

  const SalaryType(this.apiValue);

  final String apiValue;

  static SalaryType fromApi(String value) => values.firstWhere((type) => type.apiValue == value);
}

/// A staff member as an employee: pay terms and what they were paid this month.
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.roles,
    required this.monthlySalary,
    required this.salaryType,
    required this.commissionType,
    required this.commissionValue,
    required this.dailyWagesThisMonth,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    name: json['name'] as String,
    roles: [for (final role in json['roles'] as List) role as String],
    monthlySalary: json['monthly_salary'] as int,
    salaryType: SalaryType.fromApi(json['salary_type'] as String? ?? 'monthly'),
    commissionType: CommissionType.fromApi(json['commission_type'] as String),
    commissionValue: json['commission_value'] as int,
    dailyWagesThisMonth: json['daily_wages_this_month'] as int? ?? 0,
  );

  final String id;
  final String name;
  final List<String> roles;

  /// Minor units.
  final int monthlySalary;
  final SalaryType salaryType;
  final CommissionType commissionType;

  /// Minor units per car, or basis points of the car's value.
  final int commissionValue;

  /// What daily wages were recorded for them this month; minor units.
  final int dailyWagesThisMonth;
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
