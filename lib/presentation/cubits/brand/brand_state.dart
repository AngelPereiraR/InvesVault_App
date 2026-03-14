part of 'brand_cubit.dart';

abstract class BrandState extends Equatable {
  const BrandState();

  @override
  List<Object?> get props => [];
}

class BrandInitial extends BrandState {
  const BrandInitial();
}

class BrandLoading extends BrandState {
  const BrandLoading();
}

class BrandLoaded extends BrandState {
  final List<BrandModel> brands;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const BrandLoaded(
    this.brands, {
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  BrandLoaded copyWith({
    List<BrandModel>? brands,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) =>
      BrandLoaded(
        brands ?? this.brands,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [brands, hasMore, currentPage, isLoadingMore];
}

class BrandDeleting extends BrandState {
  const BrandDeleting();
}

class BrandError extends BrandState {
  final String message;
  const BrandError(this.message);

  @override
  List<Object?> get props => [message];
}
