import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/shopping_list_item_model.dart';
import '../../../data/repositories/shopping_list_repository.dart';

part 'shopping_list_state.dart';

class ShoppingListCubit extends Cubit<ShoppingListState> {
  final ShoppingListRepository _repository;
  ShoppingListCubit(this._repository) : super(const ShoppingListInitial());

  Future<void> load(int warehouseId) async {
    emit(const ShoppingListLoading());
    try {
      final items = await _repository.getList(warehouseId);
      emit(ShoppingListLoaded(items));
    } catch (e) {
      emit(ShoppingListError(e.toString()));
    }
  }

  Future<void> generate(int warehouseId) async {
    emit(const ShoppingListLoading());
    try {
      final items = await _repository.generate(warehouseId);
      emit(ShoppingListLoaded(items));
    } catch (e) {
      emit(ShoppingListError(e.toString()));
    }
  }

  Future<void> addItem(int warehouseId, int productId, double qty) async {
    try {
      await _repository.addItem(warehouseId, productId, qty);
      await load(warehouseId);
    } catch (e) {
      emit(ShoppingListError(e.toString()));
    }
  }

  Future<void> removeItem(int id, int warehouseId) async {
    try {
      await _repository.removeItem(id);
      await load(warehouseId);
    } catch (e) {
      emit(ShoppingListError(e.toString()));
    }
  }

  Future<void> clearList(int warehouseId) async {
    emit(const ShoppingListLoading());
    try {
      await _repository.clearList(warehouseId);
      emit(const ShoppingListLoaded([]));
    } catch (e) {
      emit(ShoppingListError(e.toString()));
    }
  }
}
