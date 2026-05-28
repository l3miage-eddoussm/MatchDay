import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../models/trivia_question.dart';
import '../models/user_movie_action.dart';
import '../services/movie_action_service.dart';

class TriviaQuizPage extends StatefulWidget {
  final Movie movie;
  final List<CastMember> cast;

  const TriviaQuizPage({super.key, required this.movie, required this.cast});

  @override
  State<TriviaQuizPage> createState() => _TriviaQuizPageState();
}

class _TriviaQuizPageState extends State<TriviaQuizPage> with TickerProviderStateMixin {
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
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(_progressController);
    _resultController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultAnim = CurvedAnimation(parent: _resultController, curve: Curves.easeOutBack);
    _trophyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _trophyAnim = CurvedAnimation(parent: _trophyController, curve: Curves.elasticOut);
    _buildQuestions();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _resultController.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  List<TriviaQuestion> _buildCastQuestions() {
    final cast = widget.cast;
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
      final options = [correct.character, ...wrong.map((c) => c.character)]..shuffle();
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

    return questions;
  }

  TriviaQuestion _buildYearQuestion() {
    final movie = widget.movie;
    final year = movie.releaseDate.length >= 4 ? movie.releaseDate.substring(0, 4) : '?';
    final yearInt = int.tryParse(year) ?? 2000;
    final wrongYears = ['${yearInt - 2}', '${yearInt - 1}', '${yearInt + 1}', '${yearInt + 2}']..shuffle();
    final options = [year, wrongYears[0], wrongYears[1], wrongYears[2]]..shuffle();
    return TriviaQuestion(
      question: 'En quelle année "${movie.title}" est-il sorti ?',
      options: options,
      correctIndex: options.indexOf(year),
    );
  }

  void _buildQuestions() {
    final questions = [
      ..._buildCastQuestions(),
      _buildYearQuestion(),
    ];
    setState(() => _questions = questions.take(10).toList());
    _updateProgress();
  }

  void _updateProgress() {
    _progressController.animateTo((_currentIndex + 1) / 10, curve: Curves.easeInOut);
  }

  void _onSelect(int optionIndex) {
    if (_answered) return;
    if (optionIndex == _questions[_currentIndex].correctIndex) _correctCount++;
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
        Future.delayed(const Duration(milliseconds: 300), _trophyController.forward);
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
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _quizDone
          ? _QuizResultScreen(
        correctCount: _correctCount,
        trophy: _trophy,
        movieTitle: widget.movie.title,
        resultAnim: _resultAnim,
        trophyAnim: _trophyAnim,
        onBack: () => Navigator.of(context).pop(),
      )
          : _QuizScreen(
        questions: _questions,
        currentIndex: _currentIndex,
        correctCount: _correctCount,
        selectedOption: _selectedOption,
        answered: _answered,
        progressAnim: _progressAnim,
        onSelect: _onSelect,
        onNext: _onNext,
      ),
    );
  }
}

class _QuizScreen extends StatelessWidget {
  final List<TriviaQuestion> questions;
  final int currentIndex;
  final int correctCount;
  final int? selectedOption;
  final bool answered;
  final Animation<double> progressAnim;
  final void Function(int) onSelect;
  final VoidCallback onNext;

  const _QuizScreen({
    required this.questions,
    required this.currentIndex,
    required this.correctCount,
    required this.selectedOption,
    required this.answered,
    required this.progressAnim,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(
        child: Text(
          'Pas assez de données pour générer le quiz.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 13),
        ),
      );
    }

    final question = questions[currentIndex];

    return Column(
      children: [
        _QuizProgressBar(
          currentIndex: currentIndex,
          total: questions.length,
          correctCount: correctCount,
          progressAnim: progressAnim,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestionCard(question: question.question),
                const SizedBox(height: 16),
                ...List.generate(
                  question.options.length,
                      (i) => _OptionTile(
                    label: question.options[i],
                    index: i,
                    correctIndex: question.correctIndex,
                    selectedOption: selectedOption,
                    answered: answered,
                    onTap: () => onSelect(i),
                  ),
                ),
                if (answered) ...[
                  const SizedBox(height: 8),
                  _NextButton(
                    label: currentIndex < questions.length - 1 ? 'Question suivante' : 'Voir mes résultats',
                    onTap: onNext,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizProgressBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final int correctCount;
  final Animation<double> progressAnim;

  const _QuizProgressBar({
    required this.currentIndex,
    required this.total,
    required this.correctCount,
    required this.progressAnim,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${currentIndex + 1}/$total',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            Text(
              '$correctCount correcte${correctCount > 1 ? 's' : ''}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: progressAnim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressAnim.value,
              backgroundColor: const Color(0xFF1E1E1E),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 3,
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuestionCard extends StatelessWidget {
  final String question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      question,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.4),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  final String label;
  final int index;
  final int correctIndex;
  final int? selectedOption;
  final bool answered;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.correctIndex,
    required this.selectedOption,
    required this.answered,
    required this.onTap,
  });

  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bgColor = AppColors.card;
    Color textColor = Colors.white;

    if (answered) {
      if (index == correctIndex) {
        borderColor = _green;
        bgColor = _green.withValues(alpha: 0.12);
        textColor = _green;
      } else if (index == selectedOption) {
        borderColor = _red;
        bgColor = _red.withValues(alpha: 0.12);
        textColor = _red;
      } else {
        textColor = const Color(0xFF555555);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                color: answered && index == correctIndex
                    ? _green.withValues(alpha: 0.2)
                    : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              alignment: Alignment.center,
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (answered && index == correctIndex)
              const Icon(Icons.check_circle_rounded, color: _green, size: 18),
            if (answered && index == selectedOption && index != correctIndex)
              const Icon(Icons.cancel_rounded, color: _red, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _QuizResultScreen extends StatelessWidget {
  final int correctCount;
  final TrophyLevel? trophy;
  final String movieTitle;
  final Animation<double> resultAnim;
  final Animation<double> trophyAnim;
  final VoidCallback onBack;

  const _QuizResultScreen({
    required this.correctCount,
    required this.trophy,
    required this.movieTitle,
    required this.resultAnim,
    required this.trophyAnim,
    required this.onBack,
  });

  String get _scoreLabel {
    if (correctCount == 10) return 'Parfait !';
    if (correctCount >= 7) return 'Très bon score !';
    if (correctCount >= 5) return 'Pas mal !';
    if (correctCount >= 3) return 'Peut mieux faire';
    return 'À améliorer';
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: resultAnim,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        children: [
          _ScoreCard(correctCount: correctCount, label: _scoreLabel),
          const SizedBox(height: 24),
          if (trophy != null)
            ScaleTransition(
              scale: trophyAnim,
              child: _TrophyCard(trophy: trophy!, movieTitle: movieTitle),
            )
          else
            const _NoTrophyCard(),
          const SizedBox(height: 16),
          _TrophyLegend(currentTrophy: trophy),
          const SizedBox(height: 16),
          _BackButton(onTap: onBack),
        ],
      ),
    ),
  );
}

class _ScoreCard extends StatelessWidget {
  final int correctCount;
  final String label;
  const _ScoreCard({required this.correctCount, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Text(
          '$correctCount/10',
          style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
      ],
    ),
  );
}

class _TrophyCard extends StatelessWidget {
  final TrophyLevel trophy;
  final String movieTitle;
  const _TrophyCard({required this.trophy, required this.movieTitle});

  @override
  Widget build(BuildContext context) {
    final trophyColor = Color(trophy.color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trophyColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(trophy.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'Trophée ${trophy.label}',
            style: TextStyle(color: trophyColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(movieTitle, style: const TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _NoTrophyCard extends StatelessWidget {
  const _NoTrophyCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      children: [
        Text('🎬', style: TextStyle(fontSize: 32)),
        SizedBox(height: 10),
        Text(
          'Pas de trophée cette fois',
          style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        Text(
          'Obtiens au moins 3 bonnes réponses pour décrocher un trophée Bronze.',
          style: TextStyle(color: Color(0xFF444444), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _TrophyLegend extends StatelessWidget {
  final TrophyLevel? currentTrophy;
  const _TrophyLegend({required this.currentTrophy});

  static const _levels = [
    (3, TrophyLevel.bronze),
    (5, TrophyLevel.silver),
    (7, TrophyLevel.gold),
    (10, TrophyLevel.platinum),
  ];

  @override
  Widget build(BuildContext context) => Container(
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
          style: TextStyle(color: Color(0xFF555555), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4),
        ),
        const SizedBox(height: 12),
        ..._levels.map((entry) {
          final score = entry.$1;
          final level = entry.$2;
          final isUnlocked = currentTrophy != null && currentTrophy!.index >= level.index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(level.emoji, style: TextStyle(fontSize: 18, color: isUnlocked ? null : const Color(0xFF333333))),
                const SizedBox(width: 10),
                Text(
                  level.label,
                  style: TextStyle(
                    color: isUnlocked ? Color(level.color) : const Color(0xFF444444),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  score == 10 ? '10/10' : '$score+ bonnes réponses',
                  style: TextStyle(
                    color: isUnlocked ? AppColors.muted : const Color(0xFF333333),
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

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Retour au film',
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}