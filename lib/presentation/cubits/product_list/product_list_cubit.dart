import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

part 'product_list_state.dart';

class ProductListCubit extends Cubit<ProductListState> {
  final ProductRepository _repository;
  ProductListCubit(this._repository) : super(const ProductListInitial());

  Future<void> load() async {
    emit(const ProductListLoading());
    try {
      final products = await _repository.getProducts();
      emit(ProductListLoaded(products));
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteProduct(id);
      await load();
    } catch (e) {
      emit(ProductListError(friendlyError(e)));
    }
  }
}
