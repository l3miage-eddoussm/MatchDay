import 'package:flutter/material.dart';
import '../constants/cinematch_constants.dart';
import '../models/cinematch_question.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/cinematch_error_card.dart';
import '../widgets/cinematch_loading.dart';
import '../widgets/cinematch_question_card.dart';
import '../widgets/cinematch_result_card.dart';
import '../widgets/cinematch_top_bar.dart';

class CineMatchPage extends StatefulWidget {
  const CineMatchPage({super.key});

  @override
  State<CineMatchPage> createState() => _CineMatchPageState();
}

class _CineMatchPageState extends State<CineMatchPage>
    with SingleTickerProviderStateMixin {

  final Map<CineMatchAnswerKey, String> _answers = {};
  int     _step      = 0;
  bool    _isLoading = false;
  Movie?  _result;
  String? _error;

  late final AnimationController _animController;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  static final _questions  = CineMatchQuestion.all;
  static final _answerKeys = CineMatchAnswerKey.values;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _transitionTo(VoidCallback stateChange) async {
    await _animController.reverse();
    if (!mounted) return;
    setState(stateChange);
    _animController.forward();
  }

  Future<void> _pickChoice(String value) async {
    _answers[_answerKeys[_step]] = value;
    if (_step < _questions.length - 1) {
      await _transitionTo(() => _step++);
    } else {
      await _transitionTo(() => _isLoading = true);
      await _fetchMovie();
    }
  }

  Future<void> _goBack() async {
    if (_result != null || _error != null) {
      await _transitionTo(() {
        _result    = null;
        _error     = null;
        _isLoading = false;
      });
      return;
    }
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    await _transitionTo(() => _step--);
  }

  Future<void> _restart() async {
    await _transitionTo(() {
      _step      = 0;
      _answers.clear();
      _result    = null;
      _error     = null;
      _isLoading = false;
    });
  }

  Future<void> _retry() async {
    await _transitionTo(() {
      _isLoading = true;
      _result    = null;
      _error     = null;
    });
    await _fetchMovie();
  }

  Future<void> _fetchMovie() async {
    try {
      final movie = await MovieService().getMovieMatch(_answers);
      if (!mounted) return;
      await _transitionTo(() {
        _result    = movie;
        _error     = movie == null ? CineMatchConstants.noMovieFound : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      await _transitionTo(() {
        _error     = CineMatchConstants.networkError;
        _isLoading = false;
      });
    }
  }

  bool get _showingResult => _result != null || _error != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            CineMatchTopBar(
              showBack:  _step > 0 || _showingResult,
              isLoading: _isLoading,
              onBack:    _goBack,
              onRestart: _restart,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const CineMatchLoading();

    if (_result != null) {
      return CineMatchResultCard(
        movie:          _result!,
        onRetry:        _retry,
        fadeAnimation:  _fadeAnim,
        slideAnimation: _slideAnim,
      );
    }

    if (_error != null) {
      return CineMatchErrorCard(
        error:         _error!,
        onRetry:       _retry,
        onRestart:     _restart,
        fadeAnimation: _fadeAnim,
      );
    }

    return CineMatchQuestionCard(
      question:       _questions[_step],
      step:           _step,
      total:          _questions.length,
      onPick:         _pickChoice,
      fadeAnimation:  _fadeAnim,
      slideAnimation: _slideAnim,
    );
  }
}