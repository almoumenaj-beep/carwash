import '../../l10n/app_localizations.dart';

/// A payment method from the API (`cash`, `cash_drawer`...) in words.
String moneyMethodLabel(AppLocalizations l10n, String method) => switch (method) {
  'cash' => l10n.payCash,
  'cash_drawer' => l10n.payFromDrawer,
  'card' => l10n.payCard,
  'bank_transfer' => l10n.payBankTransfer,
  'benefit' => l10n.payBenefit,
  _ => method,
};
