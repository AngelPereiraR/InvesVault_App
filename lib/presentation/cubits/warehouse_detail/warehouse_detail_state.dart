part of 'warehouse_detail_cubit.dart';

abstract class WarehouseDetailState extends Equatable {
  const WarehouseDetailState();

  @override
  List<Object?> get props => [];
}

class WarehouseDetailInitial extends WarehouseDetailState {
  const WarehouseDetailInitial();
}

class WarehouseDetailLoading extends WarehouseDetailState {
  const WarehouseDetailLoading();
}

class WarehouseDetailLoaded extends WarehouseDetailState {
  final WarehouseModel warehouse;
  final List<WarehouseProductModel> products;
  final List<WarehouseProductModel> filtered;
  final String query;

  const WarehouseDetailLoaded({
    required this.warehouse,
    required this.products,
    required this.filtered,
    this.query = '',
  });

  WarehouseDetailLoaded copyWith({
    WarehouseModel? warehouse,
    List<WarehouseProductModel>? products,
    List<WarehouseProductModel>? filtered,
    String? query,
  }) =>
      WarehouseDetailLoaded(
        warehouse: warehouse ?? this.warehouse,
        products: products ?? this.products,
        filtered: filtered ?? this.filtered,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [warehouse, products, filtered, query];
}

class WarehouseDetailError extends WarehouseDetailState {
  final String message;
  const WarehouseDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
