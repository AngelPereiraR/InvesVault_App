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
  final bool isLoadingMore;

  const ProductListLoaded(
    this.products, {
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  ProductListLoaded copyWith({
    List<ProductModel>? products,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) =>
      ProductListLoaded(
        products ?? this.products,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [products, hasMore, currentPage, isLoadingMore];
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
