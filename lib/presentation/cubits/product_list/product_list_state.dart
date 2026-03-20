part of 'product_list_cubit.dart';

abstract class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object?> get props => [];
}

class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

class ProductListLoaded extends ProductListState {
  final List<ProductModel> products;
  final bool hasMore;
  final int currentPage;
  final int firstPage;
  final bool isLoadingMore;
  final bool isLoadingPrevious;
  final bool isRefreshing;
  final bool isSearching;

  bool get hasPrevious => firstPage > 1;

  const ProductListLoaded(
    this.products, {
    this.hasMore = false,
    this.currentPage = 1,
    this.firstPage = 1,
    this.isLoadingMore = false,
    this.isLoadingPrevious = false,
    this.isRefreshing = false,
    this.isSearching = false,
  });

  ProductListLoaded copyWith({
    List<ProductModel>? products,
    bool? hasMore,
    int? currentPage,
    int? firstPage,
    bool? isLoadingMore,
    bool? isLoadingPrevious,
    bool? isRefreshing,
    bool? isSearching,
  }) =>
      ProductListLoaded(
        products ?? this.products,
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
        products,
        hasMore,
        currentPage,
        firstPage,
        isLoadingMore,
        isLoadingPrevious,
        isRefreshing,
        isSearching,
      ];
}

class ProductListDeleting extends ProductListState {
  const ProductListDeleting();
}

class ProductListError extends ProductListState {
  final String message;
  const ProductListError(this.message);

  @override
  List<Object?> get props => [message];
}
