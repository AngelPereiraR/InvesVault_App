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

  final bool isDeleting;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const WarehouseDetailLoaded({
    required this.warehouse,
    required this.products,
    required this.filtered,
    this.query = '',
    this.currentUserRole = 'viewer',
    this.updatingProductIds = const [],
    this.isDeleting = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
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
    bool? isDeleting,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) =>
      WarehouseDetailLoaded(
        warehouse: warehouse ?? this.warehouse,
        products: products ?? this.products,
        filtered: filtered ?? this.filtered,
        query: query ?? this.query,
        currentUserRole: currentUserRole ?? this.currentUserRole,
        updatingProductIds: updatingProductIds ?? this.updatingProductIds,
        isDeleting: isDeleting ?? this.isDeleting,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [
        warehouse,
        products,
        filtered,
        query,
        currentUserRole,
        updatingProductIds,
        isDeleting,
        hasMore,
        currentPage,
        isLoadingMore,
      ];
}

class WarehouseDetailError extends WarehouseDetailState {
  final String message;
  const WarehouseDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
