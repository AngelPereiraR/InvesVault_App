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
  final List<int> updatingProductIds;

  const WarehouseDetailLoaded({
    required this.warehouse,
    required this.products,
    required this.filtered,
    this.query = '',
    this.currentUserRole = 'viewer',
    this.updatingProductIds = const [],
  });

  bool get canEdit => currentUserRole == 'admin' || currentUserRole == 'editor';
  bool get isAdmin => currentUserRole == 'admin';

  WarehouseDetailLoaded copyWith({
    WarehouseModel? warehouse,
    List<WarehouseProductModel>? products,
    List<WarehouseProductModel>? filtered,
    String? query,
    String? currentUserRole,
    List<int>? updatingProductIds,
  }) =>
      WarehouseDetailLoaded(
        warehouse: warehouse ?? this.warehouse,
        products: products ?? this.products,
        filtered: filtered ?? this.filtered,
        query: query ?? this.query,
        currentUserRole: currentUserRole ?? this.currentUserRole,
        updatingProductIds: updatingProductIds ?? this.updatingProductIds,
      );

  @override
  List<Object?> get props => [
        warehouse,
        products,
        filtered,
        query,
        currentUserRole,
        updatingProductIds,
      ];
}

class WarehouseDetailError extends WarehouseDetailState {
  final String message;
  const WarehouseDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
