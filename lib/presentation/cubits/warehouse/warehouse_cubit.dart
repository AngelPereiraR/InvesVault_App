import 'dart:async';

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
  String _currentSearch = '';
  Timer? _searchDebounce;

  WarehouseCubit(this._repository) : super(const WarehouseInitial());

  FilterParams _effectiveParams({int? page}) => FilterParams(
        search: _currentSearch.isEmpty ? null : _currentSearch,
        limit: _currentParams.limit,
        page: page,
      );

  Future<void> load([FilterParams params = FilterParams.empty]) async {
    _searchDebounce?.cancel();
    _currentSearch = '';
    _currentParams = params;
    emit(const WarehouseLoading());
    try {
      final warehouses = await _repository.getWarehouses(params);
      warehouses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final limit = params.limit ?? 20;
      emit(WarehouseLoaded(
        warehouses,
        hasMore: warehouses.length >= limit,
        currentPage: 1,
      ));
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! WarehouseLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final params = _effectiveParams(page: nextPage);
      final newItems = await _repository.getWarehouses(params);
      newItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final limit = _currentParams.limit ?? 20;
      emit(current.copyWith(
        warehouses: [...current.warehouses, ...newItems],
        hasMore: newItems.length >= limit,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
    }
  }

  Future<void> loadPrevious() async {
    final current = state;
    if (current is! WarehouseLoaded) return;
    if (!current.hasPrevious || current.isLoadingPrevious) return;
    emit(current.copyWith(isLoadingPrevious: true));
    try {
      final prevPage = current.firstPage - 1;
      final params = _effectiveParams(page: prevPage);
      final newItems = await _repository.getWarehouses(params);
      newItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(current.copyWith(
        warehouses: [...newItems, ...current.warehouses],
        firstPage: prevPage,
        isLoadingPrevious: false,
      ));
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _currentSearch = query;
    final current = state;
    if (current is! WarehouseLoaded) return;
    emit(current.copyWith(isSearching: true));
    if (query.isEmpty) {
      _doSearch();
    } else {
      _searchDebounce = Timer(const Duration(milliseconds: 400), _doSearch);
    }
  }

  Future<void> _doSearch() async {
    final current = state;
    if (current is! WarehouseLoaded) return;
    try {
      final results = await _repository.getWarehouses(_effectiveParams(page: 1));
      results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (isClosed) return;
      final latest = state;
      if (latest is! WarehouseLoaded) return;
      final limit = _currentParams.limit ?? 20;
      emit(latest.copyWith(
        warehouses: results,
        hasMore: results.length >= limit,
        currentPage: 1,
        firstPage: 1,
        isSearching: false,
      ));
    } catch (e) {
      if (isClosed) return;
      final latest = state;
      if (latest is WarehouseLoaded) emit(latest.copyWith(isSearching: false));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
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
    final previous = state;
    try {
      await _repository.updateWarehouse(id, data);
      emit(const WarehouseActionSuccess('Almacén actualizado correctamente'));
      // Reload current page only; user can scroll up to recover previous pages
      if (previous is WarehouseLoaded) {
        final params = _currentParams.copyWith(page: previous.currentPage);
        final warehouses = await _repository.getWarehouses(params);
        warehouses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        final limit = _currentParams.limit ?? 20;
        emit(WarehouseLoaded(
          warehouses,
          hasMore: warehouses.length >= limit,
          currentPage: previous.currentPage,
          firstPage: previous.currentPage,
        ));
      } else {
        await load(_currentParams);
      }
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
    }
  }

  Future<void> delete(int id) async {
    final previous = state;
    try {
      await _repository.deleteWarehouse(id);
      emit(const WarehouseActionSuccess('Almacén eliminado correctamente'));
      // Reload current page only; user can scroll up to recover previous pages
      if (previous is WarehouseLoaded) {
        final params = _currentParams.copyWith(page: previous.currentPage);
        final warehouses = await _repository.getWarehouses(params);
        warehouses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        final limit = _currentParams.limit ?? 20;
        emit(WarehouseLoaded(
          warehouses,
          hasMore: warehouses.length >= limit,
          currentPage: previous.currentPage,
          firstPage: previous.currentPage,
        ));
      } else {
        await load(_currentParams);
      }
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
    }
  }

  Future<void> deleteItems(List<int> ids) async {
    final previous = state;
    emit(const WarehouseDeleting());
    try {
      for (final id in ids) {
        await _repository.deleteWarehouse(id);
      }
    } catch (e) {
      emit(WarehouseError(friendlyError(e)));
      return;
    }
    // Reload current page only; user can scroll up to recover previous pages
    if (previous is WarehouseLoaded) {
      final params = _currentParams.copyWith(page: previous.currentPage);
      final warehouses = await _repository.getWarehouses(params);
      warehouses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final limit = _currentParams.limit ?? 20;
      emit(WarehouseLoaded(
        warehouses,
        hasMore: warehouses.length >= limit,
        currentPage: previous.currentPage,
        firstPage: previous.currentPage,
      ));
    } else {
      await load(_currentParams);
    }
  }
}
