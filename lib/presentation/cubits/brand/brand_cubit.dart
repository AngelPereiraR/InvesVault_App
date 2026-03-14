import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../data/models/brand_model.dart';
import '../../../data/repositories/brand_repository.dart';

part 'brand_state.dart';

class BrandCubit extends Cubit<BrandState> {
  final BrandRepository _repository;
  FilterParams _currentParams = FilterParams.empty;

  BrandCubit(this._repository) : super(const BrandInitial());

  Future<void> load([FilterParams params = FilterParams.empty]) async {
    _currentParams = params;
    emit(const BrandLoading());
    try {
      final brands = await _repository.getBrands(params);
      emit(BrandLoaded(brands));
    } catch (e) {
      emit(BrandError(friendlyError(e)));
    }
  }

  Future<void> create(String name) async {
    try {
      await _repository.createBrand(name);
      await load(_currentParams);
    } catch (e) {
      emit(BrandError(friendlyError(e)));
    }
  }

  Future<void> update(int id, String name) async {
    try {
      await _repository.updateBrand(id, name);
      await load(_currentParams);
    } catch (e) {
      emit(BrandError(friendlyError(e)));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteBrand(id);
      await load(_currentParams);
    } catch (e) {
      emit(BrandError(friendlyError(e)));
    }
  }

  Future<void> deleteItems(List<int> ids) async {
    emit(const BrandDeleting());
    try {
      for (final id in ids) {
        await _repository.deleteBrand(id);
      }
    } catch (e) {
      emit(BrandError(friendlyError(e)));
      return;
    }
    await load(_currentParams);
  }
}
