/// How quiz questions are framed cognitively (Bloom's taxonomy). Lets the
/// student choose recall vs. situational/application vs. higher-order analysis.
enum QuizStyle { mixed, recall, application, analysis }

extension QuizStyleX on QuizStyle {
  String get label => switch (this) {
        QuizStyle.mixed => "Mixed (Bloom's)",
        QuizStyle.recall => 'Recall',
        QuizStyle.application => 'Application',
        QuizStyle.analysis => 'Critical',
      };

  String get description => switch (this) {
        QuizStyle.mixed =>
          'A spread across Bloom\'s levels, weighted to application',
        QuizStyle.recall => 'Definitions, facts & comprehension',
        QuizStyle.application => 'Situational scenarios — apply the concept',
        QuizStyle.analysis => 'Analyze, compare & judge the best option',
      };

  /// Cognitive instruction injected into the quiz prompt.
  String get promptInstruction => switch (this) {
        QuizStyle.mixed =>
          'Spread the questions across Bloom\'s taxonomy levels (Remember, '
              'Understand, Apply, Analyze, Evaluate), weighting toward Apply '
              'and Analyze. At least half should be situational/scenario-based '
              'where the student applies a concept to a realistic new context.',
        QuizStyle.recall =>
          'Target Bloom\'s Remember and Understand levels: test definitions, '
              'key facts, terminology and comprehension of the material.',
        QuizStyle.application =>
          'Target Bloom\'s Apply level. Write SITUATIONAL questions: each stem '
              'is a short realistic vignette/case where the student must apply '
              'a concept to a new context, not just recall it. Make the stems '
              'longer and concrete.',
        QuizStyle.analysis =>
          'Target Bloom\'s Analyze and Evaluate levels. Require the student to '
              'compare, distinguish, prioritize or judge the BEST option among '
              'close alternatives, using rich scenario-based stems.',
      };
}
