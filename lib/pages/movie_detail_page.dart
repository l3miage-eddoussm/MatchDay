import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/movie.dart';
import '../models/movie_credits.dart';
import '../models/movie_detail.dart';
import '../models/user_movie_action.dart';
import '../services/auth_service.dart';
import '../services/movie_action_service.dart';
import '../services/movie_service.dart';
import '../widgets/action_buttons.dart';
import '../widgets/cast_section.dart';
import '../widgets/images_section.dart';
import '../widgets/movie_info_header.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/similar_movies_section.dart';
import '../widgets/video_section.dart';
import 'collection_page.dart';
import 'trivia_quiz_page.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  UserMovieAction? _userAction;
  Movie?           _details;
  List<MovieVideo> _videos    = [];
  List<String>     _imageUrls = [];
  MovieCredits     _credits   = const MovieCredits(cast: [], directors: []);
  List<Movie>      _similar   = [];
  bool             _isLoading = true;
  String           _username  = '';

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final id      = widget.movie.id;
      final results = await Future.wait([
        MovieService().getMovieDetails(id),
        MovieService().getMovieVideos(id),
        MovieService().getMovieImages(id),
        MovieService().getMovieCredits(id),
        MovieService().getSimilarMovies(id),
      ]);

      final userAction  = MovieActionService().getAction(id);
      final currentUser = await AuthService().getCurrentUser();

      if (!mounted) return;
      setState(() {
        _details   = results[0] as Movie;
        _videos    = results[1] as List<MovieVideo>;
        _imageUrls = (results[2] as List<MovieImage>)
            .map((img) => img.imageUrl)
            .toList();
        _credits   = results[3] as MovieCredits;
        _similar   = results[4] as List<Movie>;
        _userAction = userAction;
        _username   = currentUser != null
            ? '${currentUser.firstName} ${currentUser.lastName}'
            : '';
        _isLoading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openTrailer(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleWatchLater() async {
    final movie = _details ?? widget.movie;
    MovieActionService().toggleWatchLater(
        movie.id, movie.title, movie.posterPath);
    final updated = MovieActionService().getAction(movie.id);
    if (mounted) setState(() => _userAction = updated);
  }

  Future<void> _openRatingSheet() async {
    final movie       = _details ?? widget.movie;
    final releaseYear = movie.releaseDate.length >= 4
        ? int.tryParse(movie.releaseDate.substring(0, 4))
        : null;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RatingBottomSheet(
        initialRating:  _userAction?.rating,
        initialReview:  _userAction?.review,
        onRate: (rating, review) {
          MovieActionService().rateMovie(
            movie.id,
            movie.title,
            movie.posterPath,
            rating,
            review:      review,
            releaseYear: releaseYear,
            genres:      List<String>.from(movie.genres),
            directors:   _credits.directors,
            cast:        _credits.cast,
          );
          final updated = MovieActionService().getAction(movie.id);
          if (mounted) setState(() => _userAction = updated);
        },
        onRemove: () {
          MovieActionService().removeRating(movie.id);
          final updated = MovieActionService().getAction(movie.id);
          if (mounted) setState(() => _userAction = updated);
        },
      ),
    );
  }

  Future<void> _openQuiz() async {
    final movie = _details ?? widget.movie;

    if (_userAction?.quizCompleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu as déjà complété le quiz pour ce film.'),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _QuizConfirmDialog(),
    );
    if (confirmed != true) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TriviaQuizPage(movie: movie, cast: _credits.cast),
      ),
    );

    final updated = MovieActionService().getAction(movie.id);
    if (mounted) setState(() => _userAction = updated);
  }

  Future<void> _shareReview() async {
    final movie = _details ?? widget.movie;
    try {
      final imageBytes =
      await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) return;
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/critique_${movie.id}.png');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ma critique de "${movie.title}" sur CINEART',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de générer la carte.'),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _details ?? widget.movie;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: _isLoading
              ? const Center(
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          )
              : CustomScrollView(
            slivers: [
              _buildAppBar(movie),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MovieInfoHeader(
                        movie:     movie,
                        directors: _credits.directors,
                      ),
                      const SizedBox(height: 20),
                      if (movie.belongsToCollection != null) ...[
                        _CollectionButton(movie: movie),
                        const SizedBox(height: 12),
                      ],
                      ActionButtons(
                        userAction:     _userAction,
                        onRatingTap:    _openRatingSheet,
                        onWatchLaterTap: _toggleWatchLater,
                      ),
                      if (_userAction?.rating != null) ...[
                        const SizedBox(height: 24),
                        _MyReview(
                          userAction:  _userAction!,
                          onModify:    _openRatingSheet,
                          onShare:     _shareReview,
                        ),
                        const SizedBox(height: 16),
                        _QuizButton(
                          userAction: _userAction,
                          onTap:      _openQuiz,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_credits.cast.isNotEmpty) ...[
                SliverToBoxAdapter(
                    child: SectionTitle(title: 'Casting')),
                SliverToBoxAdapter(
                    child: CastSection(cast: _credits.cast)),
              ],
              if (_videos.isNotEmpty) ...[
                SliverToBoxAdapter(
                    child: SectionTitle(title: 'Vidéos')),
                SliverToBoxAdapter(
                  child: VideoSection(
                    videos: _videos,
                    onTap:  _openTrailer,
                  ),
                ),
              ],
              if (_imageUrls.isNotEmpty) ...[
                SliverToBoxAdapter(
                    child: SectionTitle(title: 'Images')),
                SliverToBoxAdapter(
                  child: ImagesSection(imageUrls: _imageUrls),
                ),
              ],
              if (_similar.isNotEmpty) ...[
                SliverToBoxAdapter(
                    child: SectionTitle(
                        title: 'Films similaires')),
                SliverToBoxAdapter(
                  child: SimilarMoviesSection(movies: _similar),
                ),
              ],
              const SliverToBoxAdapter(
                  child: SizedBox(height: 40)),
            ],
          ),
        ),
        Positioned(
          left: -2000,
          top: 0,
          child: Screenshot(
            controller: _screenshotController,
            child: _ShareCard(
              movie:    movie,
              username: _username,
              rating:   _userAction?.rating?.toInt() ?? 0,
              review:   _userAction?.review ?? '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(Movie movie) {
    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'poster-${widget.movie.id}',
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
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.5, 1.0],
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


class _CollectionButton extends StatelessWidget {
  final Movie movie;
  const _CollectionButton({required this.movie});

  @override
  Widget build(BuildContext context) {
    final collection = movie.belongsToCollection!;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => CollectionPage(currentMovie: movie)),
      ),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.collections_bookmark_rounded,
                color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "FAIT PARTIE D'UNE COLLECTION",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    collection.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

class _QuizButton extends StatelessWidget {
  final UserMovieAction? userAction;
  final VoidCallback onTap;

  const _QuizButton({required this.userAction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final completed = userAction?.quizCompleted ?? false;
    final trophy    = userAction?.trophy;

    return GestureDetector(
      onTap: completed ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: completed
              ? const Color(0xFF0D0D0D)
              : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: trophy != null
                ? Color(trophy.color).withOpacity(0.4)
                : completed
                ? const Color(0xFF1E1E1E)
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Text(
              completed ? (trophy?.emoji ?? '🎬') : '🏆',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed
                        ? trophy != null
                        ? 'Trophée ${trophy.label} obtenu'
                        : 'Quiz complété'
                        : 'Quiz Trivia',
                    style: TextStyle(
                      color: trophy != null
                          ? Color(trophy.color)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    completed
                        ? '10 questions · tentative utilisée'
                        : '10 questions · 1 seule tentative · trophée à gagner',
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!completed)
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MyReview extends StatelessWidget {
  final UserMovieAction userAction;
  final VoidCallback onModify;
  final VoidCallback onShare;

  const _MyReview({
    required this.userAction,
    required this.onModify,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final hasReview = userAction.hasReview ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ma critique',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onModify,
              child: const Text(
                'Modifier',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasReview) ...[
          GestureDetector(
            onTap: onShare,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ios_share_rounded,
                      color: Colors.white, size: 15),
                  SizedBox(width: 7),
                  Text(
                    'Partager ma critique',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Text(
              userAction.review!,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ] else
          GestureDetector(
            onTap: onModify,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: const Text(
                'Partager votre avis sur ce film...',
                style: TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShareCard extends StatelessWidget {
  final Movie  movie;
  final String username;
  final int    rating;
  final String review;

  const _ShareCard({
    required this.movie,
    required this.username,
    required this.rating,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: 400,
        height: 600,
        child: Stack(
          fit: StackFit.expand,
          children: [
            movie.posterPath.isNotEmpty
                ? Image.network(
              '${AppConstants.tmdbImageBaseUrl}/w500${movie.posterPath}',
              fit: BoxFit.cover,
            )
                : Container(color: const Color(0xFF1A1A1A)),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xBB000000),
                    Color(0xF2000000),
                  ],
                  stops: [0.25, 0.55, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...List.generate(
                        10,
                            (i) => Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            i < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$rating/10',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      '"$review"',
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(
                        'CINEART',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizConfirmDialog extends StatelessWidget {
  const _QuizConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Quiz Trivia',
        style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800),
      ),
      content: const Text(
        "Tu ne pourras passer ce quiz qu'une seule fois.\n\nSelon ton score, tu débloques des avatars basés sur les personnages du film.\n\nBonne chance !",
        style: TextStyle(
            color: Color(0xFF888888), fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler',
              style: TextStyle(color: Color(0xFF666666))),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Commencer',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}