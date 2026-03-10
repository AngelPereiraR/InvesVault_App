import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/brand_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/store_model.dart';
import '../../../data/repositories/brand_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/store_repository.dart';

part 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  final ProductRepository _productRepository;
  final BrandRepository _brandRepository;
  final StoreRepository _storeRepository;

  ProductFormCubit(
    this._productRepository,
    this._brandRepository,
    this._storeRepository,
  ) : super(const ProductFormInitial());

  Future<void> init({int? productId}) async {
    emit(const ProductFormLoading());
    try {
      final results = await Future.wait([
        _brandRepository.getBrands(),
        _storeRepository.getStores(),
      ]);
      final brands = results[0] as List<BrandModel>;
      final stores = results[1] as List<StoreModel>;
      ProductModel? existing;
      if (productId != null) {
        existing = await _productRepository.getProductById(productId);
      }
      emit(ProductFormReady(
          brands: brands, stores: stores, existingProduct: existing));
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
      ]);
      final brands = results[0] as List<BrandModel>;
      final stores = results[1] as List<StoreModel>;
      final products = results[2] as List<ProductModel>;
      emit(ProductFormReady(
          brands: brands, stores: stores, allProducts: products));
    } catch (e) {
      emit(ProductFormError(friendlyError(e)));
    }
  }

  Future<void> save(Map<String, dynamic> data, {int? productId}) async {
    emit(const ProductFormLoading());
    try {
      final product = productId != null
          ? await _productRepository.updateProduct(productId, data)
          : await _productRepository.createProduct(data);
      emit(ProductFormSuccess(product));
    } catch (e) {
      emit(ProductFormError(friendlyError(e)));
    }
  }
}
