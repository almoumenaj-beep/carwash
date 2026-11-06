import '../../orders/domain/order.dart';

/// A cashier's shift at a branch's till. Amounts are in minor units (BHD: fils).
class CashShift {
  const CashShift({
    required this.id,
    required this.branchId,
    this.branchName,
    required this.isOpen,
    required this.openedBy,
    required this.openedAt,
    required this.openingFloat,
    required this.invoicesCount,
    required this.discountsTotal,
    required this.cashTaken,
    this.cardTaken = 0,
    this.benefitTaken = 0,
    this.cashPaidOut = 0,
    required this.expectedCash,
    required this.countedCash,
    required this.variance,
    required this.closeNote,
    this.autoClosed = false,
    required this.closedAt,
  });

  factory CashShift.fromJson(Map<String, dynamic> json) => CashShift(
    id: json['id'] as String,
    branchId: json['branch_id'] as String,
    branchName: json['branch_name'] as String?,
    isOpen: json['is_open'] as bool,
    openedBy: NamedRef.fromJson(json['opened_by'] as Map<String, dynamic>),
    openedAt: DateTime.parse(json['opened_at'] as String),
    openingFloat: json['opening_float'] as int,
    invoicesCount: json['invoices_count'] as int,
    discountsTotal: json['discounts_total'] as int,
    cashTaken: json['cash_taken'] as int,
    cardTaken: json['card_taken'] as int? ?? 0,
    benefitTaken: json['benefit_taken'] as int? ?? 0,
    cashPaidOut: json['cash_paid_out'] as int? ?? 0,
    expectedCash: json['expected_cash'] as int,
    countedCash: json['counted_cash'] as int?,
    variance: json['variance'] as int?,
    closeNote: json['close_note'] as String?,
    autoClosed: json['auto_closed'] as bool? ?? false,
    closedAt: json['closed_at'] == null ? null : DateTime.parse(json['closed_at'] as String),
  );

  final String id;
  final String branchId;
  final String? branchName;
  final bool isOpen;
  final NamedRef openedBy;
  final DateTime openedAt;

  /// The cash put in the drawer when the shift opened.
  final int openingFloat;
  final int invoicesCount;
  final int discountsTotal;

  /// Cash taken for invoices, after change was given.
  final int cashTaken;

  /// Collected by card and Benefit: outside the drawer, so not part of [expectedCash].
  final int cardTaken;
  final int benefitTaken;

  /// Cash taken out of the drawer to pay expenses.
  final int cashPaidOut;

  /// What should be in the drawer: the float plus the cash taken, less the expenses paid from it.
  final int expectedCash;

  /// Set once closed; [variance] is counted minus expected, negative when the drawer is short.
  final int? countedCash;
  final int? variance;
  final String? closeNote;

  /// Closed by the system at closing time because the cashier forgot to; the drawer still needs a
  /// real count.
  final bool autoClosed;
  final DateTime? closedAt;
}
