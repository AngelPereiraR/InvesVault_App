import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../data/models/store_model.dart';
import '../../../data/repositories/store_repository.dart';

part 'store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _repository;
  FilterParams _currentParams = FilterParams.empty;

  StoreCubit(this._repository) : super(const StoreInitial());

  Future<void> load([FilterParams params = FilterParams.empty]) async {
    _currentParams = params;
    emit(const StoreLoading());
    try {
      final stores = await _repository.getStores(params);
      final limit = params.limit ?? 20;
      emit(StoreLoaded(
        stores,
        hasMore: stores.length >= limit,
        currentPage: 1,
      ));
    } catch (e) {
      emit(StoreError(friendlyError(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! StoreLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final params = _currentParams.copyWith(page: nextPage);
      final newItems = await _repository.getStores(params);
      final limit = _currentParams.limit ?? 20;
      emit(current.copyWith(
        stores: [...current.stores, ...newItems],
        hasMore: newItems.length >= limit,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(StoreError(friendlyError(e)));
    }
  }

  Future<void> create({required String name, String? location}) async {
    try {
      await _repository.createStore(name: name, location: location);
      await load(_currentParams);
    } catch (e) {
      emit(StoreError(friendlyError(e)));
    }
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateStore(id, data);
      await load(_currentParams);
    } catch (e) {
      emit(StoreError(friendlyError(e)));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteStore(id);
      await load(_currentParams);
    } catch (e) {
      emit(StoreError(friendlyError(e)));
    }
  }

  Future<void> deleteItems(List<int> ids) async {
    emit(const StoreDeleting());
    try {
      for (final id in ids) {
        await _repository.deleteStore(id);
      }
    } catch (e) {
      emit(StoreError(friendlyError(e)));
      return;
    }
    await load(_currentParams);
  }
}
