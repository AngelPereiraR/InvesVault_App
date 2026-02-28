part of 'product_detail_cubit.dart';

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

class ProductDetailLoaded extends ProductDetailState {
  final WarehouseProductModel warehouseProduct;
  const ProductDetailLoaded(this.warehouseProduct);

  @override
  List<Object?> get props => [warehouseProduct];
}

class ProductDetailUpdating extends ProductDetailState {
  final WarehouseProductModel warehouseProduct;
  const ProductDetailUpdating(this.warehouseProduct);

  @override
  List<Object?> get props => [warehouseProduct];
}

class ProductDetailError extends ProductDetailState {
  final String message;
  const ProductDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
