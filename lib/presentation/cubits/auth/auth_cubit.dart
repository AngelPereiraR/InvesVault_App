import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/storage_service.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  static const _sessionDuration = Duration(days: 7);

  AuthCubit(this._authRepository, this._storageService)
      : super(const AuthInitial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _storageService.getToken();
    if (token == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Inactivity check: expire session after 7 days without opening the app
    final lastActive = await _storageService.getLastActive();
    if (lastActive != null &&
        DateTime.now().difference(lastActive) > _sessionDuration) {
      await _storageService.clearAll();
      emit(const AuthUnauthenticated());
      return;
    }

    final id = await _storageService.getUserId();
    final name = await _storageService.getUserName();
    final email = await _storageService.getUserEmail();
    final role = await _storageService.getUserRole();
    if (id != null && name != null && email != null && role != null) {
      await _storageService.saveLastActive();
      emit(AuthAuthenticated(
          userId: id, name: name, email: email, role: role));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final result =
          await _authRepository.login(email: email, password: password);
      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;
      await _storageService.saveToken(token);
      await _storageService.saveUser(
        id: user['id'] as int,
        name: user['name'] as String,
        email: user['email'] as String,
        role: user['role'] as String,
      );
      await _storageService.saveLastActive();
      emit(AuthAuthenticated(
        userId: user['id'] as int,
        name: user['name'] as String,
        email: user['email'] as String,
        role: user['role'] as String,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.register(
          name: name, email: email, password: password);
      final token = result['token'] as String;
      final user = result['user'] as Map<String, dynamic>;
      await _storageService.saveToken(token);
      await _storageService.saveUser(
        id: user['id'] as int,
        name: user['name'] as String,
        email: user['email'] as String,
        role: user['role'] as String,
      );
      await _storageService.saveLastActive();
      emit(AuthAuthenticated(
        userId: user['id'] as int,
        name: user['name'] as String,
        email: user['email'] as String,
        role: user['role'] as String,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    emit(const AuthUnauthenticated());
  }

  Future<bool> hasSeenWelcome() => _storageService.hasSeenWelcome();
  Future<void> markWelcomeSeen() => _storageService.markWelcomeSeen();

  Future<void> updateUser(Map<String, dynamic> data) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    emit(const AuthLoading());
    try {
      final user =
          await _authRepository.updateUser(currentState.userId, data);
      await _storageService.saveUser(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      );
      emit(AuthAuthenticated(
          userId: user.id,
          name: user.name,
          email: user.email,
          role: user.role));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
