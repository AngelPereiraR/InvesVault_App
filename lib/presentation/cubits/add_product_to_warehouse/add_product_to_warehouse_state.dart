import 'package:equatable/equatable.dart';
import '../../../data/models/warehouse_model.dart';

abstract class AddProductToWarehouseState extends Equatable {
  const AddProductToWarehouseState();

  @override
  List<Object?> get props => [];
}

class AddProductToWarehouseInitial extends AddProductToWarehouseState {
  const AddProductToWarehouseInitial();
}

class AddProductToWarehouseLoading extends AddProductToWarehouseState {
  const AddProductToWarehouseLoading();
}

class AddProductToWarehouseReady extends AddProductToWarehouseState {
  final List<WarehouseModel> warehouses;
  final String productUnit;
  final int productId;

  const AddProductToWarehouseReady({
    required this.warehouses,
    required this.productUnit,
    required this.productId,
  });

  @override
  List<Object?> get props => [warehouses, productUnit, productId];
}

class AddProductToWarehouseSuccess extends AddProductToWarehouseState {
  const AddProductToWarehouseSuccess();
}

class AddProductToWarehouseError extends AddProductToWarehouseState {
  final String message;

  const AddProductToWarehouseError(this.message);

  @override
  List<Object?> get props => [message];
}
