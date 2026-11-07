import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Opens WhatsApp on a customer's number with [message] written, for staff to read and send themselves. It costs
/// nothing and sends nothing by itself. [phone] is stored as +97333334444.
Future<void> openWhatsApp(BuildContext context, String phone, String message) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = AppLocalizations.of(context).whatsAppNotOpened;
  final uri = Uri.https('wa.me', '/${phone.replaceAll(RegExp(r'\D'), '')}', {'text': message});

  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Reported below, as when no app could open it.
  }
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}
