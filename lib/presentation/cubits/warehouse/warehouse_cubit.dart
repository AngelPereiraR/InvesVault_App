import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../data/models/warehouse_model.dart';
import '../../../data/repositories/warehouse_repository.dart';

part 'warehouse_state.dart';

class WarehouseCubit extends Cubit<WarehouseState> {
  final WarehouseRepository _repository;
  FilterParams _currentParams = FilterParams.empty;

  WarehouseCubit(this._repository) : super(const WarehouseInitial());

  Future<void> load([FilterParams params = FilterParams.empty]) async {
    _currentParams = params;
    emit(const WarehouseLoading());
    try {
      final warehouses = await _repository.getWarehouses(params);
      warehouses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(WarehouseLoaded(warehouses));
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
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
      await load(_currentParams);
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
    }
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateWarehouse(id, data);
      emit(const WarehouseActionSuccess('Almacén actualizado correctamente'));
      await load(_currentParams);
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteWarehouse(id);
      emit(const WarehouseActionSuccess('Almacén eliminado correctamente'));
      await load(_currentParams);
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
    }
  }

  Future<void> deleteItems(List<int> ids) async {
    emit(const WarehouseDeleting());
    try {
      for (final id in ids) {
        await _repository.deleteWarehouse(id);
      }
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
      return;
    }
    await load(_currentParams);
  }
}
