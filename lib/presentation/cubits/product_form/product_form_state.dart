part of 'product_form_cubit.dart';

abstract class ProductFormState extends Equatable {
  const ProductFormState();

  @override
  List<Object?> get props => [];
}

class ProductFormInitial extends ProductFormState {
  const ProductFormInitial();
}

class ProductFormLoading extends ProductFormState {
  const ProductFormLoading();
}

class ProductFormReady extends ProductFormState {
  final List<BrandModel> brands;
  final List<StoreModel> stores;
  final ProductModel? existingProduct;

  const ProductFormReady({
    required this.brands,
    required this.stores,
    this.existingProduct,
  });

  @override
  List<Object?> get props => [brands, stores, existingProduct];
}

class ProductFormSuccess extends ProductFormState {
  final ProductModel product;
  const ProductFormSuccess(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductFormError extends ProductFormState {
  final String message;
  const ProductFormError(this.message);

  @override
  List<Object?> get props => [message];
}
