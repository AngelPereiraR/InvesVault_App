import '../datasources/brand_remote_datasource.dart';
import '../models/brand_model.dart';
import '../../core/models/filter_params.dart';

class BrandRepository {
  final BrandRemoteDatasource _datasource;
  BrandRepository(this._datasource);

  Future<List<BrandModel>> getBrands([FilterParams params = FilterParams.empty]) =>
      _datasource.getBrands(params);

  Future<BrandModel> createBrand(String name) =>
      _datasource.createBrand(name);

  Future<BrandModel> updateBrand(int id, String name) =>
      _datasource.updateBrand(id, name);

  Future<void> deleteBrand(int id) => _datasource.deleteBrand(id);
}
