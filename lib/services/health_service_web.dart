/// Web stub of HealthService - health packages are not supported on web.
/// This provides no-op implementations so the app can compile on web.
class HealthService {
  static const List<String> allMetrics = [];

  Future<Map<String, dynamic>> requestPermissions() async {
    return {'ok': false, 'message': 'Health APIs are not available on web'};
  }

  Future<void> installHealthConnect() async {
    // No-op on web
  }

  Future<bool> isHealthConnectAvailable() async {
    return false;
  }

  Future<List<Map<String, dynamic>>> fetchData(
    String metric,
    DateTime start,
    DateTime end,
  ) async {
    return [];
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchAll({
    Duration range = const Duration(days: 1),
  }) async {
    return {};
  }
}
