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
  const StockChangeLoaded(this.changes);

  @override
  List<Object?> get props => [changes];
}

class StockChangeError extends StockChangeState {
  final String message;
  const StockChangeError(this.message);

  @override
  List<Object?> get props => [message];
}
