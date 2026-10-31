import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/me.dart';

final sessionProvider = AsyncNotifierProvider<SessionController, Me?>(SessionController.new);

/// The signed-in staff member (null when signed out). Restores the session on start-up.
///
/// Sign-in methods throw an ApiProblem on failure and leave the state untouched, so the
/// screen that called them shows the error.
class SessionController extends AsyncNotifier<Me?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<Me?> build() => ref.read(authRepositoryProvider).currentUser();

  Future<void> signIn({required String login, required String password}) async {
    state = AsyncData(await _repository.signIn(login: login, password: password));
  }

  Future<void> pinSignIn({required String userId, required String pin}) async {
    state = AsyncData(await _repository.pinSignIn(userId: userId, pin: pin));
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(null);
  }

  /// The server rejected our token (revoked device, deactivated account): drop the session locally.
  Future<void> expire() async {
    // During start-up, build() itself turns a rejected token into a signed-out state.
    if (state.value == null) {
      return;
    }

    await _repository.forgetSession();
    state = const AsyncData(null);
  }
}
