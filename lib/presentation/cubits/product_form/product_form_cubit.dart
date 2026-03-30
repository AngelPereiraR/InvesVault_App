import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/brand_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/store_model.dart';
import '../../../data/repositories/brand_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/store_repository.dart';

part 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  final ProductRepository _productRepository;
  final BrandRepository _brandRepository;
  final StoreRepository _storeRepository;
  final CategoryRepository _categoryRepository;

  ProductFormCubit(
    this._productRepository,
    this._brandRepository,
    this._storeRepository,
    this._categoryRepository,
  ) : super(const ProductFormInitial());

  Future<void> init({int? productId}) async {
    final prevProducts = state is ProductFormReady
        ? (state as ProductFormReady).allProducts
        : <ProductModel>[];
    emit(const ProductFormLoading());
    try {
      final results = await Future.wait([
        _brandRepository.getBrands(),
        _storeRepository.getStores(),
        _categoryRepository.getCategories(),
      ]);
      final brands = results[0] as List<BrandModel>;
      final stores = results[1] as List<StoreModel>;
      final categories = results[2] as List<CategoryModel>;
      ProductModel? existing;
      if (productId != null) {
        existing = await _productRepository.getProductById(productId);
      }
      emit(ProductFormReady(
          brands: brands, stores: stores, categories: categories,
          existingProduct: existing, allProducts: prevProducts));
    } catch (e) {
      emit(ProductFormError(friendlyError(e)));
    }
  }

  Future<void> loadForPicker() async {
    emit(const ProductFormLoading());
    try {
      final results = await Future.wait([
        _brandRepository.getBrands(),
        _storeRepository.getStores(),
        _productRepository.getProducts(),
        _categoryRepository.getCategories(),
      ]);
      final brands = results[0] as List<BrandModel>;
      final stores = results[1] as List<StoreModel>;
      final products = results[2] as List<ProductModel>;
      final categories = results[3] as List<CategoryModel>;
      emit(ProductFormReady(
          brands: brands, stores: stores, categories: categories, allProducts: products));
    } catch (e) {
      emit(ProductFormError(friendlyError(e)));
    }
  }

  Future<void> save(Map<String, dynamic> data, {int? productId}) async {
    final prev = state is ProductFormReady ? state as ProductFormReady : null;
    final prevProducts = prev?.allProducts ?? <ProductModel>[];
    emit(const ProductFormLoading());
    try {
      final product = productId != null
          ? await _productRepository.updateProduct(productId, data)
          : await _productRepository.createProduct(data);
      final updatedProducts = productId != null
          ? prevProducts.map((p) => p.id == productId ? product : p).toList()
          : [...prevProducts, product];
      emit(ProductFormSuccess(product, updatedProducts));
      emit(ProductFormReady(
        brands: prev?.brands ?? const [],
        stores: prev?.stores ?? const [],
        categories: prev?.categories ?? const [],
        allProducts: updatedProducts,
      ));
    } catch (e) {
      emit(ProductFormError(friendlyError(e)));
    }
  }
}
