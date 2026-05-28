import 'package:cineart/models/trivia_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TriviaQuestion', () {
    const question = TriviaQuestion(
      question: 'Quel acteur joue Batman ?',
      options: ['Christian Bale', 'Ben Affleck', 'Michael Keaton', 'Adam West'],
      correctIndex: 0,
    );

    test('les champs sont bien initialisés', () {
      expect(question.question, 'Quel acteur joue Batman ?');
      expect(question.options.length, 4);
      expect(question.correctIndex, 0);
    });

    test('correctIndex pointe sur la bonne option', () {
      expect(question.options[question.correctIndex], 'Christian Bale');
    });

    test('correctIndex est dans les bornes des options', () {
      expect(question.correctIndex, greaterThanOrEqualTo(0));
      expect(question.correctIndex, lessThan(question.options.length));
    });
  });
}