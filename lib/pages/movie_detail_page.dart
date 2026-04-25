import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../models/user_movie_action.dart';
import '../services/movie_action_service.dart';
import '../services/movie_service.dart';
import '../widgets/image_gallery_viewer.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../widgets/section_title.dart';

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
  List<MovieImage> _images = [];
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
        _images = results[2] as List<MovieImage>;
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
    final int movieId = (_details ?? widget.movie).id;
    final String movieTitle = (_details ?? widget.movie).title;
    final String moviePoster = (_details ?? widget.movie).posterPath;
    final double? currentRating = _userAction?.rating;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingBottomSheet(
        initialRating: currentRating,
        onRate: (rating) {
          MovieActionService().rateMovie(movieId, movieTitle, moviePoster, rating);
          final updated = MovieActionService().getAction(movieId);
          if (mounted) setState(() => _userAction = updated);
        },
        onRemove: () {
          MovieActionService().removeRating(movieId);
          final updated = MovieActionService().getAction(movieId);
          if (mounted) setState(() => _userAction = updated);
        },
      ),
    );
  }

  Future<void> _toggleWatchLater() async {
    final int movieId = (_details ?? widget.movie).id;
    final String movieTitle = (_details ?? widget.movie).title;
    final String moviePoster = (_details ?? widget.movie).posterPath;

    MovieActionService().toggleWatchLater(movieId, movieTitle, moviePoster);
    final updated = MovieActionService().getAction(movieId);
    if (mounted) setState(() => _userAction = updated);
  }

  @override
  Widget build(BuildContext context) {
    final movie = _details ?? widget.movie;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 15),
                      const SizedBox(width: 5),
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
                          color: Color(0xFF666666),
                          fontSize: 13,
                        ),
                      ),
                      if (movie.releaseDate.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF666666), size: 13),
                        const SizedBox(width: 5),
                        Text(
                          movie.releaseDate.substring(0, 4),
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (movie.genres.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: movie.genres
                          .map(
                            (g) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF444444)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            g,
                            style: const TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _openRatingSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: _userAction?.rating != null
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF2A2A2A)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _userAction?.rating != null
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: _userAction?.rating != null
                                      ? Colors.black
                                      : Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _userAction?.rating != null
                                      ? '${_userAction!.rating!.toInt()} / 10'
                                      : 'Noter',
                                  style: TextStyle(
                                    color: _userAction?.rating != null
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleWatchLater,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: (_userAction?.watchLater ?? false)
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF2A2A2A)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  (_userAction?.watchLater ?? false)
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_outline_rounded,
                                  color: (_userAction?.watchLater ?? false)
                                      ? Colors.black
                                      : Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (_userAction?.watchLater ?? false)
                                      ? 'Sauvegardé'
                                      : 'Voir plus tard',
                                  style: TextStyle(
                                    color: (_userAction?.watchLater ?? false)
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_directors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Réalisateur : ',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _directors.map((d) => d.name).join(', '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Synopsis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie.overview.isNotEmpty
                        ? movie.overview
                        : 'Aucun synopsis disponible.',
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_cast.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionTitle(title: 'Casting')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _cast.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final member = _cast[index];
                    return SizedBox(
                      width: 80,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: member.profilePath.isNotEmpty
                                ? Image.network(
                              member.profileUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(),
                            )
                                : _avatarFallback(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            member.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.character,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (_videos.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionTitle(title: 'Vidéos')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _videos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return GestureDetector(
                      onTap: () => _openTrailer(video.youtubeUrl),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              video.thumbnailUrl,
                              width: 200,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 200,
                                height: 120,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          Container(
                            width: 200,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
                          const Icon(Icons.play_circle_filled,
                              color: Colors.white, size: 44),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Text(
                              video.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (_images.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionTitle(title: 'Images')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => ImageGalleryViewer(
                          imageUrls: _images
                              .map((img) => img.imageUrl)
                              .toList(),
                          initialIndex: index,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _images[index].imageUrl,
                        width: 260,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 260,
                          height: 160,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_similar.isNotEmpty) ...[
            SliverToBoxAdapter(
                child: SectionTitle(title: 'Films similaires')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _similar.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final similar = _similar[index];
                    return GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieDetailPage(movie: similar),
                            ),
                          ),
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: similar.posterPath.isNotEmpty
                                  ? Image.network(
                                similar.posterUrl,
                                width: 120,
                                height: 170,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(
                                      width: 120,
                                      height: 170,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                              )
                                  : Container(
                                width: 120,
                                height: 170,
                                color: const Color(0xFF1A1A1A),
                                child: const Icon(Icons.movie,
                                    color: Color(0xFF333333)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              similar.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFF1A1A1A),
      child: const Icon(Icons.person, color: Color(0xFF333333), size: 36),
    );
  }

  Widget _buildAppBar(Movie movie) {
    return SliverAppBar(
      expandedHeight: 480,
      pinned: true,
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            movie.backdropPath.isNotEmpty
                ? Image.network(
              movie.backdropUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _posterFallback(movie),
            )
                : _posterFallback(movie),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterFallback(Movie movie) {
    return movie.posterPath.isNotEmpty
        ? Image.network(movie.posterUrl, fit: BoxFit.cover)
        : Container(
      color: const Color(0xFF1A1A1A),
      child: const Icon(Icons.movie, color: Color(0xFF333333), size: 60),
    );
  }
}