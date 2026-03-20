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
  final int firstPage;
  final bool isLoadingMore;
  final bool isLoadingPrevious;
  final bool isRefreshing;
  final bool isSearching;

  bool get hasPrevious => firstPage > 1;

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
    this.firstPage = 1,
    this.isLoadingMore = false,
    this.isLoadingPrevious = false,
    this.isRefreshing = false,
    this.isSearching = false,
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
    int? firstPage,
    bool? isLoadingMore,
    bool? isLoadingPrevious,
    bool? isRefreshing,
    bool? isSearching,
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
        firstPage: firstPage ?? this.firstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isLoadingPrevious: isLoadingPrevious ?? this.isLoadingPrevious,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isSearching: isSearching ?? this.isSearching,
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
        firstPage,
        isLoadingMore,
        isLoadingPrevious,
        isRefreshing,
        isSearching,
      ];
}

class WarehouseDetailError extends WarehouseDetailState {
  final String message;
  const WarehouseDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
