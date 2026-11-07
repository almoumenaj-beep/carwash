import 'package:carwash_app/features/settings/domain/message_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the owner\'s wording is filled in with the customer\'s details', () {
    final templates = MessageTemplates.fromJson({'ready': 'هلا {الاسم}، سيارتك {اللوحة} جاهزة. نشوفك في {المغسلة}'});

    expect(
      templates.render(MessageTemplateKind.ready, {
        MessageToken.name: 'حسين',
        MessageToken.plate: '73674',
        MessageToken.carWash: 'مغسلة النور',
      }),
      'هلا حسين، سيارتك 73674 جاهزة. نشوفك في مغسلة النور',
    );
  });

  test('a message the owner did not write, or left empty, uses its default text', () {
    final templates = MessageTemplates.fromJson({'greeting': '   ', 'ready': null});

    expect(templates.textOf(MessageTemplateKind.greeting), MessageTemplateKind.greeting.defaultText);
    expect(templates.textOf(MessageTemplateKind.ready), MessageTemplateKind.ready.defaultText);
    expect(
      MessageTemplates.fromJson(null).textOf(MessageTemplateKind.reminder),
      MessageTemplateKind.reminder.defaultText,
    );
  });

  test('a detail that is not known leaves no gap', () {
    expect(
      const MessageTemplates().render(MessageTemplateKind.ready, {MessageToken.plate: '12345'}),
      'مرحباً، سيارتك 12345 جاهزة للاستلام.',
    );
  });

  test('line breaks the owner wrote are kept', () {
    expect(MessageTemplates.fill('أهلاً {الاسم}\nشكراً لك', {MessageToken.name: 'علي'}), 'أهلاً علي\nشكراً لك');
  });
}
