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

  ProductListCubit(this._repository) : super(const ProductListInitial());

  Future<void> load([FilterParams params = FilterParams.empty]) async {
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
      final params = _currentParams.copyWith(page: nextPage);
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

  Future<void> delete(int id) async {
    try {
      await _repository.deleteProduct(id);
      await load(_currentParams);
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
    }
  }

  Future<void> deleteItems(List<int> ids) async {
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
  }
}
