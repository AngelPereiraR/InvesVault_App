import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/shopping_list_item_model.dart';
import '../../../data/repositories/shopping_list_repository.dart';

part 'shopping_list_state.dart';

class ShoppingListCubit extends Cubit<ShoppingListState> {
  final ShoppingListRepository _repository;
  ShoppingListCubit(this._repository) : super(const ShoppingListInitial());

  // Track current load mode so reload operations stay consistent
  bool _globalMode = false;

  // ── Persisted UI state (survives screen navigations) ──────────────────────
  int? storeFilter;
  int? selectedWarehouseId;
  final Map<int, int> stPlanned = {};
  final Map<int, int> stBuyQty = {};
  final Set<int> stChecked = {};
  final Map<int, int> whPlanned = {};
  final Map<int, int> whBuyQty = {};
  final Set<int> whChecked = {};

  Future<void> load(int warehouseId) async {
    _globalMode = false;
    emit(const ShoppingListLoading());
    try {
      final items = await _repository.getList(warehouseId);
      emit(ShoppingListLoaded(items));
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }

  Future<void> loadAll() async {
    _globalMode = true;
    emit(const ShoppingListLoading());
    try {
      final items = await _repository.getAllItems();
      emit(ShoppingListLoaded(items));
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }

  Future<void> _reload(int warehouseId) async {
    if (_globalMode) {
      await loadAll();
    } else {
      await load(warehouseId);
    }
  }

  Future<void> generateAll() async {
    _globalMode = true;
    emit(const ShoppingListLoading());
    try {
      final items = await _repository.generateAll();
      emit(ShoppingListLoaded(items));
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }

  Future<void> generate(int warehouseId) async {
    _globalMode = false;
    emit(const ShoppingListLoading());
    try {
      final items = await _repository.generate(warehouseId);
      emit(ShoppingListLoaded(items));
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }

  Future<void> addItem(int warehouseId, int productId, double qty) async {
    try {
      final items = await _repository.addItem(warehouseId, productId, qty);
      if (_globalMode) {
        await loadAll();
      } else {
        emit(ShoppingListLoaded(items));
      }
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }

  Future<void> updateItem(
      int id, double newQty, int warehouseId) async {
    try {
      final items = await _repository.updateItem(id, newQty);
      if (_globalMode) {
        // updateItem returns only the warehouse's list — reload all so global view is fresh
        await loadAll();
      } else {
        emit(ShoppingListLoaded(items));
      }
    } catch (e) {
      await _reload(warehouseId);
    }
  }

  Future<void> removeItem(int id, int warehouseId) async {
    try {
      await _repository.removeItem(id);
      await _reload(warehouseId);
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }

  /// Persists the planned quantity to the backend without triggering a reload.
  /// Called debounced after every +/- tap so all users see the updated qty.
  Future<void> saveItemQty(int id, double newQty) async {
    try {
      await _repository.updateItem(id, newQty);
    } catch (_) {
      // Silent — the user's local value is already shown; next full load will reconcile
    }
  }

  Future<void> clearList(int warehouseId) async {
    emit(const ShoppingListLoading());
    try {
      await _repository.clearList(warehouseId);
      emit(const ShoppingListLoaded([]));
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }
}
