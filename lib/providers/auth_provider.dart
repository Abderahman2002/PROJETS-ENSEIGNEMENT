import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/session_store.dart';
import '../models/models.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// Mirrors the login/register/session logic from MainViewModel.kt,
/// backed by the Django JWT endpoints under /api/auth/.
class AuthProvider extends ChangeNotifier {
  final SessionStore _session = SessionStore();
  final _dio = ApiClient.instance.dio;

  AuthStatus status = AuthStatus.unknown;
  TeacherProfile? teacherProfile;
  String? sessionRole;
  String colorTheme = 'blue';

  Future<void> bootstrap() async {
    final token = await _session.readAccessToken();
    if (token == null) {
      status = AuthStatus.loggedOut;
      notifyListeners();
      return;
    }
    try {
      await fetchProfile();
      status = AuthStatus.loggedIn;
    } catch (_) {
      status = AuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final response = await _dio.get('/auth/me/');
    teacherProfile = TeacherProfile.fromJson(response.data);
    sessionRole = teacherProfile?.role.toLowerCase();
    colorTheme = teacherProfile?.colorTheme ?? 'blue';
  }

  /// [phoneOrIndex] accepts either the phone number or financial index,
  /// matching LoginScreen.kt's single identifier field.
  Future<void> login({
    required String phoneOrIndex,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login/', data: {
      'phone': phoneOrIndex,
      'password': password,
    });
    await _session.saveTokens(
      access: response.data['access'],
      refresh: response.data['refresh'],
    );
    await fetchProfile();
    status = AuthStatus.loggedIn;
    notifyListeners();
  }

  Future<void> register({
    required String phone,
    required String password,
    required String fullName,
    String nationalId = '',
    String financialIndex = '',
    String schoolName = '',
    String wilaya = '',
    String moughataa = '',
  }) async {
    await _dio.post('/auth/register/', data: {
      'phone': phone,
      'password': password,
      'full_name': fullName,
      'national_id': nationalId,
      'financial_index': financialIndex,
      'school_name': schoolName,
      'wilaya': wilaya,
      'moughataa': moughataa,
    });
    await login(phoneOrIndex: phone, password: password);
  }

  Future<void> requestPasswordReset(String phone) async {
    await _dio.post('/auth/forgot-password/request/', data: {'phone': phone});
  }

  Future<void> confirmPasswordReset({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post('/auth/forgot-password/confirm/', data: {
      'phone': phone,
      'code': code,
      'new_password': newPassword,
    });
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    await _dio.patch('/auth/me/', data: fields);
    await fetchProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    await _session.clear();
    teacherProfile = null;
    status = AuthStatus.loggedOut;
    notifyListeners();
  }

  String friendlyError(Object error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('DioException')) {
        return 'تعذر الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت.';
      }
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }
}
