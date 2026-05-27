import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/movie.dart';
import '../models/movie_credits.dart';
import '../models/movie_detail.dart';
import '../models/user_movie_action.dart';
import '../services/auth_service.dart';
import '../services/movie_action_service.dart';
import '../services/movie_service.dart';
import '../services/share_service.dart';
import '../widgets/action_buttons.dart';
import '../widgets/cast_section.dart';
import '../widgets/images_section.dart';
import '../widgets/movie_info_header.dart';
import '../widgets/movie_poster_placeholder.dart';
import '../widgets/quiz_confirm_dialog.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/share_card.dart';
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

  Movie get _movie => _details ?? widget.movie;

  int? get _releaseYear {
    final date = _movie.releaseDate;
    return date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final id = widget.movie.id;

      final movieFuture   = MovieService().getMovieDetails(id);
      final videosFuture  = MovieService().getMovieVideos(id);
      final imagesFuture  = MovieService().getMovieImages(id);
      final creditsFuture = MovieService().getMovieCredits(id);
      final similarFuture = MovieService().getSimilarMovies(id);

      final (movie, videos, images, credits, similar) = await (
      movieFuture,
      videosFuture,
      imagesFuture,
      creditsFuture,
      similarFuture,
      ).wait;

      final userAction  = MovieActionService().getAction(id);
      final currentUser = await AuthService().getCurrentUser();

      if (!mounted) return;
      setState(() {
        _details    = movie;
        _videos     = videos;
        _imageUrls  = images.map((img) => img.imageUrl).toList();
        _credits    = credits;
        _similar    = similar;
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
    MovieActionService().toggleWatchLater(
        _movie.id, _movie.title, _movie.posterPath);
    _refreshUserAction();
  }

  void _refreshUserAction() {
    final updated = MovieActionService().getAction(_movie.id);
    if (mounted) setState(() => _userAction = updated);
  }

  void _onRate(double rating, String? review) {
    MovieActionService().rateMovie(
      _movie.id,
      _movie.title,
      _movie.posterPath,
      rating,
      review:      review,
      releaseYear: _releaseYear,
      genres:      List<String>.from(_movie.genres),
      directors:   _credits.directors,
      cast:        _credits.cast,
    );
    _refreshUserAction();
  }

  void _onRemoveRating() {
    MovieActionService().removeRating(_movie.id);
    _refreshUserAction();
  }

  Future<void> _openRatingSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RatingBottomSheet(
        initialRating: _userAction?.rating,
        initialReview: _userAction?.review,
        onRate:        _onRate,
        onRemove:      _onRemoveRating,
      ),
    );
  }

  Future<void> _openQuiz() async {
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
      builder: (_) => const QuizConfirmDialog(),
    );
    if (confirmed != true) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TriviaQuizPage(movie: _movie, cast: _credits.cast),
      ),
    );

    _refreshUserAction();
  }

  Future<void> _shareReview() async {
    try {
      await ShareService().shareReview(
          _screenshotController, _movie.title, _movie.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de générer la carte.'),
          backgroundColor: AppColors.surfaceDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildAppBar(_movie),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MovieInfoHeader(
                        movie:     _movie,
                        directors: _credits.directors,
                      ),
                      const SizedBox(height: 20),
                      if (_movie.belongsToCollection != null) ...[
                        _CollectionButton(movie: _movie),
                        const SizedBox(height: 12),
                      ],
                      ActionButtons(
                        userAction:      _userAction,
                        onRatingTap:     _openRatingSheet,
                        onWatchLaterTap: _toggleWatchLater,
                      ),
                      if (_userAction?.rating != null) ...[
                        const SizedBox(height: 24),
                        _MyReview(
                          userAction: _userAction!,
                          onModify:   _openRatingSheet,
                          onShare:    _shareReview,
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
                      videos: _videos, onTap: _openTrailer),
                ),
              ],
              if (_imageUrls.isNotEmpty) ...[
                SliverToBoxAdapter(
                    child: SectionTitle(title: 'Images')),
                SliverToBoxAdapter(
                    child: ImagesSection(imageUrls: _imageUrls)),
              ],
              if (_similar.isNotEmpty) ...[
                SliverToBoxAdapter(
                    child: SectionTitle(title: 'Films similaires')),
                SliverToBoxAdapter(
                    child: SimilarMoviesSection(movies: _similar)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
        Positioned(
          left: -2000,
          top: 0,
          child: Screenshot(
            controller: _screenshotController,
            child: ShareCard(
              movie:    _movie,
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
                const MoviePosterPlaceholder(),
              )
                  : const MoviePosterPlaceholder(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: completed ? const Color(0xFF0D0D0D) : const Color(0xFF141414),
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
                      color: trophy != null ? Color(trophy.color) : Colors.white,
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
                        color: Color(0xFF555555), fontSize: 11),
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
        if (userAction.hasReview) ...[
          GestureDetector(
            onTap: onShare,
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.white.withOpacity(0.4)),
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
                border: Border.all(color: const Color(0xFF2A2A2A)),
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