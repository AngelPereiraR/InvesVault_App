import 'dart:async';

import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

part 'product_list_state.dart';

class ProductListCubit extends Cubit<ProductListState> {
  final ProductRepository _repository;
  FilterParams _currentParams = FilterParams.empty;
  String _currentSearch = '';
  Timer? _searchDebounce;

  ProductListCubit(this._repository) : super(const ProductListInitial());

  FilterParams _effectiveParams({int? page}) => FilterParams(
        search: _currentSearch.isEmpty ? null : _currentSearch,
        limit: _currentParams.limit,
        page: page,
      );

  Future<void> load([FilterParams params = FilterParams.empty]) async {
    _searchDebounce?.cancel();
    _currentSearch = '';
    _currentParams = params;
    emit(const ProductListLoading());
    try {
      final products = await _repository.getProducts(params);
      final limit = params.limit ?? 20;
      emit(ProductListLoaded(
        products,
        hasMore: products.length >= limit,
        currentPage: 1,
      ));
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ProductListLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final params = _effectiveParams(page: nextPage);
      final newItems = await _repository.getProducts(params);
      final limit = _currentParams.limit ?? 20;
      emit(current.copyWith(
        products: [...current.products, ...newItems],
        hasMore: newItems.length >= limit,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
    }
  }

  Future<void> loadPrevious() async {
    final current = state;
    if (current is! ProductListLoaded) return;
    if (!current.hasPrevious || current.isLoadingPrevious) return;
    emit(current.copyWith(isLoadingPrevious: true));
    try {
      final prevPage = current.firstPage - 1;
      final params = _effectiveParams(page: prevPage);
      final newItems = await _repository.getProducts(params);
      emit(current.copyWith(
        products: [...newItems, ...current.products],
        firstPage: prevPage,
        isLoadingPrevious: false,
      ));
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _currentSearch = query;
    final current = state;
    if (current is! ProductListLoaded) return;
    emit(current.copyWith(isSearching: true));
    if (query.isEmpty) {
      _doSearch();
    } else {
      _searchDebounce = Timer(const Duration(milliseconds: 400), _doSearch);
    }
  }

  Future<void> _doSearch() async {
    final current = state;
    if (current is! ProductListLoaded) return;
    try {
      final results = await _repository.getProducts(_effectiveParams(page: 1));
      if (isClosed) return;
      final latest = state;
      if (latest is! ProductListLoaded) return;
      final limit = _currentParams.limit ?? 20;
      emit(latest.copyWith(
        products: results,
        hasMore: results.length >= limit,
        currentPage: 1,
        firstPage: 1,
        isSearching: false,
      ));
    } catch (e) {
      if (isClosed) return;
      final latest = state;
      if (latest is ProductListLoaded) emit(latest.copyWith(isSearching: false));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  /// Refreshes data while maintaining scroll position by reloading all pages up to current.
  Future<void> refresh() async {
    final current = state;
    if (current is! ProductListLoaded) {
      load(_currentParams);
      return;
    }
    if (current.isRefreshing) return;

    emit(current.copyWith(isRefreshing: true));
    try {
      // Reload all pages from 1 to currentPage
      final allProducts = <ProductModel>[];
      for (int page = 1; page <= current.currentPage; page++) {
        final params = _effectiveParams(page: page);
        final pageItems = await _repository.getProducts(params);
        allProducts.addAll(pageItems);
      }

      final limit = _currentParams.limit ?? 20;
      final hasMore = allProducts.length >= (current.currentPage * limit);

      emit(current.copyWith(
        products: allProducts,
        hasMore: hasMore,
        firstPage: 1,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
    }
  }

  Future<void> delete(int id) async {
    final current = state;
    if (current is! ProductListLoaded) {
      await load(_currentParams);
      return;
    }
    try {
      await _repository.deleteProduct(id);
      // Reload current page only; user can scroll up to recover previous pages
      final params = _currentParams.copyWith(page: current.currentPage);
      final products = await _repository.getProducts(params);
      final limit = _currentParams.limit ?? 20;
      final hasMore = products.length >= limit;
      emit(ProductListLoaded(
        products,
        hasMore: hasMore,
        currentPage: current.currentPage,
        firstPage: current.currentPage,
      ));
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
    }
  }

  Future<void> deleteItems(List<int> ids) async {
    final current = state;
    if (current is! ProductListLoaded) {
      emit(const ProductListDeleting());
      try {
        for (final id in ids) {
          await _repository.deleteProduct(id);
        }
      } catch (e) {
        emit(ProductListError(friendlyError(e)));
        return;
      }
      await load(_currentParams);
      return;
    }

    emit(const ProductListDeleting());
    try {
      for (final id in ids) {
        await _repository.deleteProduct(id);
      }
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
      return;
    }
    // Reload current page only; user can scroll up to recover previous pages
    final params = _currentParams.copyWith(page: current.currentPage);
    final products = await _repository.getProducts(params);
    final limit = _currentParams.limit ?? 20;
    final hasMore = products.length >= limit;
    emit(ProductListLoaded(
      products,
      hasMore: hasMore,
      currentPage: current.currentPage,
      firstPage: current.currentPage,
    ));
  }
}
