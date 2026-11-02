import '../../orders/domain/order.dart';

/// How an expense is paid; null on an expense means it is still owed.
enum ExpensePaymentMethod {
  cashDrawer('cash_drawer'),
  cash('cash'),
  bankTransfer('bank_transfer'),
  card('card');

  const ExpensePaymentMethod(this.apiValue);

  final String apiValue;

  static ExpensePaymentMethod? fromApi(String? value) =>
      value == null ? null : values.firstWhere((method) => method.apiValue == value);
}

/// What money is spent on.
class ExpenseCategory {
  const ExpenseCategory({required this.id, required this.name, required this.isActive});

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) =>
      ExpenseCategory(id: json['id'] as String, name: json['name'] as String, isActive: json['is_active'] as bool);

  final String id;
  final String name;
  final bool isActive;
}

/// Someone the car wash pays, with what is still owed to them (minor units).
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.notes,
    required this.isActive,
    required this.owed,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String?,
    notes: json['notes'] as String?,
    isActive: json['is_active'] as bool,
    owed: json['owed'] as int? ?? 0,
  );

  final String id;
  final String name;
  final String? phone;
  final String? notes;
  final bool isActive;
  final int owed;
}

/// Money spent by a branch, paid or still owed. Amounts in minor units.
class Expense {
  const Expense({
    required this.id,
    required this.branchId,
    required this.category,
    required this.supplier,
    required this.amount,
    required this.spentOn,
    required this.description,
    required this.paymentMethod,
    required this.isRecurring,
    required this.createdBy,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    branchId: json['branch_id'] as String,
    category: NamedRef.fromJson(json['category'] as Map<String, dynamic>),
    supplier: json['supplier'] == null ? null : NamedRef.fromJson(json['supplier'] as Map<String, dynamic>),
    amount: json['amount'] as int,
    spentOn: DateTime.parse(json['spent_on'] as String),
    description: json['description'] as String?,
    paymentMethod: ExpensePaymentMethod.fromApi(json['payment_method'] as String?),
    isRecurring: json['is_recurring'] as bool? ?? false,
    createdBy: NamedRef.fromJson(json['created_by'] as Map<String, dynamic>),
  );

  final String id;
  final String branchId;
  final NamedRef category;
  final NamedRef? supplier;
  final int amount;
  final DateTime spentOn;
  final String? description;

  /// Null while the expense is still owed.
  final ExpensePaymentMethod? paymentMethod;
  final bool isRecurring;
  final NamedRef createdBy;

  bool get isPaid => paymentMethod != null;
}

/// How often a recurring expense falls due.
enum RecurrenceFrequency {
  weekly,
  monthly,
  yearly;

  static RecurrenceFrequency fromApi(String value) => values.firstWhere((frequency) => frequency.name == value);
}

/// An expense that falls due on a schedule, such as the monthly rent.
class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.branchId,
    required this.category,
    required this.supplier,
    required this.amount,
    required this.description,
    required this.frequency,
    required this.nextDueOn,
    required this.isActive,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) => RecurringExpense(
    id: json['id'] as String,
    branchId: json['branch_id'] as String,
    category: NamedRef.fromJson(json['category'] as Map<String, dynamic>),
    supplier: json['supplier'] == null ? null : NamedRef.fromJson(json['supplier'] as Map<String, dynamic>),
    amount: json['amount'] as int,
    description: json['description'] as String?,
    frequency: RecurrenceFrequency.fromApi(json['frequency'] as String),
    nextDueOn: DateTime.parse(json['next_due_on'] as String),
    isActive: json['is_active'] as bool,
  );

  final String id;
  final String branchId;
  final NamedRef category;
  final NamedRef? supplier;
  final int amount;
  final String? description;
  final RecurrenceFrequency frequency;
  final DateTime nextDueOn;
  final bool isActive;
}

/// `YYYY-MM-DD` for the API.
String apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
