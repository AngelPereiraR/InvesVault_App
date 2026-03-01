import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDatasource _datasource;
  AuthRepository(this._datasource);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _datasource.register(name: name, email: email, password: password);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      _datasource.login(email: email, password: password);

  Future<UserModel> updateUser(int id, Map<String, dynamic> data) =>
      _datasource.updateUser(id, data);

  Future<UserModel?> searchByEmail(String email) =>
      _datasource.searchByEmail(email);
}
