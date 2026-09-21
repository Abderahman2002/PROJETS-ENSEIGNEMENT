import 'package:dio/dio.dart';
import 'session_store.dart';

/// Central HTTP client for the Django REST backend.
///
/// [baseUrl] points at a Django server running on the same machine — this
/// works for the Windows desktop app and Chrome/Edge. Switch it if you run
/// the app elsewhere:
/// - Android emulator: `http://10.0.2.2:8000/api`
/// - Physical phone/tablet on the same Wi-Fi: `http://<your-PC-LAN-IP>:8000/api`
///   (find it with `ipconfig`, e.g. `http://192.168.1.23:8000/api`)
/// - A deployed backend: its real URL.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _session.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final clone = await _retry(error.requestOptions);
              return handler.resolve(clone);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  static const String baseUrl = 'http://127.0.0.1:8000/api';

  late final Dio _dio;
  final SessionStore _session = SessionStore();

  Dio get dio => _dio;

  Future<bool> _tryRefreshToken() async {
    final refresh = await _session.readRefreshToken();
    if (refresh == null) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: baseUrl)).post(
        '/auth/refresh/',
        data: {'refresh': refresh},
      );
      final newAccess = response.data['access'] as String;
      await _session.saveTokens(access: newAccess, refresh: refresh);
      return true;
    } catch (_) {
      await _session.clear();
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(method: requestOptions.method, headers: requestOptions.headers);
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
