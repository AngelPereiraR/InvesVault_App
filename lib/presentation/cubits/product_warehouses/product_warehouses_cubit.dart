import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_messages.dart';
import '../../../data/models/warehouse_product_model.dart';
import '../../../data/repositories/warehouse_product_repository.dart';

part 'product_warehouses_state.dart';

class ProductWarehousesCubit extends Cubit<ProductWarehousesState> {
  final WarehouseProductRepository _repository;

  ProductWarehousesCubit(this._repository)
      : super(const ProductWarehousesInitial());

  Future<void> load(int productId) async {
    emit(const ProductWarehousesLoading());
    try {
      final items = await _repository.getWarehousesByProduct(productId);
      emit(ProductWarehousesLoaded(items));
    } catch (e) {
      emit(ProductWarehousesError(friendlyError(e)));
    }
  }
}
