/// A word in a message template that becomes the customer's details when the message is written.
enum MessageToken {
  name('{الاسم}'),
  plate('{اللوحة}'),
  date('{التاريخ}'),
  time('{الوقت}'),
  carWash('{المغسلة}');

  const MessageToken(this.text);

  final String text;
}

/// The messages staff send on WhatsApp, each with the words it can use and the text it starts from.
enum MessageTemplateKind {
  ready('ready', [
    MessageToken.name,
    MessageToken.plate,
    MessageToken.carWash,
  ], 'مرحباً {الاسم}، سيارتك {اللوحة} جاهزة للاستلام. {المغسلة}'),
  reminder('reminder', [
    MessageToken.name,
    MessageToken.plate,
    MessageToken.date,
    MessageToken.time,
    MessageToken.carWash,
  ], 'مرحباً {الاسم}، نذكّرك بموعدك يوم {التاريخ} الساعة {الوقت}. {المغسلة}'),
  greeting('greeting', [MessageToken.name, MessageToken.carWash], 'مرحباً {الاسم}');

  const MessageTemplateKind(this.apiKey, this.tokens, this.defaultText);

  final String apiKey;
  final List<MessageToken> tokens;
  final String defaultText;
}

/// The owner's wording of each message; a message they did not write uses its default text.
class MessageTemplates {
  const MessageTemplates([this._written = const {}]);

  factory MessageTemplates.fromJson(Map<String, dynamic>? json) => MessageTemplates({
    for (final entry in (json ?? const <String, dynamic>{}).entries)
      if (entry.value is String && (entry.value as String).trim().isNotEmpty) entry.key: entry.value as String,
  });

  final Map<String, String> _written;

  String textOf(MessageTemplateKind kind) => _written[kind.apiKey] ?? kind.defaultText;

  /// The message with the details filled in. A detail that is not known leaves no gap behind it.
  String render(MessageTemplateKind kind, Map<MessageToken, String> values) => fill(textOf(kind), values);

  static String fill(String template, Map<MessageToken, String> values) {
    var message = template;
    for (final token in MessageToken.values) {
      message = message.replaceAll(token.text, values[token] ?? '');
    }
    return message
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAllMapped(RegExp(r' +([،,.؟!:])'), (match) => match[1]!)
        .replaceAll(RegExp(r'^ +| +$', multiLine: true), '')
        .trim();
  }
}
