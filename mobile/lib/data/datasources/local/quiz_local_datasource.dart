import 'package:objectbox/objectbox.dart';
import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_question_model.dart';
import '../../models/quiz_attempt_model.dart';

class QuizLocalDatasource {
  final ObjectBox _objectBox;

  QuizLocalDatasource(this._objectBox);

  Box<QuizModel> get _quizBox => _objectBox.store.box<QuizModel>();
  Box<QuizQuestionModel> get _questionBox => _objectBox.store.box<QuizQuestionModel>();
  Box<QuizAttemptModel> get _attemptBox => _objectBox.store.box<QuizAttemptModel>();

  List<QuizModel> getByNotebookId(int notebookId) {
    final query = _quizBox.query(QuizModel_.notebookId.equals(notebookId))
        .order(QuizModel_.createdAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  QuizModel createQuiz(QuizModel model) {
    final id = _quizBox.put(model);
    return _quizBox.get(id)!;
  }

  void saveQuestions(List<QuizQuestionModel> questions) {
    _questionBox.putMany(questions);
  }

  List<QuizQuestionModel> getQuestions(int quizId) {
    final query = _questionBox.query(QuizQuestionModel_.quizId.equals(quizId))
        .order(QuizQuestionModel_.questionIndex)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  QuizAttemptModel saveAttempt(QuizAttemptModel model) {
    final id = _attemptBox.put(model);
    return _attemptBox.get(id)!;
  }

  List<QuizAttemptModel> getAttempts(int quizId) {
    final query = _attemptBox.query(QuizAttemptModel_.quizId.equals(quizId))
        .order(QuizAttemptModel_.completedAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  void deleteQuiz(int id) {
    // Delete questions
    final qQuery = _questionBox.query(QuizQuestionModel_.quizId.equals(id)).build();
    final qIds = qQuery.find().map((q) => q.id).toList();
    qQuery.close();
    _questionBox.removeMany(qIds);

    // Delete attempts
    final aQuery = _attemptBox.query(QuizAttemptModel_.quizId.equals(id)).build();
    final aIds = aQuery.find().map((a) => a.id).toList();
    aQuery.close();
    _attemptBox.removeMany(aIds);

    _quizBox.remove(id);
  }
}
