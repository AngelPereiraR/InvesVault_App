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
  final String currentUserRole; // 'admin', 'editor', 'viewer'

  const WarehouseDetailLoaded({
    required this.warehouse,
    required this.products,
    required this.filtered,
    this.query = '',
    this.currentUserRole = 'viewer',
  });

  bool get canEdit => currentUserRole == 'admin' || currentUserRole == 'editor';
  bool get isAdmin => currentUserRole == 'admin';

  WarehouseDetailLoaded copyWith({
    WarehouseModel? warehouse,
    List<WarehouseProductModel>? products,
    List<WarehouseProductModel>? filtered,
    String? query,
    String? currentUserRole,
  }) =>
      WarehouseDetailLoaded(
        warehouse: warehouse ?? this.warehouse,
        products: products ?? this.products,
        filtered: filtered ?? this.filtered,
        query: query ?? this.query,
        currentUserRole: currentUserRole ?? this.currentUserRole,
      );

  @override
  List<Object?> get props => [warehouse, products, filtered, query, currentUserRole];
}

class WarehouseDetailError extends WarehouseDetailState {
  final String message;
  const WarehouseDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
