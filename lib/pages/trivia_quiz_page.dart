import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../models/user_movie_action.dart';
import '../services/movie_action_service.dart';

class TriviaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class TriviaQuizPage extends StatefulWidget {
  final Movie movie;
  final List<CastMember> cast;

  const TriviaQuizPage({super.key, required this.movie, required this.cast});

  @override
  State<TriviaQuizPage> createState() => _TriviaQuizPageState();
}

class _TriviaQuizPageState extends State<TriviaQuizPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _quizDone = false;
  TrophyLevel? _trophy;
  List<TriviaQuestion> _questions = [];

  late AnimationController _progressController;
  late Animation<double> _progressAnim;
  late AnimationController _resultController;
  late Animation<double> _resultAnim;
  late AnimationController _trophyController;
  late Animation<double> _trophyAnim;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim =
        Tween<double>(begin: 0, end: 1).animate(_progressController);
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutBack,
    );
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _trophyAnim = CurvedAnimation(
      parent: _trophyController,
      curve: Curves.elasticOut,
    );
    _buildQuestions();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _resultController.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  void _buildQuestions() {
    final cast = widget.cast;
    final movie = widget.movie;
    final questions = <TriviaQuestion>[];

    void addNameQuestion(CastMember correct) {
      final wrong = cast.where((c) => c.id != correct.id).take(3).toList();
      if (wrong.length < 3) return;
      final options = [correct.name, ...wrong.map((c) => c.name)]..shuffle();
      questions.add(TriviaQuestion(
        question: 'Quel acteur joue "${correct.character}" ?',
        options: options,
        correctIndex: options.indexOf(correct.name),
      ));
    }

    void addCharacterQuestion(CastMember correct) {
      final wrong = cast.where((c) => c.id != correct.id).take(3).toList();
      if (wrong.length < 3) return;
      final options = [correct.character, ...wrong.map((c) => c.character)]
        ..shuffle();
      questions.add(TriviaQuestion(
        question: '${correct.name} joue quel personnage ?',
        options: options,
        correctIndex: options.indexOf(correct.character),
      ));
    }

    for (int i = 0; i < cast.length && questions.length < 9; i++) {
      if (i % 2 == 0) {
        addNameQuestion(cast[i]);
      } else {
        addCharacterQuestion(cast[i]);
      }
    }

    final year = movie.releaseDate.length >= 4
        ? movie.releaseDate.substring(0, 4)
        : '?';
    final yearInt = int.tryParse(year) ?? 2000;
    final wrongYears = [
      '${yearInt - 2}',
      '${yearInt - 1}',
      '${yearInt + 1}',
      '${yearInt + 2}',
    ]..shuffle();
    final yearOptions = [year, wrongYears[0], wrongYears[1], wrongYears[2]]
      ..shuffle();
    questions.add(TriviaQuestion(
      question: 'En quelle année "${movie.title}" est-il sorti ?',
      options: yearOptions,
      correctIndex: yearOptions.indexOf(year),
    ));

    setState(() {
      _questions = questions.take(10).toList();
    });
    _updateProgress();
  }

  void _updateProgress() {
    _progressController.animateTo(
      (_currentIndex + 1) / 10,
      curve: Curves.easeInOut,
    );
  }

  void _onSelect(int optionIndex) {
    if (_answered) return;
    final isCorrect = optionIndex == _questions[_currentIndex].correctIndex;
    if (isCorrect) _correctCount++;
    setState(() {
      _selectedOption = optionIndex;
      _answered = true;
    });
  }

  void _onNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _updateProgress();
    } else {
      final trophy = trophyFromScore(_correctCount);
      MovieActionService().saveQuizResult(
        widget.movie.id,
        widget.movie.title,
        widget.movie.posterPath,
        trophy,
      );
      setState(() {
        _trophy = trophy;
        _quizDone = true;
      });
      _resultController.forward();
      if (trophy != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _trophyController.forward();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _quizDone ? 'Résultats' : 'Trivia — ${widget.movie.title}',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _quizDone ? _buildResultScreen() : _buildQuizScreen(),
    );
  }

  Widget _buildQuizScreen() {
    if (_questions.isEmpty) {
      return const Center(
        child: Text(
          'Pas assez de données pour générer le quiz.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 13),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                  Text(
                    '$_correctCount correcte${_correctCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressAnim.value,
                    backgroundColor: const Color(0xFF1E1E1E),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white),
                    minHeight: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Text(
                    question.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(question.options.length, (i) {
                  Color borderColor = const Color(0xFF2A2A2A);
                  Color bgColor = const Color(0xFF111111);
                  Color textColor = Colors.white;

                  if (_answered) {
                    if (i == question.correctIndex) {
                      borderColor = const Color(0xFF4CAF50);
                      bgColor = const Color(0xFF4CAF50).withOpacity(0.12);
                      textColor = const Color(0xFF4CAF50);
                    } else if (i == _selectedOption &&
                        i != question.correctIndex) {
                      borderColor = const Color(0xFFE53935);
                      bgColor = const Color(0xFFE53935).withOpacity(0.12);
                      textColor = const Color(0xFFE53935);
                    } else {
                      textColor = const Color(0xFF555555);
                    }
                  }

                  return GestureDetector(
                    onTap: () => _onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _answered && i == question.correctIndex
                                  ? const Color(0xFF4CAF50).withOpacity(0.2)
                                  : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: borderColor.withOpacity(0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question.options[i],
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_answered && i == question.correctIndex)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF4CAF50), size: 18),
                          if (_answered &&
                              i == _selectedOption &&
                              i != question.correctIndex)
                            const Icon(Icons.cancel_rounded,
                                color: Color(0xFFE53935), size: 18),
                        ],
                      ),
                    ),
                  );
                }),
                if (_answered) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? 'Question suivante'
                            : 'Voir mes résultats',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    final trophyColor =
    _trophy != null ? Color(_trophy!.color) : Colors.transparent;

    return ScaleTransition(
      scale: _resultAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                children: [
                  Text(
                    '$_correctCount/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _correctCount == 10
                        ? 'Parfait !'
                        : _correctCount >= 7
                        ? 'Très bon score !'
                        : _correctCount >= 5
                        ? 'Pas mal !'
                        : _correctCount >= 3
                        ? 'Peut mieux faire'
                        : 'À améliorer',
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_trophy != null) ...[
              ScaleTransition(
                scale: _trophyAnim,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: trophyColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _trophy!.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Trophée ${_trophy!.label}',
                        style: TextStyle(
                          color: trophyColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎬',
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pas de trophée cette fois',
                      style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Obtiens au moins 3 bonnes réponses pour décrocher un trophée Bronze.',
                      style:
                      TextStyle(color: Color(0xFF444444), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildTrophyLegend(),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Retour au film',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyLegend() {
    final levels = [
      (3, TrophyLevel.bronze),
      (5, TrophyLevel.silver),
      (7, TrophyLevel.gold),
      (10, TrophyLevel.platinum),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TROPHÉES',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...levels.map((entry) {
            final score = entry.$1;
            final level = entry.$2;
            final isUnlocked =
                _trophy != null && _trophy!.index >= level.index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    level.emoji,
                    style: TextStyle(
                      fontSize: 18,
                      color: isUnlocked ? null : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    level.label,
                    style: TextStyle(
                      color: isUnlocked
                          ? Color(level.color)
                          : const Color(0xFF444444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    score == 10 ? '10/10' : '$score+ bonnes réponses',
                    style: TextStyle(
                      color: isUnlocked
                          ? const Color(0xFF888888)
                          : const Color(0xFF333333),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}