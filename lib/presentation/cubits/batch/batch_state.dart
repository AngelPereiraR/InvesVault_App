part of 'batch_cubit.dart';

abstract class BatchState extends Equatable {
  const BatchState();
  @override
  List<Object?> get props => [];
}

class BatchInitial extends BatchState {
  const BatchInitial();
}

class BatchLoading extends BatchState {
  const BatchLoading();
}

class BatchLoaded extends BatchState {
  final List<BatchModel> batches;
  final int warehouseProductId;
  const BatchLoaded({required this.batches, required this.warehouseProductId});
  @override
  List<Object?> get props => [batches, warehouseProductId];
}

class BatchError extends BatchState {
  final String message;
  const BatchError(this.message);
  @override
  List<Object?> get props => [message];
}

class BatchMutating extends BatchState {
  final List<BatchModel> batches;
  const BatchMutating({required this.batches});
  @override
  List<Object?> get props => [batches];
}
