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
  const BrandLoaded(this.brands);

  @override
  List<Object?> get props => [brands];
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
