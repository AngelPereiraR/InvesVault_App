part of 'stock_change_cubit.dart';

abstract class StockChangeState extends Equatable {
  const StockChangeState();

  @override
  List<Object?> get props => [];
}

class StockChangeInitial extends StockChangeState {
  const StockChangeInitial();
}

class StockChangeLoading extends StockChangeState {
  const StockChangeLoading();
}

class StockChangeLoaded extends StockChangeState {
  final List<StockChangeModel> changes;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const StockChangeLoaded(
    this.changes, {
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  StockChangeLoaded copyWith({
    List<StockChangeModel>? changes,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) =>
      StockChangeLoaded(
        changes ?? this.changes,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [changes, hasMore, currentPage, isLoadingMore];
}

class StockChangeError extends StockChangeState {
  final String message;
  const StockChangeError(this.message);

  @override
  List<Object?> get props => [message];
}
