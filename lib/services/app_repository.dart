import '../core/api_client.dart';
import '../models/models.dart';

/// Thin wrapper around the Django REST endpoints under /api/, mirroring the
/// CRUD methods AppRepository.kt exposed over local Room + Firestore.
class AppRepository {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  final _dio = ApiClient.instance.dio;

  // --- Classes ---

  Future<List<SchoolClass>> getClasses() async {
    final res = await _dio.get('/classes/');
    return _list(res.data).map((e) => SchoolClass.fromJson(e)).toList();
  }

  Future<SchoolClass> createClass({required String name, required String gradeLevel}) async {
    final res = await _dio.post('/classes/', data: {
      'name': name,
      'grade_level': gradeLevel,
    });
    return SchoolClass.fromJson(res.data);
  }

  Future<SchoolClass> updateClass(int id, {required String name, required String gradeLevel}) async {
    final res = await _dio.patch('/classes/$id/', data: {
      'name': name,
      'grade_level': gradeLevel,
    });
    return SchoolClass.fromJson(res.data);
  }

  Future<void> deleteClass(int id) => _dio.delete('/classes/$id/');

  // --- Students ---

  Future<List<Student>> getStudents({int? classId}) async {
    final res = await _dio.get('/students/', queryParameters: classId != null ? {'school_class': classId} : null);
    return _list(res.data).map((e) => Student.fromJson(e)).toList();
  }

  Future<Student> createStudent(Student student) async {
    final res = await _dio.post('/students/', data: student.toJson());
    return Student.fromJson(res.data);
  }

  Future<Student> updateStudent(int id, Student student) async {
    final res = await _dio.patch('/students/$id/', data: student.toJson());
    return Student.fromJson(res.data);
  }

  Future<void> deleteStudent(int id) => _dio.delete('/students/$id/');

  // --- Attendance ---

  Future<List<AttendanceRecord>> getAttendanceForClass(int classId, {String? date}) async {
    final query = <String, dynamic>{'school_class': classId};
    if (date != null) query['date'] = date;
    final res = await _dio.get('/attendance/', queryParameters: query);
    return _list(res.data).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  /// Creates or updates the attendance record for a student on a given date.
  Future<AttendanceRecord> upsertAttendance({
    required int classId,
    required int studentId,
    required String date,
    required String status,
    AttendanceRecord? existing,
  }) async {
    if (existing != null) {
      final res = await _dio.patch('/attendance/${existing.id}/', data: {'status': status});
      return AttendanceRecord.fromJson(res.data);
    }
    final res = await _dio.post('/attendance/', data: {
      'school_class': classId,
      'student': studentId,
      'date': date,
      'status': status,
    });
    return AttendanceRecord.fromJson(res.data);
  }

  // --- Subscription ---

  Future<List<TeacherSubscription>> getSubscriptions() async {
    final res = await _dio.get('/subscriptions/');
    return _list(res.data).map((e) => TeacherSubscription.fromJson(e)).toList();
  }

  Future<TeacherSubscription> submitSubscriptionProof({
    required String paymentMethod,
    required String paymentReference,
    String userNote = '',
  }) async {
    final res = await _dio.post('/subscriptions/', data: {
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'user_note': userNote,
    });
    return TeacherSubscription.fromJson(res.data);
  }

  // --- Parent reports ---

  Future<List<MonthlyParentReport>> getParentReports() async {
    final res = await _dio.get('/parent-reports/');
    return _list(res.data).map((e) => MonthlyParentReport.fromJson(e)).toList();
  }

  Future<MonthlyParentReport> createParentReport(MonthlyParentReport report) async {
    final res = await _dio.post('/parent-reports/', data: report.toJson());
    return MonthlyParentReport.fromJson(res.data);
  }

  Future<void> deleteParentReport(int id) => _dio.delete('/parent-reports/$id/');

  // --- Admin (developer panel / user management) ---

  Future<List<AdminTeacher>> getAdminTeachers({String? search}) async {
    final res = await _dio.get('/auth/admin/users/', queryParameters: search != null && search.isNotEmpty ? {'search': search} : null);
    return _list(res.data).map((e) => AdminTeacher.fromJson(e)).toList();
  }

  Future<AdminTeacher> activateSubscription(String teacherId, {int durationDays = 365, String note = ''}) async {
    final res = await _dio.post('/auth/admin/users/$teacherId/activate-subscription/',
        data: {'duration_days': durationDays, 'note': note});
    return AdminTeacher.fromJson(res.data);
  }

  Future<AdminTeacher> extendSubscription(String teacherId, {int durationDays = 30, String note = ''}) async {
    final res = await _dio.post('/auth/admin/users/$teacherId/extend-subscription/',
        data: {'duration_days': durationDays, 'note': note});
    return AdminTeacher.fromJson(res.data);
  }

  Future<AdminTeacher> deactivateSubscription(String teacherId) async {
    final res = await _dio.post('/auth/admin/users/$teacherId/deactivate-subscription/');
    return AdminTeacher.fromJson(res.data);
  }

  Future<AdminTeacher> endSubscription(String teacherId) async {
    final res = await _dio.post('/auth/admin/users/$teacherId/end-subscription/');
    return AdminTeacher.fromJson(res.data);
  }

  Future<AdminTeacher> disableAccount(String teacherId, {String reason = ''}) async {
    final res = await _dio.post('/auth/admin/users/$teacherId/disable-account/', data: {'reason': reason});
    return AdminTeacher.fromJson(res.data);
  }

  Future<AdminTeacher> activateAccount(String teacherId) async {
    final res = await _dio.post('/auth/admin/users/$teacherId/activate-account/');
    return AdminTeacher.fromJson(res.data);
  }

  Future<List<AdminActionLog>> getAdminActionLog() async {
    final res = await _dio.get('/auth/admin/actions/');
    return _list(res.data).map((e) => AdminActionLog.fromJson(e)).toList();
  }

  // --- Chat (public room only) ---

  Future<ChatConversation> getOrCreatePublicRoom() async {
    final res = await _dio.get('/conversations/');
    final list = _list(res.data).map((e) => ChatConversation.fromJson(e)).toList();
    final existing = list.where((c) => c.type == 'PUBLIC_ROOM').toList();
    if (existing.isNotEmpty) return existing.first;
    final created = await _dio.post('/conversations/', data: {
      'type': 'PUBLIC_ROOM',
      'title': 'غرفة المعلمين العامة',
    });
    return ChatConversation.fromJson(created.data);
  }

  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final res = await _dio.get('/messages/', queryParameters: {'conversation': conversationId});
    return _list(res.data).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<ChatMessage> sendMessage({required int conversationId, required String text}) async {
    final res = await _dio.post('/messages/', data: {'conversation': conversationId, 'text': text});
    return ChatMessage.fromJson(res.data);
  }

  // --- Lessons ---

  Future<List<Lesson>> getLessons() async {
    final res = await _dio.get('/lessons/');
    return _list(res.data).map((e) => Lesson.fromJson(e)).toList();
  }

  Future<Lesson> createLesson(Lesson lesson) async {
    final res = await _dio.post('/lessons/', data: lesson.toJson());
    return Lesson.fromJson(res.data);
  }

  Future<Lesson> updateLesson(int id, Lesson lesson) async {
    final res = await _dio.patch('/lessons/$id/', data: lesson.toJson());
    return Lesson.fromJson(res.data);
  }

  Future<void> deleteLesson(int id) => _dio.delete('/lessons/$id/');

  // --- Bag documents ---

  Future<List<BagDocument>> getBagDocuments() async {
    final res = await _dio.get('/bag-documents/');
    return _list(res.data).map((e) => BagDocument.fromJson(e)).toList();
  }

  Future<BagDocument> createBagDocument(BagDocument doc) async {
    final res = await _dio.post('/bag-documents/', data: doc.toJson());
    return BagDocument.fromJson(res.data);
  }

  Future<void> deleteBagDocument(int id) => _dio.delete('/bag-documents/$id/');

  // --- Timetable ---

  Future<List<TimetableSlot>> getTimetableSlots() async {
    final res = await _dio.get('/timetable/');
    return _list(res.data).map((e) => TimetableSlot.fromJson(e)).toList();
  }

  Future<TimetableSlot> createTimetableSlot(TimetableSlot slot) async {
    final res = await _dio.post('/timetable/', data: slot.toJson());
    return TimetableSlot.fromJson(res.data);
  }

  Future<TimetableSlot> updateTimetableSlot(int id, TimetableSlot slot) async {
    final res = await _dio.patch('/timetable/$id/', data: slot.toJson());
    return TimetableSlot.fromJson(res.data);
  }

  Future<void> deleteTimetableSlot(int id) => _dio.delete('/timetable/$id/');

  // --- Skills ---

  Future<List<Skill>> getSkills({int? classId}) async {
    final res = await _dio.get('/skills/', queryParameters: classId != null ? {'school_class': classId} : null);
    return _list(res.data).map((e) => Skill.fromJson(e)).toList();
  }

  Future<Skill> createSkill(Skill skill) async {
    final res = await _dio.post('/skills/', data: skill.toJson());
    return Skill.fromJson(res.data);
  }

  Future<Skill> updateSkill(int id, Skill skill) async {
    final res = await _dio.patch('/skills/$id/', data: skill.toJson());
    return Skill.fromJson(res.data);
  }

  Future<void> deleteSkill(int id) => _dio.delete('/skills/$id/');

  // --- Grades ---

  Future<List<StudentGrade>> getGrades({required int classId, required String term}) async {
    final res = await _dio.get('/grades/', queryParameters: {'school_class': classId, 'term': term});
    return _list(res.data).map((e) => StudentGrade.fromJson(e)).toList();
  }

  /// Creates or updates a student's grade for a term (student+term is unique server-side).
  Future<StudentGrade> upsertGrade(StudentGrade grade, {StudentGrade? existing}) async {
    if (existing != null) {
      final res = await _dio.patch('/grades/${existing.id}/', data: grade.toJson());
      return StudentGrade.fromJson(res.data);
    }
    final res = await _dio.post('/grades/', data: grade.toJson());
    return StudentGrade.fromJson(res.data);
  }

  // --- Skill evaluations ---

  Future<List<SkillEvaluation>> getSkillEvaluations({required int skillId}) async {
    final res = await _dio.get('/skill-evaluations/', queryParameters: {'skill': skillId});
    return _list(res.data).map((e) => SkillEvaluation.fromJson(e)).toList();
  }

  Future<SkillEvaluation> upsertSkillEvaluation(SkillEvaluation evaluation, {SkillEvaluation? existing}) async {
    if (existing != null) {
      final res = await _dio.patch('/skill-evaluations/${existing.id}/', data: evaluation.toJson());
      return SkillEvaluation.fromJson(res.data);
    }
    final res = await _dio.post('/skill-evaluations/', data: evaluation.toJson());
    return SkillEvaluation.fromJson(res.data);
  }

  // --- Calendar events ---

  Future<List<CalendarEvent>> getCalendarEvents() async {
    final res = await _dio.get('/calendar-events/');
    return _list(res.data).map((e) => CalendarEvent.fromJson(e)).toList();
  }

  Future<CalendarEvent> createCalendarEvent(CalendarEvent event) async {
    final res = await _dio.post('/calendar-events/', data: event.toJson());
    return CalendarEvent.fromJson(res.data);
  }

  Future<CalendarEvent> updateCalendarEvent(int id, CalendarEvent event) async {
    final res = await _dio.patch('/calendar-events/$id/', data: event.toJson());
    return CalendarEvent.fromJson(res.data);
  }

  Future<void> deleteCalendarEvent(int id) => _dio.delete('/calendar-events/$id/');

  // --- Notifications ---

  Future<List<AppNotification>> getNotifications() async {
    final res = await _dio.get('/notifications/');
    return _list(res.data).map((e) => AppNotification.fromJson(e)).toList();
  }

  List<dynamic> _list(dynamic data) {
    if (data is Map && data.containsKey('results')) return data['results'] as List<dynamic>;
    return data as List<dynamic>;
  }
}
