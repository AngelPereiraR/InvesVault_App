part of 'warehouse_user_cubit.dart';

abstract class WarehouseUserState extends Equatable {
  const WarehouseUserState();

  @override
  List<Object?> get props => [];
}

class WarehouseUserInitial extends WarehouseUserState {
  const WarehouseUserInitial();
}

class WarehouseUserLoading extends WarehouseUserState {
  const WarehouseUserLoading();
}

class WarehouseUserLoaded extends WarehouseUserState {
  final List<WarehouseUserModel> users;
  const WarehouseUserLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class WarehouseUserError extends WarehouseUserState {
  final String message;
  const WarehouseUserError(this.message);

  @override
  List<Object?> get props => [message];
}

class WarehouseUserActionSuccess extends WarehouseUserState {
  final String message;
  const WarehouseUserActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
