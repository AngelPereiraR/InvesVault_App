import '../datasources/store_remote_datasource.dart';
import '../models/store_model.dart';
import '../../core/models/filter_params.dart';

class StoreRepository {
  final StoreRemoteDatasource _datasource;
  StoreRepository(this._datasource);

  Future<List<StoreModel>> getStores([FilterParams params = FilterParams.empty]) =>
      _datasource.getStores(params);

  Future<StoreModel> createStore({required String name, String? location}) =>
      _datasource.createStore(name: name, location: location);

  Future<StoreModel> updateStore(int id, Map<String, dynamic> data) =>
      _datasource.updateStore(id, data);

  Future<void> deleteStore(int id) => _datasource.deleteStore(id);
}
