import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/warehouse_user_model.dart';
import '../../../data/repositories/warehouse_user_repository.dart';

part 'warehouse_user_state.dart';

class WarehouseUserCubit extends Cubit<WarehouseUserState> {
  final WarehouseUserRepository _repository;

  WarehouseUserCubit(this._repository) : super(const WarehouseUserInitial());

  Future<void> load(int warehouseId) async {
    emit(const WarehouseUserLoading());
    try {
      final users = await _repository.getUsers(warehouseId);
      emit(WarehouseUserLoaded(users));
    } catch (e) {
      emit(WarehouseUserError(e.toString()));
    }
  }

  Future<void> addUserByEmail(
      int warehouseId, String email, String role) async {
    final current = state;
    if (current is! WarehouseUserLoaded) {
      debugPrint('[WarehouseUserCubit] addUserByEmail blocked: state is ${state.runtimeType}');
      return;
    }
    debugPrint('[WarehouseUserCubit] addUserByEmail warehouseId=$warehouseId email=$email role=$role');
    emit(current.copyWith(isAdding: true, clearAddError: true));
    try {
      await _repository.addUserByEmail(warehouseId, email, role);
      emit(const WarehouseUserActionSuccess('Usuario añadido correctamente'));
      await load(warehouseId);
    } on DioException catch (e) {
      debugPrint('[WarehouseUserCubit] DioException status=${e.response?.statusCode} data=${e.response?.data}');
      final msg = e.response?.data?['message'] as String? ??
          e.response?.data?.toString() ??
          'Error al añadir usuario (${e.response?.statusCode})';
      emit(current.copyWith(isAdding: false, addError: msg));
    } catch (e) {
      debugPrint('[WarehouseUserCubit] Exception: $e');
      emit(current.copyWith(isAdding: false, addError: e.toString()));
    }
  }

  Future<void> addUser(
      int warehouseId, int userId, String role) async {
    try {
      await _repository.addUser(warehouseId, userId, role);
      emit(const WarehouseUserActionSuccess('Usuario añadido correctamente'));
      await load(warehouseId);
    } catch (e) {
      emit(WarehouseUserError(e.toString()));
    }
  }

  Future<void> updateRole(
      int warehouseId, int userId, String role) async {
    try {
      await _repository.updateRole(warehouseId, userId, role);
      emit(const WarehouseUserActionSuccess('Rol actualizado correctamente'));
      await load(warehouseId);
    } catch (e) {
      emit(WarehouseUserError(e.toString()));
    }
  }

  Future<void> removeUser(int warehouseId, int userId) async {
    try {
      await _repository.removeUser(warehouseId, userId);
      emit(const WarehouseUserActionSuccess('Usuario eliminado correctamente'));
      await load(warehouseId);
    } catch (e) {
      emit(WarehouseUserError(e.toString()));
    }
  }
}
