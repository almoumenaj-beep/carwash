import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../network/api_problem.dart';

/// The text to show the user for a failed request. Server messages arrive already translated.
String problemMessage(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);

  if (error is ApiProblem) {
    if (error.isNetwork) {
      return l10n.networkError;
    }
    if (error.detail.isNotEmpty) {
      return error.detail;
    }
  }

  return l10n.unexpectedError;
}
