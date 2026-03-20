part of 'store_cubit.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

class StoreInitial extends StoreState {
  const StoreInitial();
}

class StoreLoading extends StoreState {
  const StoreLoading();
}

class StoreLoaded extends StoreState {
  final List<StoreModel> stores;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final bool isSearching;

  const StoreLoaded(
    this.stores, {
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.isSearching = false,
  });

  StoreLoaded copyWith({
    List<StoreModel>? stores,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    bool? isSearching,
  }) =>
      StoreLoaded(
        stores ?? this.stores,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isSearching: isSearching ?? this.isSearching,
      );

  @override
  List<Object?> get props => [stores, hasMore, currentPage, isLoadingMore, isSearching];
}

class StoreDeleting extends StoreState {
  const StoreDeleting();
}

class StoreError extends StoreState {
  final String message;
  const StoreError(this.message);

  @override
  List<Object?> get props => [message];
}
