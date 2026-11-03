/// A name with an amount in minor units, e.g. an expense category and what was spent on it.
typedef NamedAmount = ({String name, int amount});

/// Profit and loss over a period, with what each branch, service and washer brought in. Minor units.
class ProfitAndLoss {
  const ProfitAndLoss({
    required this.invoicesCount,
    required this.gross,
    required this.discounts,
    required this.sales,
    required this.vat,
    required this.netSales,
    required this.expenses,
    required this.owed,
    required this.expensesByCategory,
    required this.profit,
    required this.marginBps,
    required this.byBranch,
    required this.byService,
    required this.byWasher,
  });

  factory ProfitAndLoss.fromJson(Map<String, dynamic> json) {
    final revenue = json['revenue'] as Map<String, dynamic>;
    final expenses = json['expenses'] as Map<String, dynamic>;
    List<Map<String, dynamic>> rows(Object? list) => [for (final row in list as List) row as Map<String, dynamic>];

    return ProfitAndLoss(
      invoicesCount: revenue['invoices_count'] as int,
      gross: revenue['gross'] as int,
      discounts: revenue['discounts'] as int,
      sales: revenue['sales'] as int,
      vat: revenue['vat'] as int,
      netSales: revenue['net_sales'] as int,
      expenses: expenses['total'] as int,
      owed: expenses['owed'] as int,
      expensesByCategory: [
        for (final row in rows(expenses['by_category'])) (name: row['name'] as String, amount: row['amount'] as int),
      ],
      profit: json['profit'] as int,
      marginBps: json['margin_bps'] as int?,
      byBranch: [
        for (final row in rows(json['by_branch']))
          (
            name: row['name'] as String,
            netSales: row['net_sales'] as int,
            expenses: row['expenses'] as int,
            profit: row['profit'] as int,
          ),
      ],
      byService: [
        for (final row in rows(json['by_service']))
          (
            name: row['name'] as String,
            quantity: row['quantity'] as int,
            netRevenue: row['net_revenue'] as int,
            materials: row['materials'] as int,
            profit: row['profit'] as int,
          ),
      ],
      byWasher: [
        for (final row in rows(json['by_washer']))
          (
            name: row['name'] as String,
            cars: row['cars'] as int,
            netRevenue: row['net_revenue'] as int,
            pay: row['pay'] as int,
          ),
      ],
    );
  }

  final int invoicesCount;
  final int gross;
  final int discounts;

  /// What customers paid, VAT included.
  final int sales;
  final int vat;
  final int netSales;

  /// Expenses dated in the period, paid or owed.
  final int expenses;
  final int owed;
  final List<NamedAmount> expensesByCategory;

  /// Net sales less expenses; negative for a loss.
  final int profit;

  /// Profit as basis points of net sales; null without sales.
  final int? marginBps;
  final List<({String name, int netSales, int expenses, int profit})> byBranch;

  /// [materials] is an estimate at today's material costs.
  final List<({String name, int quantity, int netRevenue, int materials, int profit})> byService;

  /// [netRevenue] is the washer's share of the cars they worked on; [pay] their salary and commission.
  final List<({String name, int cars, int netRevenue, int pay})> byWasher;

  bool get isEmpty => invoicesCount == 0 && expenses == 0;
}

/// Money in and out over a period, by payment method and by day. Minor units.
class CashFlow {
  const CashFlow({
    required this.inflow,
    required this.inflowByMethod,
    required this.outflow,
    required this.outflowByMethod,
    required this.net,
    required this.owed,
    required this.owedCount,
    required this.byDay,
  });

  factory CashFlow.fromJson(Map<String, dynamic> json) {
    final inflow = json['inflow'] as Map<String, dynamic>;
    final outflow = json['outflow'] as Map<String, dynamic>;
    final owed = json['owed'] as Map<String, dynamic>;
    List<NamedAmount> methods(Map<String, dynamic> flow) => [
      for (final row in flow['by_method'] as List)
        (name: (row as Map<String, dynamic>)['method'] as String, amount: row['amount'] as int),
    ];

    return CashFlow(
      inflow: inflow['total'] as int,
      inflowByMethod: methods(inflow),
      outflow: outflow['total'] as int,
      outflowByMethod: methods(outflow),
      net: json['net'] as int,
      owed: owed['total'] as int,
      owedCount: owed['count'] as int,
      byDay: [
        for (final row in json['by_day'] as List)
          (
            date: DateTime.parse((row as Map<String, dynamic>)['date'] as String),
            inflow: row['inflow'] as int,
            outflow: row['outflow'] as int,
          ),
      ],
    );
  }

  final int inflow;

  /// [NamedAmount.name] is the API's payment method, e.g. `cash`.
  final List<NamedAmount> inflowByMethod;
  final int outflow;
  final List<NamedAmount> outflowByMethod;
  final int net;

  /// What is still owed today, whatever the period.
  final int owed;
  final int owedCount;
  final List<({DateTime date, int inflow, int outflow})> byDay;
}
