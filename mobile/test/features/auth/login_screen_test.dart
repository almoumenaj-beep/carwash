import 'package:carwash_app/core/network/api_problem.dart';
import 'package:carwash_app/features/auth/data/auth_repository.dart';
import 'package:carwash_app/features/auth/domain/me.dart';
import 'package:carwash_app/features/auth/presentation/login_screen.dart';
import 'package:carwash_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<FakeAuthRepository> pumpLoginScreen(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  testWidgets('asks for both fields before calling the API', (tester) async {
    final repository = await pumpLoginScreen(tester);

    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pump();

    expect(find.text('This field is required'), findsNWidgets(2));
    expect(repository.signInCalls, 0);
  });

  testWidgets('shows the server validation message under the login field', (tester) async {
    final repository = await pumpLoginScreen(tester);
    repository.signInError = const ApiProblem(
      type: 'urn:carwash:problem:validation-failed',
      title: 'The given data was invalid',
      status: 422,
      detail: 'These credentials do not match our records.',
      errors: {
        'login': ['These credentials do not match our records.'],
      },
    );

    await tester.enterText(find.byKey(const Key('login-field')), 'cashier@example.com');
    await tester.enterText(find.byKey(const Key('password-field')), 'wrong');
    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(find.text('These credentials do not match our records.'), findsOneWidget);
  });

  testWidgets('explains when the server cannot be reached', (tester) async {
    final repository = await pumpLoginScreen(tester);
    repository.signInError = const ApiProblem.network();

    await tester.enterText(find.byKey(const Key('login-field')), 'cashier@example.com');
    await tester.enterText(find.byKey(const Key('password-field')), 'password');
    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle();

    expect(find.text('Cannot reach the server. Check your connection and try again.'), findsOneWidget);
  });

  testWidgets('is in Arabic and right-to-left by default locale ar', (tester) async {
    await pumpLoginScreen(tester, locale: const Locale('ar'));

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(LoginScreen))), TextDirection.rtl);
  });
}

class FakeAuthRepository implements AuthRepository {
  ApiProblem? signInError;
  int signInCalls = 0;

  @override
  Future<Me> signIn({required String login, required String password}) async {
    signInCalls++;
    throw signInError ?? const ApiProblem.network();
  }

  @override
  Future<bool> isTrustedDevice() async => false;

  @override
  Future<Me?> currentUser() async => null;

  @override
  Future<List<DeviceStaff>> deviceStaff() async => [];

  @override
  Future<Me> pinSignIn({required String userId, required String pin}) => throw UnimplementedError();

  @override
  Future<void> setPin({required String currentPassword, required String pin}) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> forgetSession() async {}
}
