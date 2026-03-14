import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepository {
  final DashboardRemoteDatasource _datasource;
  DashboardRepository(this._datasource);

  Future<DashboardStats> getStats() => _datasource.getStats();
}
