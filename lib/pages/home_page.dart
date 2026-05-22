import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../models/user_movie_action.dart';
import 'profile_page.dart';
import '../services/auth_service.dart';
import '../services/movie_action_service.dart';
import '../services/movie_service.dart';
import 'login_page.dart';
import 'movie_detail_page.dart';
import 'search_page.dart';
import 'cinematch_page.dart';

const List<Map<String, dynamic>> _kGenres = [
  {'id': 28,    'name': 'Action'},
  {'id': 35,    'name': 'Comédie'},
  {'id': 27,    'name': 'Horreur'},
  {'id': 878,   'name': 'Science-Fiction'},
  {'id': 16,    'name': 'Animation'},
  {'id': 53,    'name': 'Thriller'},
  {'id': 10749, 'name': 'Romance'},
  {'id': 99,    'name': 'Documentaire'},
];

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Movie>            _trending    = [];
  List<Movie>            _nowPlaying  = [];
  List<Movie>            _topRated    = [];
  List<Movie>            _upcoming    = [];
  List<UserMovieAction>  _watchLater  = [];
  final Map<int, List<Movie>> _byGenre = {};

  bool    _isLoading = true;
  String? _error;

  final PageController _heroCtrl  = PageController();
  Timer?               _heroTimer;
  int                  _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final genreFutures =
      _kGenres.map((g) => MovieService().getMoviesByGenre(g['id'] as int));

      final results = await Future.wait([
        MovieService().getTrendingMovies(),
        MovieService().getNowPlayingMovies(),
        MovieService().getTopRatedMovies(),
        MovieService().getUpcomingMovies(),
        ...genreFutures,
      ]);

      setState(() {
        _trending   = results[0] as List<Movie>;
        _nowPlaying = results[1] as List<Movie>;
        _topRated   = results[2] as List<Movie>;
        _upcoming   = results[3] as List<Movie>;
        for (int i = 0; i < _kGenres.length; i++) {
          _byGenre[_kGenres[i]['id'] as int] = results[4 + i] as List<Movie>;
        }
        _watchLater = MovieActionService().getWatchLaterList();
        _isLoading  = false;
      });

      _startHeroTimer();
    } catch (e) {
      setState(() {
        _error     = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _refreshWatchLater() {
    setState(() {
      _watchLater = MovieActionService().getWatchLaterList();
    });
  }

  void _startHeroTimer() {
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _trending.isEmpty) return;
      final next = (_heroIndex + 1) % _trending.take(5).length;
      _heroCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    MovieActionService().clearUser();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  Future<void> _openMovie(Movie movie) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MovieDetailPage(movie: movie),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _refreshWatchLater();
  }

  void _toggleWatchLaterHero(Movie movie) {
    MovieActionService().toggleWatchLater(
      movie.id,
      movie.title,
      movie.posterPath,
    );
    _refreshWatchLater();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFF4444), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeroBanner()),
          if (_watchLater.isNotEmpty)
            SliverToBoxAdapter(child: _buildWatchLaterSection()),
          SliverToBoxAdapter(child: _buildSection('Tendances',       _trending)),
          SliverToBoxAdapter(child: _buildSection('À l\'affiche',    _nowPlaying)),
          SliverToBoxAdapter(child: _buildSection('Les mieux notés', _topRated)),
          SliverToBoxAdapter(child: _buildSection('Prochainement',   _upcoming)),
          for (final genre in _kGenres)
            SliverToBoxAdapter(
              child: _buildSection(
                genre['name'] as String,
                _byGenre[genre['id']] ?? [],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.black,
      elevation: 0,
      title: const Text(
        'CINEART',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SearchPage(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.search_rounded, color: Colors.white, size: 15),
                  ),
                ),
                Container(width: 1, height: 14, color: Colors.white12),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CineMatchPage()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'CineMatch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfilePage(user: widget.user)),
            );
            if (mounted) _refreshWatchLater();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFF2A2A2A),
              child: Text(
                widget.user.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF888888), size: 18),
          onPressed: () => _logout(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFF1A1A1A)),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final heroes = _trending.take(5).toList();
    if (heroes.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          PageView.builder(
            controller: _heroCtrl,
            onPageChanged: (i) => setState(() => _heroIndex = i),
            itemCount: heroes.length,
            itemBuilder: (_, index) {
              final movie     = heroes[index];
              final inList    = MovieActionService().getAction(movie.id)?.watchLater ?? false;
              return _HeroSlide(
                movie:   movie,
                inList:  inList,
                onPlay:  () => _openMovie(movie),
                onAdd:   () => _toggleWatchLaterHero(movie),
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(heroes.length, (i) {
                final active = i == _heroIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  active ? 20 : 6,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : const Color(0xFF555555),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchLaterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Row(
            children: [
              const Text(
                'À voir plus tard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_watchLater.length}',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _watchLater.length,
            itemBuilder: (_, i) {
              final action = _watchLater[i];
              return _WatchLaterCard(
                action: action,
                onTap: () async {
                  final movie = Movie(
                    id:          action.movieId,
                    title:       action.movieTitle,
                    posterPath:  action.posterPath,
                    backdropPath: '',
                    overview:    '',
                    releaseDate: '',
                    voteAverage: 0,
                    genres:    [],
                  );
                  await _openMovie(movie);
                },
                onRemove: () {
                  MovieActionService().toggleWatchLater(
                    action.movieId,
                    action.movieTitle,
                    action.posterPath,
                  );
                  _refreshWatchLater();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Movie> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (_, i) => _PosterCard(
              movie: movies[i],
              onTap: () => _openMovie(movies[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final Movie        movie;
  final bool         inList;
  final VoidCallback onPlay;
  final VoidCallback onAdd;

  const _HeroSlide({
    required this.movie,
    required this.inList,
    required this.onPlay,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          movie.posterPath.isNotEmpty
              ? Image.network(
            movie.posterUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF1A1A1A)),
          )
              : Container(color: const Color(0xFF1A1A1A)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x55000000),
                  Colors.black,
                ],
                stops: [0.35, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            left:   20,
            right:  20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    color:       Colors.white,
                    fontSize:    28,
                    fontWeight:  FontWeight.w900,
                    height:      1.1,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HeroBtn(
                      icon:   Icons.play_arrow_rounded,
                      label:  'Regarder',
                      filled: true,
                      onTap:  onPlay,
                    ),
                    const SizedBox(width: 10),
                    _HeroBtn(
                      icon:   inList ? Icons.check : Icons.add,
                      label:  inList ? 'Dans ma liste' : 'Ma liste',
                      filled: false,
                      onTap:  onAdd,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         filled;
  final VoidCallback onTap;

  const _HeroBtn({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color:  filled ? Colors.white : Colors.transparent,
          border: filled ? null : Border.all(color: Colors.white70, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: filled ? Colors.black : Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color:      filled ? Colors.black : Colors.white,
                fontSize:   13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchLaterCard extends StatelessWidget {
  final UserMovieAction action;
  final VoidCallback    onTap;
  final VoidCallback    onRemove;

  const _WatchLaterCard({
    required this.action,
    required this.onTap,
    required this.onRemove,
  });

  String get _posterUrl =>
      'https://image.tmdb.org/t/p/w300${action.posterPath}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: action.posterPath.isNotEmpty
                          ? Image.network(
                        _posterUrl,
                        fit:   BoxFit.cover,
                        width: 110,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                          : _placeholder(),
                    ),
                    Positioned(
                      top:   4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color:  Colors.black54,
                            shape:  BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size:  12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.movieTitle,
                style: const TextStyle(
                  color:      Color(0xFFDDDDDD),
                  fontSize:   11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'À revoir',
                style: TextStyle(color: Color(0xFF666666), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF1A1A1A),
    child: const Center(
      child: Icon(Icons.movie, color: Color(0xFF333333), size: 28),
    ),
  );
}

class _PosterCard extends StatelessWidget {
  final Movie        movie;
  final VoidCallback onTap;

  const _PosterCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: movie.posterPath.isNotEmpty
                      ? Image.network(
                    movie.posterUrl,
                    fit:   BoxFit.cover,
                    width: 110,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                      : _placeholder(),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                movie.title,
                style: const TextStyle(
                  color:      Color(0xFFDDDDDD),
                  fontSize:   11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFD700), size: 10),
                  const SizedBox(width: 3),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Color(0xFF777777), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF1A1A1A),
    child: const Center(
      child: Icon(Icons.movie, color: Color(0xFF333333), size: 28),
    ),
  );
}