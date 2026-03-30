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
  final List<CategoryModel> categories;
  final ProductModel? existingProduct;
  final List<ProductModel> allProducts;

  const ProductFormReady({
    required this.brands,
    required this.stores,
    this.categories = const [],
    this.existingProduct,
    this.allProducts = const [],
  });

  @override
  List<Object?> get props => [brands, stores, categories, existingProduct, allProducts];
}

class ProductFormSuccess extends ProductFormState {
  final ProductModel product;
  final List<ProductModel> updatedProducts;
  const ProductFormSuccess(this.product, this.updatedProducts);

  @override
  List<Object?> get props => [product, updatedProducts];
}

class ProductFormError extends ProductFormState {
  final String message;
  const ProductFormError(this.message);

  @override
  List<Object?> get props => [message];
}
