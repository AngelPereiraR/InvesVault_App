import 'dart:async';

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
  String _currentSearch = '';
  Timer? _searchDebounce;

  BrandCubit(this._repository) : super(const BrandInitial());

  FilterParams _effectiveParams({int? page}) => FilterParams(
        search: _currentSearch.isEmpty ? null : _currentSearch,
        limit: _currentParams.limit,
        page: page,
      );

  Future<void> load([FilterParams params = FilterParams.empty]) async {
    _searchDebounce?.cancel();
    _currentSearch = '';
    _currentParams = params;
    emit(const BrandLoading());
    try {
      final brands = await _repository.getBrands(params);
      final limit = params.limit ?? 20;
      emit(BrandLoaded(
        brands,
        hasMore: brands.length >= limit,
        currentPage: 1,
      ));
    } catch (e) {
      emit(BrandError(friendlyError(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! BrandLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final params = _effectiveParams(page: nextPage);
      final newItems = await _repository.getBrands(params);
      final limit = _currentParams.limit ?? 20;
      emit(current.copyWith(
        brands: [...current.brands, ...newItems],
        hasMore: newItems.length >= limit,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(BrandError(friendlyError(e)));
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _currentSearch = query;
    final current = state;
    if (current is! BrandLoaded) return;
    emit(current.copyWith(isSearching: true));
    if (query.isEmpty) {
      _doSearch();
    } else {
      _searchDebounce = Timer(const Duration(milliseconds: 400), _doSearch);
    }
  }

  Future<void> _doSearch() async {
    final current = state;
    if (current is! BrandLoaded) return;
    try {
      final results = await _repository.getBrands(_effectiveParams(page: 1));
      if (isClosed) return;
      final latest = state;
      if (latest is! BrandLoaded) return;
      final limit = _currentParams.limit ?? 20;
      emit(latest.copyWith(
        brands: results,
        hasMore: results.length >= limit,
        currentPage: 1,
        isSearching: false,
      ));
    } catch (e) {
      if (isClosed) return;
      final latest = state;
      if (latest is BrandLoaded) emit(latest.copyWith(isSearching: false));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
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
