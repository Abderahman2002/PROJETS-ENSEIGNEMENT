// Data models mirroring app/src/main/java/com/example/data/model/Entities.kt
// and the Django REST serializers in backend/core/serializers.py.

class TeacherProfile {
  final String id;
  final String phone;
  final String fullName;
  final String nationalId;
  final String financialIndex;
  final String schoolName;
  final String wilaya;
  final String moughataa;
  final String? avatarUrl;
  final bool isLoggedIn;
  final String role;
  final String accountStatus;
  final bool isActive;
  final String suspensionReason;
  final String subscriptionStatus;
  final String colorTheme;

  TeacherProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    this.nationalId = '',
    this.financialIndex = '',
    this.schoolName = '',
    this.wilaya = '',
    this.moughataa = '',
    this.avatarUrl,
    this.isLoggedIn = false,
    this.role = 'TEACHER',
    this.accountStatus = 'pending',
    this.isActive = true,
    this.suspensionReason = '',
    this.subscriptionStatus = 'TRIAL',
    this.colorTheme = 'blue',
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isPending => accountStatus == 'pending';
  bool get isSuspended => accountStatus == 'suspended' || accountStatus == 'deleted' || accountStatus == 'disabled';

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: json['id'].toString(),
      phone: json['phone'] ?? '',
      fullName: json['full_name'] ?? '',
      nationalId: json['national_id'] ?? '',
      financialIndex: json['financial_index'] ?? '',
      schoolName: json['school_name'] ?? '',
      wilaya: json['wilaya'] ?? '',
      moughataa: json['moughataa'] ?? '',
      avatarUrl: json['avatar'],
      isLoggedIn: true,
      role: json['role'] ?? 'TEACHER',
      accountStatus: json['account_status'] ?? 'pending',
      isActive: json['is_active'] ?? true,
      suspensionReason: json['suspension_reason'] ?? '',
      subscriptionStatus: json['subscription_status'] ?? 'TRIAL',
      colorTheme: json['color_theme'] ?? 'blue',
    );
  }
}

class SchoolClass {
  final int id;
  final String name;
  final String gradeLevel;
  final String academicYear;
  final int studentCount;
  final bool isArchived;

  SchoolClass({
    required this.id,
    required this.name,
    required this.gradeLevel,
    this.academicYear = '2026-2027',
    this.studentCount = 0,
    this.isArchived = false,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        id: json['id'],
        name: json['name'] ?? '',
        gradeLevel: json['grade_level'] ?? '',
        academicYear: json['academic_year'] ?? '2026-2027',
        studentCount: json['student_count'] ?? 0,
        isArchived: json['is_archived'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'grade_level': gradeLevel,
        'academic_year': academicYear,
        'is_archived': isArchived,
      };
}

class Student {
  final int id;
  final int schoolClass;
  final String fullName;
  final String studentCode;
  final String guardianName;
  final String guardianPhone;
  final String gender;
  final String? avatarUrl;
  final bool isArchived;
  final String healthNotes;
  final String pedagogicalNotes;

  Student({
    required this.id,
    required this.schoolClass,
    required this.fullName,
    this.studentCode = '',
    this.guardianName = '',
    this.guardianPhone = '',
    this.gender = 'ذكر',
    this.avatarUrl,
    this.isArchived = false,
    this.healthNotes = '',
    this.pedagogicalNotes = '',
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        schoolClass: json['school_class'],
        fullName: json['full_name'] ?? '',
        studentCode: json['student_code'] ?? '',
        guardianName: json['guardian_name'] ?? '',
        guardianPhone: json['guardian_phone'] ?? '',
        gender: json['gender'] ?? 'ذكر',
        avatarUrl: json['avatar'],
        isArchived: json['is_archived'] ?? false,
        healthNotes: json['health_notes'] ?? '',
        pedagogicalNotes: json['pedagogical_notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'school_class': schoolClass,
        'full_name': fullName,
        'student_code': studentCode,
        'guardian_name': guardianName,
        'guardian_phone': guardianPhone,
        'gender': gender,
        'is_archived': isArchived,
        'health_notes': healthNotes,
        'pedagogical_notes': pedagogicalNotes,
      };
}

class CalendarEvent {
  final int id;
  final String title;
  final String type;
  final String date;
  final String location;
  final String description;
  final bool isDone;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.location = 'المدرسة',
    this.description = '',
    this.isDone = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'],
        title: json['title'] ?? '',
        type: json['type'] ?? '',
        date: json['date'] ?? '',
        location: json['location'] ?? 'المدرسة',
        description: json['description'] ?? '',
        isDone: json['is_done'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'date': date,
        'location': location,
        'description': description,
        'is_done': isDone,
      };
}

class SkillEvaluation {
  final int id;
  final int skill;
  final int student;
  final int schoolClass;
  final String date;
  final String rating; // متقن / في طور الاكتساب / غير مكتسب
  final double score;
  final String notes;

  SkillEvaluation({
    required this.id,
    required this.skill,
    required this.student,
    required this.schoolClass,
    required this.date,
    required this.rating,
    this.score = 0,
    this.notes = '',
  });

  factory SkillEvaluation.fromJson(Map<String, dynamic> json) => SkillEvaluation(
        id: json['id'],
        skill: json['skill'],
        student: json['student'],
        schoolClass: json['school_class'],
        date: json['date'] ?? '',
        rating: json['rating'] ?? 'في طور الاكتساب',
        score: (json['score'] ?? 0).toDouble(),
        notes: json['notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'skill': skill,
        'student': student,
        'school_class': schoolClass,
        'date': date,
        'rating': rating,
        'score': score,
        'notes': notes,
      };
}

class AttendanceRecord {
  final int id;
  final int schoolClass;
  final int student;
  final String date; // YYYY-MM-DD
  final String status; // حاضر / غائب / متأخر
  final String notes;

  AttendanceRecord({
    required this.id,
    required this.schoolClass,
    required this.student,
    required this.date,
    required this.status,
    this.notes = '',
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        id: json['id'],
        schoolClass: json['school_class'],
        student: json['student'],
        date: json['date'] ?? '',
        status: json['status'] ?? 'حاضر',
        notes: json['notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'school_class': schoolClass,
        'student': student,
        'date': date,
        'status': status,
        'notes': notes,
      };
}

class TimetableSlot {
  final int id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int schoolClass;
  final String subject;
  final String lessonTitle;

  TimetableSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.schoolClass,
    required this.subject,
    this.lessonTitle = '',
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
        id: json['id'],
        dayOfWeek: json['day_of_week'] ?? '',
        startTime: (json['start_time'] ?? '').toString().substring(0, 5),
        endTime: (json['end_time'] ?? '').toString().substring(0, 5),
        schoolClass: json['school_class'],
        subject: json['subject'] ?? '',
        lessonTitle: json['lesson_title'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'school_class': schoolClass,
        'subject': subject,
        'lesson_title': lessonTitle,
      };
}

class TeacherSubscription {
  final int id;
  final String planName;
  final String status;
  final int priceOuguiya;
  final int durationDays;
  final String? activationDate;
  final String? expiryDate;
  final String paymentMethod;
  final String paymentReference;
  final String userNote;
  final String createdAt;

  TeacherSubscription({
    required this.id,
    required this.planName,
    required this.status,
    required this.priceOuguiya,
    required this.durationDays,
    this.activationDate,
    this.expiryDate,
    required this.paymentMethod,
    this.paymentReference = '',
    this.userNote = '',
    required this.createdAt,
  });

  factory TeacherSubscription.fromJson(Map<String, dynamic> json) => TeacherSubscription(
        id: json['id'],
        planName: json['plan_name'] ?? '',
        status: json['status'] ?? 'PENDING_VERIFICATION',
        priceOuguiya: json['price_ouguiya'] ?? 6000,
        durationDays: json['duration_days'] ?? 365,
        activationDate: json['activation_date'],
        expiryDate: json['expiry_date'],
        paymentMethod: json['payment_method'] ?? 'BANKILY',
        paymentReference: json['payment_reference'] ?? '',
        userNote: json['user_note'] ?? '',
        createdAt: json['created_at'] ?? '',
      );
}

class MonthlyParentReport {
  final int id;
  final int schoolClass;
  final int student;
  final String studentName;
  final String guardianName;
  final String guardianPhone;
  final String monthYear;
  final String progressLevel;
  final String attendanceSummary;
  final String evaluationResults;
  final String difficultyLessons;
  final String teacherRecommendations;

  MonthlyParentReport({
    required this.id,
    required this.schoolClass,
    required this.student,
    this.studentName = '',
    this.guardianName = '',
    this.guardianPhone = '',
    required this.monthYear,
    this.progressLevel = '',
    this.attendanceSummary = '',
    this.evaluationResults = '',
    this.difficultyLessons = '',
    this.teacherRecommendations = '',
  });

  factory MonthlyParentReport.fromJson(Map<String, dynamic> json) => MonthlyParentReport(
        id: json['id'],
        schoolClass: json['school_class'],
        student: json['student'],
        monthYear: json['month_year'] ?? '',
        progressLevel: json['progress_level'] ?? '',
        attendanceSummary: json['attendance_summary'] ?? '',
        evaluationResults: json['evaluation_results'] ?? '',
        difficultyLessons: json['difficulty_lessons'] ?? '',
        teacherRecommendations: json['teacher_recommendations'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'school_class': schoolClass,
        'student': student,
        'month_year': monthYear,
        'progress_level': progressLevel,
        'attendance_summary': attendanceSummary,
        'evaluation_results': evaluationResults,
        'difficulty_lessons': difficultyLessons,
        'teacher_recommendations': teacherRecommendations,
      };
}

class AdminTeacher {
  final String id;
  final String phone;
  final String fullName;
  final String schoolName;
  final String wilaya;
  final String role;
  final String accountStatus;
  final String suspensionReason;
  final String subscriptionStatus;
  final String? subscriptionEndDate;
  final bool isActive;

  AdminTeacher({
    required this.id,
    required this.phone,
    required this.fullName,
    this.schoolName = '',
    this.wilaya = '',
    this.role = 'TEACHER',
    this.accountStatus = 'pending',
    this.suspensionReason = '',
    this.subscriptionStatus = 'TRIAL',
    this.subscriptionEndDate,
    this.isActive = true,
  });

  factory AdminTeacher.fromJson(Map<String, dynamic> json) => AdminTeacher(
        id: json['id'].toString(),
        phone: json['phone'] ?? '',
        fullName: json['full_name'] ?? '',
        schoolName: json['school_name'] ?? '',
        wilaya: json['wilaya'] ?? '',
        role: json['role'] ?? 'TEACHER',
        accountStatus: json['account_status'] ?? 'pending',
        suspensionReason: json['suspension_reason'] ?? '',
        subscriptionStatus: json['subscription_status'] ?? 'TRIAL',
        subscriptionEndDate: json['subscription_end_date'],
        isActive: json['is_active'] ?? true,
      );
}

class AdminActionLog {
  final int id;
  final String teacherName;
  final String? adminName;
  final String actionType;
  final String oldValue;
  final String newValue;
  final String note;
  final String timestamp;

  AdminActionLog({
    required this.id,
    required this.teacherName,
    this.adminName,
    required this.actionType,
    this.oldValue = '',
    this.newValue = '',
    this.note = '',
    required this.timestamp,
  });

  factory AdminActionLog.fromJson(Map<String, dynamic> json) => AdminActionLog(
        id: json['id'],
        teacherName: json['teacher_name'] ?? '',
        adminName: json['admin_name'],
        actionType: json['action_type'] ?? '',
        oldValue: json['old_value'] ?? '',
        newValue: json['new_value'] ?? '',
        note: json['note'] ?? '',
        timestamp: json['timestamp'] ?? '',
      );
}

class ChatConversation {
  final int id;
  final String type;
  final String title;

  ChatConversation({required this.id, required this.type, required this.title});

  factory ChatConversation.fromJson(Map<String, dynamic> json) => ChatConversation(
        id: json['id'],
        type: json['type'] ?? 'PUBLIC_ROOM',
        title: json['title'] ?? '',
      );
}

class ChatMessage {
  final int id;
  final int conversation;
  final String sender;
  final String senderName;
  final String text;
  final String timestamp;

  ChatMessage({
    required this.id,
    required this.conversation,
    required this.sender,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        conversation: json['conversation'],
        sender: json['sender'].toString(),
        senderName: json['sender_name'] ?? '',
        text: json['text'] ?? '',
        timestamp: json['timestamp'] ?? '',
      );
}

class Lesson {
  final int id;
  final int schoolClass;
  final String subject;
  final String gradeLevel;
  final String domain;
  final String skillTitle;
  final String title;
  final String introduction;
  final String presentation;
  final String summary;
  final String application;
  final String integration;
  final bool isCompleted;
  final bool addedToBag;
  final bool isArchived;

  Lesson({
    required this.id,
    required this.schoolClass,
    required this.subject,
    this.gradeLevel = '',
    this.domain = '',
    this.skillTitle = '',
    required this.title,
    this.introduction = '',
    this.presentation = '',
    this.summary = '',
    this.application = '',
    this.integration = '',
    this.isCompleted = false,
    this.addedToBag = false,
    this.isArchived = false,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        schoolClass: json['school_class'],
        subject: json['subject'] ?? '',
        gradeLevel: json['grade_level'] ?? '',
        domain: json['domain'] ?? '',
        skillTitle: json['skill_title'] ?? '',
        title: json['title'] ?? '',
        introduction: json['introduction'] ?? '',
        presentation: json['presentation'] ?? '',
        summary: json['summary'] ?? '',
        application: json['application'] ?? '',
        integration: json['integration'] ?? '',
        isCompleted: json['is_completed'] ?? false,
        addedToBag: json['added_to_bag'] ?? false,
        isArchived: json['is_archived'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'school_class': schoolClass,
        'subject': subject,
        'grade_level': gradeLevel,
        'domain': domain,
        'skill_title': skillTitle,
        'title': title,
        'introduction': introduction,
        'presentation': presentation,
        'summary': summary,
        'application': application,
        'integration': integration,
        'is_completed': isCompleted,
        'added_to_bag': addedToBag,
        'is_archived': isArchived,
      };
}

class BagDocument {
  final int id;
  final String title;
  final String category;
  final String subject;
  final String gradeLevel;
  final String fileType;
  final String? sourceUrl;
  final String contentPreview;

  BagDocument({
    required this.id,
    required this.title,
    this.category = '',
    this.subject = '',
    this.gradeLevel = '',
    this.fileType = 'PDF',
    this.sourceUrl,
    this.contentPreview = '',
  });

  factory BagDocument.fromJson(Map<String, dynamic> json) => BagDocument(
        id: json['id'],
        title: json['title'] ?? '',
        category: json['category'] ?? '',
        subject: json['subject'] ?? '',
        gradeLevel: json['grade_level'] ?? '',
        fileType: json['file_type'] ?? 'PDF',
        sourceUrl: json['source_url'],
        contentPreview: json['content_preview'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'subject': subject,
        'grade_level': gradeLevel,
        'file_type': fileType,
        'source_url': sourceUrl,
        'content_preview': contentPreview,
      };
}

class Skill {
  final int id;
  final int schoolClass;
  final String subject;
  final String title;
  final String description;
  final String term;
  final String priority;
  final String domain;
  final String status;

  Skill({
    required this.id,
    required this.schoolClass,
    required this.subject,
    required this.title,
    this.description = '',
    this.term = 'الامتحان الأول',
    this.priority = 'عادية',
    this.domain = '',
    this.status = 'مخطط لها',
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'],
        schoolClass: json['school_class'],
        subject: json['subject'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        term: json['term'] ?? 'الامتحان الأول',
        priority: json['priority'] ?? 'عادية',
        domain: json['domain'] ?? '',
        status: json['status'] ?? 'مخطط لها',
      );

  Map<String, dynamic> toJson() => {
        'school_class': schoolClass,
        'subject': subject,
        'title': title,
        'description': description,
        'term': term,
        'priority': priority,
        'domain': domain,
        'status': status,
      };
}

class StudentGrade {
  final int id;
  final int schoolClass;
  final int student;
  final String term;
  final double arabicScore;
  final double mathScore;
  final double scienceScore;
  final double islamicScore;
  final double frenchScore;
  final double historyScore;
  final double civicScore;
  final double artScore;
  final double peScore;
  final double totalScore;
  final double average;
  final int rank;
  final String teacherNotes;

  StudentGrade({
    required this.id,
    required this.schoolClass,
    required this.student,
    required this.term,
    this.arabicScore = 0,
    this.mathScore = 0,
    this.scienceScore = 0,
    this.islamicScore = 0,
    this.frenchScore = 0,
    this.historyScore = 0,
    this.civicScore = 0,
    this.artScore = 0,
    this.peScore = 0,
    this.totalScore = 0,
    this.average = 0,
    this.rank = 0,
    this.teacherNotes = '',
  });

  double scoreForCode(String code) {
    switch (code) {
      case 'arabic':
        return arabicScore;
      case 'math':
        return mathScore;
      case 'science':
        return scienceScore;
      case 'islamic':
        return islamicScore;
      case 'french':
        return frenchScore;
      case 'history':
        return historyScore;
      case 'civic':
        return civicScore;
      case 'art':
        return artScore;
      case 'pe':
        return peScore;
      default:
        return 0;
    }
  }

  factory StudentGrade.fromJson(Map<String, dynamic> json) => StudentGrade(
        id: json['id'],
        schoolClass: json['school_class'],
        student: json['student'],
        term: json['term'] ?? '',
        arabicScore: (json['arabic_score'] ?? 0).toDouble(),
        mathScore: (json['math_score'] ?? 0).toDouble(),
        scienceScore: (json['science_score'] ?? 0).toDouble(),
        islamicScore: (json['islamic_score'] ?? 0).toDouble(),
        frenchScore: (json['french_score'] ?? 0).toDouble(),
        historyScore: (json['history_score'] ?? 0).toDouble(),
        civicScore: (json['civic_score'] ?? 0).toDouble(),
        artScore: (json['art_score'] ?? 0).toDouble(),
        peScore: (json['pe_score'] ?? 0).toDouble(),
        totalScore: (json['total_score'] ?? 0).toDouble(),
        average: (json['average'] ?? 0).toDouble(),
        rank: json['rank'] ?? 0,
        teacherNotes: json['teacher_notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'school_class': schoolClass,
        'student': student,
        'term': term,
        'arabic_score': arabicScore,
        'math_score': mathScore,
        'science_score': scienceScore,
        'islamic_score': islamicScore,
        'french_score': frenchScore,
        'history_score': historyScore,
        'civic_score': civicScore,
        'art_score': artScore,
        'pe_score': peScore,
        'total_score': totalScore,
        'average': average,
        'teacher_notes': teacherNotes,
      };
}

class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final String timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? '',
        timestamp: json['timestamp'] ?? '',
        isRead: json['is_read'] ?? false,
      );
}
