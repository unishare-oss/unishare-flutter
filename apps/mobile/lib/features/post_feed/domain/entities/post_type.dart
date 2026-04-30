enum PostType {
  note,
  exercise,
  pastExam;

  String get label {
    switch (this) {
      case PostType.note:
        return 'NOTE';
      case PostType.exercise:
        return 'EXERCISE';
      case PostType.pastExam:
        return 'PAST EXAM';
    }
  }

  static PostType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EXERCISE':
        return PostType.exercise;
      case 'OLD_QUESTION':
      case 'PAST_EXAM':
        return PostType.pastExam;
      case 'NOTE':
      default:
        return PostType.note;
    }
  }
}
