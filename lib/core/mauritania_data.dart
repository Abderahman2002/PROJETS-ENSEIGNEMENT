/// Mirrors data/MauritaniaData.kt — shared reference lists used across screens.
class SubjectRule {
  final String name;
  final double maxPoints;
  final String code;

  const SubjectRule(this.name, this.maxPoints, this.code);
}

class MauritaniaData {
  MauritaniaData._();

  static const List<String> schoolLevels = [
    'السنة الأولى',
    'السنة الثانية',
    'السنة الثالثة',
    'السنة الرابعة',
    'السنة الخامسة',
    'السنة السادسة',
  ];

  static const List<String> terms = [
    'الامتحان الأول',
    'الامتحان الثاني',
    'الامتحان النهائي أو التجاوز',
  ];

  static const List<String> standardSubjects = [
    'اللغة العربية',
    'الرياضيات',
    'العلوم',
    'التربية الإسلامية',
    'اللغة الفرنسية',
    'التاريخ',
    'التربية المدنية',
    'التربية الفنية',
    'التربية الرياضية',
  ];

  static const List<String> _year1And2Subjects = [
    'اللغة العربية',
    'الرياضيات',
    'التربية الإسلامية',
    'التربية المدنية',
    'التربية الفنية',
    'التربية الرياضية',
  ];

  static List<String> getSubjectsForGrade(String? gradeLevel) {
    if (gradeLevel == null) return standardSubjects;
    if (gradeLevel.contains('الأولى') || gradeLevel.contains('الثانية')) {
      return _year1And2Subjects;
    }
    return standardSubjects;
  }

  static const Map<String, String> subjectEmojis = {
    'اللغة العربية': '📘',
    'الرياضيات': '📗',
    'اللغة الفرنسية': '📕',
    'التربية الإسلامية': '📙',
    'العلوم': '📒',
    'التاريخ': '🌍',
    'التربية المدنية': '⚖️',
    'التربية الفنية': '🎨',
    'التربية الرياضية': '⚽',
  };

  static List<String> getDomainOptionsForSubject(String subject) {
    if (subject.contains('العربية')) {
      return ['القراءة والفهم', 'النحو والتراكيب', 'التعبير الشفهي', 'الإملاء والكتابة', 'الخط'];
    }
    if (subject.contains('الرياضيات')) {
      return ['الحساب والعمليات', 'الهندسة والفضاء', 'القياس والمقادير', 'حل المسائل'];
    }
    if (subject.contains('الإسلامية')) {
      return ['القرآن الكريم', 'الحديث الشريف', 'العقيدة والفقه', 'السيرة والآداب'];
    }
    if (subject.contains('العلوم')) {
      return ['جسم الإنسان وصحته', 'الكائنات الحية والبيئة', 'المادة والطاقة'];
    }
    if (subject.contains('الفرنسية')) {
      return ['Communication orale', 'Lecture', 'Grammaire', 'Production écrite'];
    }
    if (subject.contains('التاريخ') || subject.contains('الجغرافيا')) {
      return ['التاريخ الوطني', 'الجغرافيا والبيئة', 'المعالم والخرائط'];
    }
    if (subject.contains('المدنية')) {
      return ['المواطنة والسلوك المدني', 'المؤسسات الوطنية', 'حقوق وواجبات'];
    }
    if (subject.contains('الفنية')) {
      return ['الرسم والألوان', 'الأشغال اليدوية', 'الخط والزخرفة'];
    }
    if (subject.contains('الرياضية') || subject.contains('البدنية')) {
      return ['اللياقة البدنية', 'الجمباز والحركات', 'الألعاب الجماعية'];
    }
    return ['المجال الأساسي', 'المفاهيم والتطبيقات', 'الأنشطة الاستكشافية'];
  }

  static const Map<String, List<SubjectRule>> _curriculumByLevel = {
    'السنة الأولى': [
      SubjectRule('التربية الإسلامية', 40, 'islamic'),
      SubjectRule('اللغة العربية', 80, 'arabic'),
      SubjectRule('الرياضيات', 40, 'math'),
      SubjectRule('التربية المدنية', 15, 'civic'),
      SubjectRule('التربية الفنية', 15, 'art'),
      SubjectRule('الرياضة البدنية', 10, 'pe'),
    ],
    'السنة الثانية': [
      SubjectRule('التربية الإسلامية', 30, 'islamic'),
      SubjectRule('اللغة العربية', 50, 'arabic'),
      SubjectRule('الرياضيات', 40, 'math'),
      SubjectRule('التربية المدنية', 15, 'civic'),
      SubjectRule('التربية الفنية', 15, 'art'),
      SubjectRule('اللغة الفرنسية', 40, 'french'),
      SubjectRule('الرياضة البدنية', 10, 'pe'),
    ],
    'السنة الثالثة': [
      SubjectRule('التربية الإسلامية', 30, 'islamic'),
      SubjectRule('اللغة العربية', 50, 'arabic'),
      SubjectRule('الرياضيات', 40, 'math'),
      SubjectRule('التربية المدنية', 10, 'civic'),
      SubjectRule('التربية الفنية', 10, 'art'),
      SubjectRule('اللغة الفرنسية', 30, 'french'),
      SubjectRule('التاريخ والجغرافيا', 10, 'history'),
      SubjectRule('العلوم الطبيعية', 10, 'science'),
      SubjectRule('الرياضة البدنية', 10, 'pe'),
    ],
    'السنة الرابعة': [
      SubjectRule('التربية الإسلامية', 30, 'islamic'),
      SubjectRule('اللغة العربية', 50, 'arabic'),
      SubjectRule('الرياضيات', 40, 'math'),
      SubjectRule('التربية المدنية', 10, 'civic'),
      SubjectRule('التربية الفنية', 10, 'art'),
      SubjectRule('اللغة الفرنسية', 30, 'french'),
      SubjectRule('التاريخ والجغرافيا', 10, 'history'),
      SubjectRule('العلوم الطبيعية', 10, 'science'),
      SubjectRule('الرياضة البدنية', 10, 'pe'),
    ],
    'السنة الخامسة': [
      SubjectRule('التربية الإسلامية', 30, 'islamic'),
      SubjectRule('اللغة العربية', 50, 'arabic'),
      SubjectRule('الرياضيات', 40, 'math'),
      SubjectRule('التربية المدنية', 10, 'civic'),
      SubjectRule('التربية الفنية', 10, 'art'),
      SubjectRule('اللغة الفرنسية', 30, 'french'),
      SubjectRule('التاريخ والجغرافيا', 10, 'history'),
      SubjectRule('العلوم الطبيعية', 10, 'science'),
      SubjectRule('الرياضة البدنية', 10, 'pe'),
    ],
    'السنة السادسة': [
      SubjectRule('التربية الإسلامية', 30, 'islamic'),
      SubjectRule('اللغة العربية', 50, 'arabic'),
      SubjectRule('الرياضيات', 40, 'math'),
      SubjectRule('التربية المدنية', 10, 'civic'),
      SubjectRule('التربية الفنية', 10, 'art'),
      SubjectRule('اللغة الفرنسية', 30, 'french'),
      SubjectRule('التاريخ والجغرافيا', 10, 'history'),
      SubjectRule('العلوم الطبيعية', 10, 'science'),
      SubjectRule('الرياضة البدنية', 10, 'pe'),
    ],
  };

  static List<SubjectRule> getSubjectsForLevel(String gradeLevel) {
    for (final entry in _curriculumByLevel.entries) {
      if (gradeLevel.contains(entry.key) || entry.key.contains(gradeLevel)) {
        return entry.value;
      }
    }
    return _curriculumByLevel['السنة الثالثة']!;
  }
}
