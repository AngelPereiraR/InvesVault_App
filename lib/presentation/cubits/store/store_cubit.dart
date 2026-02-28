import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/store_model.dart';
import '../../../data/repositories/store_repository.dart';

part 'store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _repository;
  StoreCubit(this._repository) : super(const StoreInitial());

  Future<void> load() async {
    emit(const StoreLoading());
    try {
      final stores = await _repository.getStores();
      emit(StoreLoaded(stores));
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  Future<void> create({required String name, String? location}) async {
    try {
      await _repository.createStore(name: name, location: location);
      await load();
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateStore(id, data);
      await load();
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteStore(id);
      await load();
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }
}
