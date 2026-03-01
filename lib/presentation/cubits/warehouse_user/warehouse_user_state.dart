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
  final bool isAdding;
  final String? addError;

  const WarehouseUserLoaded(
    this.users, {
    this.isAdding = false,
    this.addError,
  });

  WarehouseUserLoaded copyWith({
    List<WarehouseUserModel>? users,
    bool? isAdding,
    String? addError,
    bool clearAddError = false,
  }) =>
      WarehouseUserLoaded(
        users ?? this.users,
        isAdding: isAdding ?? this.isAdding,
        addError: clearAddError ? null : (addError ?? this.addError),
      );

  @override
  List<Object?> get props => [users, isAdding, addError];
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
