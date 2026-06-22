enum QuestionType {
  mcq,
  trueFalse,
  fillBlank,
  essay;

  String get label {
    switch (this) {
      case QuestionType.mcq: return 'Multiple Choice';
      case QuestionType.trueFalse: return 'True/False';
      case QuestionType.fillBlank: return 'Fill in the Blank';
      case QuestionType.essay: return 'Essay';
    }
  }

  static QuestionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'mcq': case 'multiple_choice': return QuestionType.mcq;
      case 'truefalse': case 'true_false': return QuestionType.trueFalse;
      case 'fillblank': case 'fill_blank': return QuestionType.fillBlank;
      case 'essay': return QuestionType.essay;
      default: return QuestionType.mcq;
    }
  }
}
