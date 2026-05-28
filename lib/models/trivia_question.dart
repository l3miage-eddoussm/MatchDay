class TriviaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}