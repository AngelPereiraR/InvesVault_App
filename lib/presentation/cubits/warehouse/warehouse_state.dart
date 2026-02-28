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
  const WarehouseLoaded(this.warehouses);

  @override
  List<Object?> get props => [warehouses];
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
