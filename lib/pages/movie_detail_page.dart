import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../models/user_movie_action.dart';
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

class MovieDetailPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  UserMovieAction? _userAction;
  Movie? _details;
  List<MovieVideo> _videos = [];
  List<String> _imageUrls = [];
  List<CastMember> _cast = [];
  List<CrewMember> _directors = [];
  List<Movie> _similar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final id = widget.movie.id;
      final results = await Future.wait([
        MovieService().getMovieDetails(id),
        MovieService().getMovieVideos(id),
        MovieService().getMovieImages(id),
        MovieService().getMovieCredits(id),
        MovieService().getSimilarMovies(id),
      ]);

      final userAction = MovieActionService().getAction(id);

      setState(() {
        _details = results[0] as Movie;
        _videos = results[1] as List<MovieVideo>;
        _imageUrls = (results[2] as List<MovieImage>)
            .map((img) => img.imageUrl)
            .toList();
        final credits = results[3] as Map<String, dynamic>;
        _cast = credits['cast'] as List<CastMember>;
        _directors = credits['crew'] as List<CrewMember>;
        _similar = results[4] as List<Movie>;
        _userAction = userAction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openTrailer(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openRatingSheet() async {
    final movie = _details ?? widget.movie;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingBottomSheet(
        initialRating: _userAction?.rating,
        onRate: (rating) {
          MovieActionService().rateMovie(
              movie.id, movie.title, movie.posterPath, rating);
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

  Future<void> _toggleWatchLater() async {
    final movie = _details ?? widget.movie;
    MovieActionService().toggleWatchLater(
        movie.id, movie.title, movie.posterPath);
    final updated = MovieActionService().getAction(movie.id);
    if (mounted) setState(() => _userAction = updated);
  }

  @override
  Widget build(BuildContext context) {
    final movie = _details ?? widget.movie;

    return PopScope(
      canPop: true,
      child: Scaffold(
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MovieInfoHeader(
                      movie: movie,
                      directors: _directors,
                    ),
                    const SizedBox(height: 20),
                    ActionButtons(
                      userAction: _userAction,
                      onRatingTap: _openRatingSheet,
                      onWatchLaterTap: _toggleWatchLater,
                    ),
                  ],
                ),
              ),
            ),
            if (_cast.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionTitle(title: 'Casting')),
              SliverToBoxAdapter(child: CastSection(cast: _cast)),
            ],
            if (_videos.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionTitle(title: 'Vidéos')),
              SliverToBoxAdapter(
                child: VideoSection(
                  videos: _videos,
                  onTap: _openTrailer,
                ),
              ),
            ],
            if (_imageUrls.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionTitle(title: 'Images')),
              SliverToBoxAdapter(
                child: ImagesSection(imageUrls: _imageUrls),
              ),
            ],
            if (_similar.isNotEmpty) ...[
              SliverToBoxAdapter(
                  child: SectionTitle(title: 'Films similaires')),
              SliverToBoxAdapter(
                child: SimilarMoviesSection(movies: _similar),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
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