import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../constants/genre_constants.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../models/user_movie_action.dart';
import '../services/auth_service.dart';
import '../services/movie_action_service.dart';
import '../services/movie_service.dart';
import 'cinematch_page.dart';
import 'login_page.dart';
import 'movie_detail_page.dart';
import 'profile_page.dart';
import 'search_page.dart';


class _SectionState {
  List<Movie> movies;
  int currentPage;
  bool isLoadingMore;

  _SectionState({
    this.movies = const [],
    this.currentPage = 1,
    this.isLoadingMore = false,
  });
}

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late _SectionState _trending;
  late _SectionState _nowPlaying;
  late _SectionState _topRated;
  late _SectionState _upcoming;
  final Map<int, _SectionState> _byGenre = {};

  List<UserMovieAction> _watchLater = [];
  bool _isLoading = true;
  String? _error;

  final PageController _heroCtrl = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    _trending   = _SectionState();
    _nowPlaying = _SectionState();
    _topRated   = _SectionState();
    _upcoming   = _SectionState();
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
      final genreFutures = GenreConstants.genres
          .map((g) => MovieService().getMoviesByGenre(g.id));

      final results = await Future.wait([
        MovieService().getTrendingMovies(),
        MovieService().getNowPlayingMovies(),
        MovieService().getTopRatedMovies(),
        MovieService().getUpcomingMovies(),
        ...genreFutures,
      ]);

      setState(() {
        _trending   = _SectionState(movies: results[0]);
        _nowPlaying = _SectionState(movies: results[1]);
        _topRated   = _SectionState(movies: results[2]);
        _upcoming   = _SectionState(movies: results[3]);
        for (int i = 0; i < GenreConstants.genres.length; i++) {
          _byGenre[GenreConstants.genres[i].id] =
              _SectionState(movies: results[4 + i]);
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

  Future<void> _loadMore(
      _SectionState section,
      Future<List<Movie>> Function(int) fetcher,
      ) async {
    if (section.isLoadingMore) return;
    setState(() => section.isLoadingMore = true);
    try {
      final next = await fetcher(section.currentPage + 1);
      setState(() {
        section.movies      = [...section.movies, ...next];
        section.currentPage++;
        section.isLoadingMore = false;
      });
    } catch (_) {
      setState(() => section.isLoadingMore = false);
    }
  }

  void _refreshWatchLater() {
    setState(() => _watchLater = MovieActionService().getWatchLaterList());
  }

  void _startHeroTimer() {
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _trending.movies.isEmpty) return;
      final next = (_heroIndex + 1) % _trending.movies.take(5).length;
      _heroCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
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
        movie.id, movie.title, movie.posterPath);
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
          _HomeAppBar(
            user:       widget.user,
            onSearch:   () => Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SearchPage(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            )),
            onCineMatch: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CineMatchPage()),
            ),
            onProfile: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              if (mounted) _refreshWatchLater();
            },
            onLogout: _logout,
          ),
          SliverToBoxAdapter(
            child: _HeroBanner(
              movies:     _trending.movies.take(5).toList(),
              heroIndex:  _heroIndex,
              heroCtrl:   _heroCtrl,
              watchLater: _watchLater,
              onPageChanged: (i) => setState(() => _heroIndex = i),
              onPlay:     _openMovie,
              onToggle:   _toggleWatchLaterHero,
            ),
          ),
          if (_watchLater.isNotEmpty)
            SliverToBoxAdapter(
              child: _WatchLaterSection(
                watchLater:  _watchLater,
                onTap:       (action) => _openMovie(Movie(
                  id:           action.movieId,
                  title:        action.movieTitle,
                  posterPath:   action.posterPath,
                  backdropPath: '',
                  overview:     '',
                  releaseDate:  '',
                  voteAverage:  0,
                  genres:       [],
                )),
                onRemove: (action) {
                  MovieActionService().toggleWatchLater(
                      action.movieId, action.movieTitle, action.posterPath);
                  _refreshWatchLater();
                },
              ),
            ),
          SliverToBoxAdapter(
            child: _MovieSection(
              title:   'Tendances',
              section: _trending,
              fetcher: (p) => MovieService().getTrendingMovies(page: p),
              onTap:   _openMovie,
              onMore:  _loadMore,
            ),
          ),
          SliverToBoxAdapter(
            child: _MovieSection(
              title:   "À l'affiche",
              section: _nowPlaying,
              fetcher: (p) => MovieService().getNowPlayingMovies(page: p),
              onTap:   _openMovie,
              onMore:  _loadMore,
            ),
          ),
          SliverToBoxAdapter(
            child: _MovieSection(
              title:   'Les mieux notés',
              section: _topRated,
              fetcher: (p) => MovieService().getTopRatedMovies(page: p),
              onTap:   _openMovie,
              onMore:  _loadMore,
            ),
          ),
          SliverToBoxAdapter(
            child: _MovieSection(
              title:   'Prochainement',
              section: _upcoming,
              fetcher: (p) => MovieService().getUpcomingMovies(page: p),
              onTap:   _openMovie,
              onMore:  _loadMore,
            ),
          ),
          for (final genre in GenreConstants.genres)
            SliverToBoxAdapter(
              child: _MovieSection(
                title:   genre.name,
                section: _byGenre[genre.id] ?? _SectionState(),
                fetcher: (p) =>
                    MovieService().getMoviesByGenre(genre.id, page: p),
                onTap:  _openMovie,
                onMore: _loadMore,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  final User user;
  final VoidCallback onSearch;
  final VoidCallback onCineMatch;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _HomeAppBar({
    required this.user,
    required this.onSearch,
    required this.onCineMatch,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
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
                  onTap: onSearch,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.search_rounded,
                        color: Colors.white, size: 15),
                  ),
                ),
                Container(width: 1, height: 14, color: Colors.white12),
                GestureDetector(
                  onTap: onCineMatch,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 13),
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
          onTap: onProfile,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFF2A2A2A),
              child: Text(
                user.firstName[0].toUpperCase(),
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
          icon: const Icon(Icons.logout,
              color: Color(0xFF888888), size: 18),
          onPressed: onLogout,
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
}

class _HeroBanner extends StatelessWidget {
  final List<Movie> movies;
  final int heroIndex;
  final PageController heroCtrl;
  final List<UserMovieAction> watchLater;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function(Movie) onPlay;
  final void Function(Movie) onToggle;

  const _HeroBanner({
    required this.movies,
    required this.heroIndex,
    required this.heroCtrl,
    required this.watchLater,
    required this.onPageChanged,
    required this.onPlay,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          PageView.builder(
            controller: heroCtrl,
            onPageChanged: onPageChanged,
            itemCount: movies.length,
            itemBuilder: (_, index) {
              final movie  = movies[index];
              final inList = MovieActionService()
                  .getAction(movie.id)
                  ?.watchLater ??
                  false;
              return _HeroSlide(
                movie:  movie,
                inList: inList,
                onPlay: () => onPlay(movie),
                onAdd:  () => onToggle(movie),
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(movies.length, (i) {
                final active = i == heroIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  active ? 20 : 6,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : const Color(0xFF555555),
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
}

class _WatchLaterSection extends StatelessWidget {
  final List<UserMovieAction> watchLater;
  final void Function(UserMovieAction) onTap;
  final void Function(UserMovieAction) onRemove;

  const _WatchLaterSection({
    required this.watchLater,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${watchLater.length}',
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
            itemCount: watchLater.length,
            itemBuilder: (_, i) => _WatchLaterCard(
              action:   watchLater[i],
              onTap:    () => onTap(watchLater[i]),
              onRemove: () => onRemove(watchLater[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _MovieSection extends StatelessWidget {
  final String title;
  final _SectionState section;
  final Future<List<Movie>> Function(int) fetcher;
  final Future<void> Function(Movie) onTap;
  final Future<void> Function(_SectionState, Future<List<Movie>> Function(int)) onMore;

  const _MovieSection({
    required this.title,
    required this.section,
    required this.fetcher,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    if (section.movies.isEmpty) return const SizedBox.shrink();
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
            itemCount: section.movies.length + 1,
            itemBuilder: (_, i) {
              if (i == section.movies.length) {
                return _LoadMoreButton(
                  isLoadingMore: section.isLoadingMore,
                  onTap: () => onMore(section, fetcher),
                );
              }
              return _PosterCard(
                movie: section.movies[i],
                onTap: () => onTap(section.movies[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool isLoadingMore;
  final VoidCallback onTap;

  const _LoadMoreButton(
      {required this.isLoadingMore, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Center(
          child: isLoadingMore
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                color: Colors.white54, strokeWidth: 2),
          )
              : const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white38, size: 22),
              SizedBox(height: 6),
              Text(
                'Suite',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final Movie movie;
  final bool inList;
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
                end: Alignment.bottomCenter,
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
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 8)
                    ],
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
  final IconData icon;
  final String label;
  final bool filled;
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
          color: filled ? Colors.white : Colors.transparent,
          border: filled
              ? null
              : Border.all(color: Colors.white70, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17,
                color: filled ? Colors.black : Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.black : Colors.white,
                fontSize: 13,
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
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _WatchLaterCard({
    required this.action,
    required this.onTap,
    required this.onRemove,
  });

  Widget _placeholder() => Container(
    color: const Color(0xFF1A1A1A),
    child: const Center(
      child:
      Icon(Icons.movie, color: Color(0xFF333333), size: 28),
    ),
  );

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
                        '${AppConstants.tmdbImageBaseUrl}/w300${action.posterPath}',
                        fit: BoxFit.cover,
                        width: 110,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(),
                      )
                          : _placeholder(),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 12),
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
                  color: Color(0xFFDDDDDD),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'À revoir',
                style:
                TextStyle(color: Color(0xFF666666), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _PosterCard({required this.movie, required this.onTap});

  Widget _placeholder() => Container(
    color: const Color(0xFF1A1A1A),
    child: const Center(
      child:
      Icon(Icons.movie, color: Color(0xFF333333), size: 28),
    ),
  );

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
                    fit: BoxFit.cover,
                    width: 110,
                    errorBuilder: (_, __, ___) =>
                        _placeholder(),
                  )
                      : _placeholder(),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                movie.title,
                style: const TextStyle(
                  color: Color(0xFFDDDDDD),
                  fontSize: 11,
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
}