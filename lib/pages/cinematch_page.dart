import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/movie.dart';
import 'movie_detail_page.dart';

class _Question {
  final String title;
  final String subtitle;
  final List<_Choice> choices;

  const _Question({
    required this.title,
    required this.subtitle,
    required this.choices,
  });
}

class _Choice {
  final String label;
  final dynamic value;

  const _Choice({required this.label, required this.value});
}

class CineMatchPage extends StatefulWidget {
  const CineMatchPage({super.key});

  @override
  State<CineMatchPage> createState() => _CineMatchPageState();
}

class _CineMatchPageState extends State<CineMatchPage>
    with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFFF0000);
  static const _card = Color(0xFF1A1A1A);

  final List<_Question> _questions = const [
    _Question(
      title: 'Comment tu te sens ce soir ?',
      subtitle: 'Ton humeur du moment',
      choices: [
        _Choice(label: 'Je veux rire', value: 'fun'),
        _Choice(label: 'Je veux avoir peur', value: 'scared'),
        _Choice(label: 'Je veux réfléchir', value: 'think'),
        _Choice(label: 'Je veux pleurer', value: 'sad'),
        _Choice(label: 'Je veux de l\'adrénaline', value: 'thrill'),
        _Choice(label: 'Je veux m\'évader', value: 'escape'),
      ],
    ),
    _Question(
      title: 'Quel style de film t\'attire ?',
      subtitle: 'Ton type préféré ce soir',
      choices: [
        _Choice(label: 'Quelque chose de réaliste', value: 'realistic'),
        _Choice(label: 'Un univers fantastique', value: 'fantasy'),
        _Choice(label: 'Basé sur des faits réels', value: 'true_story'),
        _Choice(label: 'Peu importe', value: 'any'),
      ],
    ),
    _Question(
      title: 'Tu préfères quelle époque ?',
      subtitle: 'Période de sortie',
      choices: [
        _Choice(label: 'Très récent (après 2020)', value: 'recent'),
        _Choice(label: 'Années 2000–2020', value: 'modern'),
        _Choice(label: 'Classique (avant 2000)', value: 'classic'),
        _Choice(label: 'Peu importe', value: 'any'),
      ],
    ),
    _Question(
      title: 'Combien de temps t\'as ?',
      subtitle: 'Durée du film',
      choices: [
        _Choice(label: 'Moins de 1h30', value: 'short'),
        _Choice(label: '1h30 — 2h', value: 'medium'),
        _Choice(label: 'Plus de 2h', value: 'long'),
      ],
    ),
    _Question(
      title: 'Tu regardes avec qui ?',
      subtitle: 'Ambiance du soir',
      choices: [
        _Choice(label: 'Solo', value: 'solo'),
        _Choice(label: 'En couple', value: 'couple'),
        _Choice(label: 'Entre amis', value: 'amis'),
        _Choice(label: 'En famille', value: 'famille'),
      ],
    ),
  ];

  static const Map<String, List<int>> _moodGenres = {
    'fun':    [35],
    'scared': [27, 53],
    'think':  [18, 9648],
    'sad':    [18, 10749],
    'thrill': [28, 80],
    'escape': [12, 14],
  };

  static const Map<String, double> _moodMinRating = {
    'fun':    6.5,
    'scared': 6.0,
    'think':  7.0,
    'sad':    6.5,
    'thrill': 6.5,
    'escape': 6.5,
  };

  static const Map<String, List<int>> _audienceExcludedGenres = {
    'famille': [27, 53, 80, 9648],
    'couple':  [],
    'amis':    [],
    'solo':    [],
  };

  static const Map<String, int> _audienceBonusGenre = {
    'famille': 16,
    'couple':  10749,
    'amis':    35,
    'solo':    0,
  };

  static const Map<String, List<int>> _styleGenres = {
    'realistic': [18, 36],
    'fantasy':   [14, 878, 16],
    'true_story': [36, 99],
    'any':       [],
  };

  int _step = 0;
  final Map<int, dynamic> _answers = {};
  bool _isLoading = false;
  Movie? _result;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickChoice(dynamic value) async {
    _answers[_step] = value;
    if (_step < _questions.length - 1) {
      await _animController.reverse();
      if (!mounted) return;
      setState(() => _step++);
      _animController.forward();
    } else {
      await _animController.reverse();
      if (!mounted) return;
      setState(() => _isLoading = true);
      await _fetchMovie();
    }
  }

  Future<void> _goBack() async {
    if (_result != null || _error != null) {
      await _animController.reverse();
      if (!mounted) return;
      setState(() {
        _result = null;
        _error = null;
        _isLoading = false;
      });
      _animController.forward();
      return;
    }
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    await _animController.reverse();
    if (!mounted) return;
    setState(() => _step--);
    _animController.forward();
  }

  Future<void> _restart() async {
    await _animController.reverse();
    if (!mounted) return;
    setState(() {
      _step = 0;
      _answers.clear();
      _result = null;
      _error = null;
      _isLoading = false;
    });
    _animController.forward();
  }

  Future<void> _fetchMovie() async {
    try {
      final mood     = _answers[0] as String;
      final style    = _answers[1] as String;
      final era      = _answers[2] as String;
      final duration = _answers[3] as String;
      final audience = _answers[4] as String;

      final excludedGenres = List<int>.from(_audienceExcludedGenres[audience] ?? []);
      final bonusGenre     = _audienceBonusGenre[audience] ?? 0;

      final moodGenreList  = List<int>.from(_moodGenres[mood] ?? [18]);
      final styleGenreList = List<int>.from(_styleGenres[style] ?? []);

      final Set<int> genreSet = {};
      for (final g in [...moodGenreList, ...styleGenreList]) {
        if (!excludedGenres.contains(g)) genreSet.add(g);
      }
      if (bonusGenre > 0 && !excludedGenres.contains(bonusGenre)) {
        genreSet.add(bonusGenre);
      }

      final genreParam = genreSet.isNotEmpty ? genreSet.join(',') : '18';
      final minRating  = (_moodMinRating[mood] ?? 6.5).clamp(5.0, 9.0);

      final rng  = Random();
      final page = rng.nextInt(8) + 1;

      final buffer = StringBuffer(
        '${AppConstants.tmdbBaseUrl}/discover/movie'
            '?language=fr-FR'
            '&sort_by=popularity.desc'
            '&vote_count.gte=200'
            '&vote_average.gte=$minRating'
            '&with_genres=$genreParam'
            '&page=$page',
      );

      switch (duration) {
        case 'short':
          buffer.write('&with_runtime.lte=89');
          break;
        case 'medium':
          buffer.write('&with_runtime.gte=90&with_runtime.lte=120');
          break;
        case 'long':
          buffer.write('&with_runtime.gte=121');
          break;
      }

      switch (era) {
        case 'recent':
          buffer.write('&primary_release_date.gte=2020-01-01');
          break;
        case 'modern':
          buffer.write(
              '&primary_release_date.gte=2000-01-01'
                  '&primary_release_date.lte=2019-12-31');
          break;
        case 'classic':
          buffer.write('&primary_release_date.lte=1999-12-31');
          break;
      }

      if (audience == 'famille') {
        buffer.write('&without_genres=27,53,80,9648');
      }

      final response = await http.get(
        Uri.parse(buffer.toString()),
        headers: {
          'Authorization': 'Bearer ${AppConstants.tmdbToken}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        await _animController.reverse();
        setState(() {
          _error = 'Aucun film trouvé.\nEssaie d\'autres réponses !';
          _isLoading = false;
        });
        _animController.forward();
        return;
      }

      final data    = jsonDecode(response.body);
      final results = data['results'] as List? ?? [];

      if (results.isEmpty) {
        await _fetchMovieFallback(mood, era, duration);
        return;
      }

      final picked = results[rng.nextInt(min(results.length, 15))];
      final movie  = Movie.fromJson(picked as Map<String, dynamic>);

      await _animController.reverse();
      if (!mounted) return;
      setState(() {
        _result    = movie;
        _isLoading = false;
      });
      _animController.forward();
    } catch (_) {
      if (!mounted) return;
      await _animController.reverse();
      setState(() {
        _error    = 'Une erreur est survenue.\nVérifie ta connexion et réessaie.';
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  Future<void> _fetchMovieFallback(
      String mood, String era, String duration) async {
    try {
      final moodGenreList = List<int>.from(_moodGenres[mood] ?? [18]);
      final genreParam    = moodGenreList.first.toString();
      final minRating     = (_moodMinRating[mood] ?? 6.0) - 0.5;

      final buffer = StringBuffer(
        '${AppConstants.tmdbBaseUrl}/discover/movie'
            '?language=fr-FR'
            '&sort_by=popularity.desc'
            '&vote_count.gte=100'
            '&vote_average.gte=$minRating'
            '&with_genres=$genreParam'
            '&page=${Random().nextInt(5) + 1}',
      );

      switch (era) {
        case 'recent':
          buffer.write('&primary_release_date.gte=2020-01-01');
          break;
        case 'modern':
          buffer.write(
              '&primary_release_date.gte=2000-01-01'
                  '&primary_release_date.lte=2019-12-31');
          break;
        case 'classic':
          buffer.write('&primary_release_date.lte=1999-12-31');
          break;
      }

      final response = await http.get(
        Uri.parse(buffer.toString()),
        headers: {
          'Authorization': 'Bearer ${AppConstants.tmdbToken}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      final data    = jsonDecode(response.body);
      final results = data['results'] as List? ?? [];

      if (results.isEmpty) {
        await _animController.reverse();
        if (!mounted) return;
        setState(() {
          _error    = 'Aucun film trouvé.\nEssaie d\'autres réponses !';
          _isLoading = false;
        });
        _animController.forward();
        return;
      }

      final picked = results[Random().nextInt(min(results.length, 15))];
      final movie  = Movie.fromJson(picked as Map<String, dynamic>);

      await _animController.reverse();
      if (!mounted) return;
      setState(() {
        _result    = movie;
        _isLoading = false;
      });
      _animController.forward();
    } catch (_) {
      if (!mounted) return;
      await _animController.reverse();
      setState(() {
        _error    = 'Une erreur est survenue.\nVérifie ta connexion et réessaie.';
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  Future<void> _retry() async {
    await _animController.reverse();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _result    = null;
      _error     = null;
    });
    await _fetchMovie();
  }

  bool get _showingResult => _result != null || _error != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _result != null
                  ? _buildResult()
                  : _error != null
                  ? _buildError()
                  : _buildQuestion(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final showBack = _step > 0 || _showingResult;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(
                showBack
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.close_rounded,
                color: Colors.white70,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CineMatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading)
            GestureDetector(
              onTap: _restart,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Text(
                  'Recommencer',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_step + 1) / _questions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFF1A1A1A),
          valueColor: const AlwaysStoppedAnimation<Color>(_red),
          minHeight: 3,
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final q = _questions[_step];
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
              child: Text(
                q.subtitle.toUpperCase(),
                style: const TextStyle(
                  color: _red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                q.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: q.choices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final choice = q.choices[i];
                  return GestureDetector(
                    onTap: () => _pickChoice(choice.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        border:
                        Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              choice.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF444444),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: _red,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'On cherche ton film parfait...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Un instant',
            style: TextStyle(color: Color(0xFF555555), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final movie = _result!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VOTRE FILM CE SOIR',
                style: TextStyle(
                  color: _red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'On a trouvé !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MovieDetailPage(movie: movie),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      movie.posterPath.isNotEmpty
                          ? Image.network(
                        movie.posterUrl,
                        width: double.infinity,
                        height: 420,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 420,
                          color: _card,
                          child: const Center(
                            child: Icon(Icons.movie,
                                color: Color(0xFF333333), size: 60),
                          ),
                        ),
                      )
                          : Container(
                        height: 420,
                        color: _card,
                        child: const Center(
                          child: Icon(Icons.movie,
                              color: Color(0xFF333333), size: 60),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xEE000000),
                              ],
                              stops: [0.3, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.white, size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.voteAverage.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    ' / 10',
                                    style: TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 13),
                                  ),
                                  if (movie.releaseDate.length >= 4) ...[
                                    const SizedBox(width: 14),
                                    Text(
                                      movie.releaseDate.substring(0, 4),
                                      style: const TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (movie.overview.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  movie.overview,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MovieDetailPage(movie: movie),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Voir le film',
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _retry,
                  style: TextButton.styleFrom(
                    backgroundColor: _card,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                  ),
                  child: const Text(
                    'Autre suggestion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style:
                    TextStyle(color: Color(0xFF666666), fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(Icons.movie_filter_outlined,
                      color: Color(0xFF444444), size: 32),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Réessayer',
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _restart,
                  style: TextButton.styleFrom(
                    backgroundColor: _card,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                  ),
                  child: const Text(
                    'Changer mes réponses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}