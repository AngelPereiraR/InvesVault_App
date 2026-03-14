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
      emit(StoreLoaded(stores));
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
