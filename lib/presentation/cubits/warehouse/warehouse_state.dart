part of 'warehouse_cubit.dart';

abstract class WarehouseState extends Equatable {
  const WarehouseState();

  @override
  List<Object?> get props => [];
}

class WarehouseInitial extends WarehouseState {
  const WarehouseInitial();
}

class WarehouseLoading extends WarehouseState {
  const WarehouseLoading();
}

class WarehouseLoaded extends WarehouseState {
  final List<WarehouseModel> warehouses;
  final bool hasMore;
  final int currentPage;
  final int firstPage;
  final bool isLoadingMore;
  final bool isLoadingPrevious;
  final bool isSearching;

  bool get hasPrevious => firstPage > 1;

  const WarehouseLoaded(
    this.warehouses, {
    this.hasMore = false,
    this.currentPage = 1,
    this.firstPage = 1,
    this.isLoadingMore = false,
    this.isLoadingPrevious = false,
    this.isSearching = false,
  });

  WarehouseLoaded copyWith({
    List<WarehouseModel>? warehouses,
    bool? hasMore,
    int? currentPage,
    int? firstPage,
    bool? isLoadingMore,
    bool? isLoadingPrevious,
    bool? isSearching,
  }) =>
      WarehouseLoaded(
        warehouses ?? this.warehouses,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        firstPage: firstPage ?? this.firstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isLoadingPrevious: isLoadingPrevious ?? this.isLoadingPrevious,
        isSearching: isSearching ?? this.isSearching,
      );

  @override
  List<Object?> get props => [
        warehouses,
        hasMore,
        currentPage,
        firstPage,
        isLoadingMore,
        isLoadingPrevious,
        isSearching,
      ];
}

class WarehouseError extends WarehouseState {
  final String message;
  const WarehouseError(this.message);

  @override
  List<Object?> get props => [message];
}

class WarehouseActionSuccess extends WarehouseState {
  final String message;
  const WarehouseActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class WarehouseDeleting extends WarehouseState {
  const WarehouseDeleting();
}

class WarehouseCreated extends WarehouseState {
  final WarehouseModel warehouse;
  const WarehouseCreated(this.warehouse);

  @override
  List<Object?> get props => [warehouse];
}
