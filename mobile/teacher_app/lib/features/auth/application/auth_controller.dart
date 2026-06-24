import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.dart';
import '../data/auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

class AuthBooting extends AuthState {
  const AuthBooting();
}

class Unauthenticated extends AuthState {
  final String? lastMessage;
  const Unauthenticated({this.lastMessage});
}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _bootstrap();
    return const AuthBooting();
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      state = const Unauthenticated();
      return;
    }
    final cached = await storage.readUserJson();
    if (cached != null) {
      try {
        state = Authenticated(AppUser.fromJson(jsonDecode(cached)));
      } catch (_) {
        state = const Unauthenticated();
      }
    } else {
      try {
        final user = await ref.read(authRepositoryProvider).me();
        await storage.writeUserJson(jsonEncode(user.toJson()));
        state = Authenticated(user);
      } catch (_) {
        await storage.clearAll();
        state = const Unauthenticated();
      }
    }
  }

  Future<void> signIn(String username, String password) async {
    final storage = ref.read(secureStorageProvider);
    final result = await ref.read(authRepositoryProvider).login(username, password);
    await storage.writeToken(result.token);
    await storage.writeUserJson(jsonEncode(result.user.toJson()));
    state = Authenticated(result.user);
  }

  Future<void> signOut({String? message}) async {
    await ref.read(secureStorageProvider).clearAll();
    state = Unauthenticated(lastMessage: message);
  }
}
