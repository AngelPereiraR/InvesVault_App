import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/warehouse_model.dart';
import '../../../data/repositories/warehouse_repository.dart';

part 'warehouse_state.dart';

class WarehouseCubit extends Cubit<WarehouseState> {
  final WarehouseRepository _repository;
  WarehouseCubit(this._repository) : super(const WarehouseInitial());

  Future<void> load() async {
    emit(const WarehouseLoading());
    try {
      final warehouses = await _repository.getWarehouses();
      emit(WarehouseLoaded(warehouses));
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }

  Future<void> create({
    required String name,
    required int ownerId,
    bool isShared = false,
  }) async {
    try {
      final warehouse = await _repository.createWarehouse(
          name: name, ownerId: ownerId, isShared: isShared);
      emit(WarehouseCreated(warehouse));
      await load();
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateWarehouse(id, data);
      emit(const WarehouseActionSuccess('Almacén actualizado correctamente'));
      await load();
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteWarehouse(id);
      emit(const WarehouseActionSuccess('Almacén eliminado correctamente'));
      await load();
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }
}
