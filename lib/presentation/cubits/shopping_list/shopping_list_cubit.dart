import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../data/models/shopping_list_item_model.dart';
import '../../../data/repositories/shopping_list_repository.dart';

part 'shopping_list_state.dart';

enum ShoppingListSortOrder { alphabetical, byCategory }

class ShoppingListCubit extends Cubit<ShoppingListState> {
  final ShoppingListRepository _repository;
  ShoppingListCubit(this._repository) : super(const ShoppingListInitial());

  // Track current load mode so reload operations stay consistent
  bool _globalMode = false;
  FilterParams _currentParams = FilterParams.empty;

  // ── Persisted UI state (survives screen navigations) ──────────────────────
  int? storeFilter;
  int? selectedWarehouseId;
  ShoppingListSortOrder sortOrder = ShoppingListSortOrder.alphabetical;
  final Map<int, int> stPlanned = {};
  final Map<int, int> stBuyQty = {};
  final Set<int> stChecked = {};
  final Map<int, int> whPlanned = {};
  final Map<int, int> whBuyQty = {};
  final Set<int> whChecked = {};

  Future<void> load(int warehouseId, [FilterParams params = FilterParams.empty]) async {
    _globalMode = false;
    _currentParams = params;
    emit(const ShoppingListLoading());
    try {
      final items = await _repository.getList(warehouseId, params);
      emit(ShoppingListLoaded(items));
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }

  Future<void> loadAll([FilterParams params = FilterParams.empty]) async {
    _globalMode = true;
    _currentParams = params;
    emit(const ShoppingListLoading());
    try {
      final items = await _repository.getAllItems(params);
      emit(ShoppingListLoaded(items));
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
    }
  }

  Future<void> _reload(int warehouseId) async {
    if (_globalMode) {
      await loadAll(_currentParams);
    } else {
      await load(warehouseId, _currentParams);
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
        await loadAll(_currentParams);
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
        await loadAll(_currentParams);
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

  /// Deletes a batch of items sequentially and does a single reload at the end.
  /// Runs entirely in the cubit so navigation away from the screen does not
  /// interrupt the process.
  Future<void> deleteItems(
      List<({int id, int warehouseId})> items) async {
    emit(const ShoppingListDeleting());
    try {
      for (final item in items) {
        // Clean persisted UI state for each deleted id
        stPlanned.remove(item.id);
        stBuyQty.remove(item.id);
        stChecked.remove(item.id);
        whPlanned.remove(item.id);
        whBuyQty.remove(item.id);
        whChecked.remove(item.id);
        await _repository.removeItem(item.id);
      }
    } catch (e) {
      emit(ShoppingListError(friendlyError(e)));
      return;
    }
    // Single reload after all deletions
    if (_globalMode) {
      await loadAll(_currentParams);
    } else if (items.isNotEmpty) {
      await load(items.first.warehouseId, _currentParams);
    } else {
      emit(const ShoppingListLoaded([]));
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
