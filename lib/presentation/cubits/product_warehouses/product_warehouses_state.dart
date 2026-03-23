part of 'product_warehouses_cubit.dart';

abstract class ProductWarehousesState extends Equatable {
  const ProductWarehousesState();

  @override
  List<Object?> get props => [];
}

class ProductWarehousesInitial extends ProductWarehousesState {
  const ProductWarehousesInitial();
}

class ProductWarehousesLoading extends ProductWarehousesState {
  const ProductWarehousesLoading();
}

class ProductWarehousesLoaded extends ProductWarehousesState {
  final List<WarehouseProductModel> items;
  const ProductWarehousesLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class ProductWarehousesError extends ProductWarehousesState {
  final String message;
  const ProductWarehousesError(this.message);

  @override
  List<Object?> get props => [message];
}
