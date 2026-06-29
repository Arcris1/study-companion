import '../ai/ai_config.dart';

class PromptTemplates {
  static String summarize(String text) {
    return '''<|begin_of_turn|>system
${AiConfig.instance.systemPrompt(AiOp.summary)}<|end_of_turn|>
<|begin_of_turn|>user
Summarize the following text:

$text<|end_of_turn|>
<|begin_of_turn|>assistant
''';
  }

  static String answerQuestion(String context, String question) {
    return '''<|begin_of_turn|>system
${AiConfig.instance.systemPrompt(AiOp.chat)}<|end_of_turn|>
<|begin_of_turn|>user
Context:
$context

Question: $question<|end_of_turn|>
<|begin_of_turn|>assistant
''';
  }

  static String answerWithHistory({
    required String context,
    required String history,
    required String question,
  }) {
    return '''<|begin_of_turn|>system
${AiConfig.instance.systemPrompt(AiOp.chat)}<|end_of_turn|>
<|begin_of_turn|>user
Context from notes:
$context

Conversation so far:
$history

Question: $question<|end_of_turn|>
<|begin_of_turn|>assistant
''';
  }

  static String generateQuiz({
    required String content,
    required int numQuestions,
    required String questionType,
    required String difficulty,
    String styleInstruction = '',
  }) {
    String typeInstruction;
    if (questionType == 'trueFalse' || questionType == 'true_false') {
      typeInstruction = '''Each question MUST be a complete statement that is either true or false.
Example: "The mitochondria is the powerhouse of the cell." with correct_answer "True"
Example: "Water boils at 50 degrees Celsius." with correct_answer "False"
Options MUST be ["True", "False"]. Mix true and false answers.''';
    } else if (questionType == 'fillBlank' || questionType == 'fill_blank') {
      typeInstruction = 'Each question must have a ___ blank. Options should be empty. correct_answer is the missing word.';
    } else {
      typeInstruction = '''Each question must have exactly 4 options; exactly one is correct. Shuffle the correct answer's position randomly.
Write strong, plausible distractors so the answer is NOT obvious. Favour these distractor types:
- Adjacent/related criterion (a real concept that is close but not what's asked)
- Opposing theoretical construct
- Ethical-vs-legal (or similarly easy-to-confuse) distinction
- Sound-alike / look-alike term
Keep all options similar in length and grammatical form; never use "all/none of the above".''';
    }

    final style = styleInstruction.trim().isEmpty ? '' : '$styleInstruction\n\n';

    return '''<|begin_of_turn|>system
${AiConfig.instance.systemPrompt(AiOp.quiz)}
Generate EXACTLY $numQuestions questions at $difficulty difficulty — do not return fewer.

$style$typeInstruction

Keep each "explanation" to 1-2 sentences. Return ONLY valid JSON:
{"questions": [{"question": "...", "type": "$questionType", "options": [...], "correct_answer": "...", "explanation": "..."}]}<|end_of_turn|>
<|begin_of_turn|>user
Generate a quiz from this material:

$content<|end_of_turn|>
<|begin_of_turn|>assistant
{
  "questions": [''';
  }

  static String generateFlashcards({required String content, required int count}) {
    return '''<|begin_of_turn|>system
${AiConfig.instance.systemPrompt(AiOp.flashcards)}
Create exactly $count flashcards from the provided study material.

Return ONLY valid JSON in this exact format:
{
  "cards": [
    {"front": "What is X?", "back": "X is..."},
  ]
}<|end_of_turn|>
<|begin_of_turn|>user
Create flashcards from this material:

$content<|end_of_turn|>
<|begin_of_turn|>assistant
{
  "cards": [''';
  }

  static String extractTopics(String content) {
    return '''<|begin_of_turn|>system
You are a topic extractor. Identify the key topics/concepts from the study material. Return ONLY valid JSON:
{"topics": ["topic1", "topic2", ...]}<|end_of_turn|>
<|begin_of_turn|>user
Extract topics from:

$content<|end_of_turn|>
<|begin_of_turn|>assistant
{"topics": [''';
  }

  static String generateFocusQuiz({
    required String content,
    required int numQuestions,
    required String topic,
    required String difficulty,
  }) {
    return '''<|begin_of_turn|>system
You are a quiz generator. Generate exactly $numQuestions multiple choice questions specifically about "$topic" at $difficulty difficulty. Focus ONLY on this topic.

Return ONLY valid JSON in this exact format:
{
  "questions": [
    {
      "question": "...",
      "type": "mcq",
      "topic": "$topic",
      "options": ["A", "B", "C", "D"],
      "correct_answer": "A",
      "explanation": "..."
    }
  ]
}<|end_of_turn|>
<|begin_of_turn|>user
Generate a focused quiz on "$topic" from this material:

$content<|end_of_turn|>
<|begin_of_turn|>assistant
{
  "questions": [''';
  }

  static String generateStudyPlan({
    required int availableMinutes,
    required List<String> dueFlashcardDecks,
    required List<String> weakTopics,
    required List<String> recentNotebooks,
  }) {
    return '''<|begin_of_turn|>system
You are a study planner. Create a study plan for today with the available time. Prioritize weak areas and due reviews.

Available time: $availableMinutes minutes
Due flashcard decks: ${dueFlashcardDecks.join(', ')}
Weak topics needing review: ${weakTopics.join(', ')}
Active notebooks: ${recentNotebooks.join(', ')}

Return ONLY valid JSON:
{
  "tasks": [
    {
      "title": "...",
      "description": "...",
      "type": "flashcard_review|quiz_review|note_reading|weak_area_focus",
      "estimated_minutes": 15
    }
  ]
}<|end_of_turn|>
<|begin_of_turn|>user
Generate my study plan for today.<|end_of_turn|>
<|begin_of_turn|>assistant
{
  "tasks": [''';
  }

  static String explainConcept(String concept, String context) {
    return '''<|begin_of_turn|>system
You are a patient tutor. Explain the concept clearly using simple language, examples, and analogies. Use the provided context for accuracy.<|end_of_turn|>
<|begin_of_turn|>user
Context:
$context

Explain this concept: $concept<|end_of_turn|>
<|begin_of_turn|>assistant
''';
  }
}
