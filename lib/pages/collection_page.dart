import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_action_service.dart';
import '../services/movie_service.dart';
import 'movie_detail_page.dart';

class CollectionPage extends StatefulWidget {
  final Movie currentMovie;

  const CollectionPage({super.key, required this.currentMovie});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  bool _isLoading = true;
  String _collectionName = '';
  String _collectionOverview = '';
  String _backdropPath = '';
  List<Movie> _parts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final collection = widget.currentMovie.belongsToCollection;
    if (collection == null) return;
    try {
      final data = await MovieService().getCollection(collection.id);
      setState(() {
        _collectionName = data['name'] as String;
        _collectionOverview = data['overview'] as String;
        _backdropPath = data['backdropPath'] as String;
        _parts = data['parts'] as List<Movie>;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      )
          : CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTimelineItem(index),
                childCount: _parts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _backdropPath.isNotEmpty
                ? Image.network(
              'https://image.tmdb.org/t/p/w1280$_backdropPath',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1A1A1A)),
            )
                : Container(color: const Color(0xFF1A1A1A)),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xFF0A0A0A)],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${_parts.length} FILMS',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _collectionName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  if (_collectionOverview.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _collectionOverview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(int index) {
    final movie = _parts[index];
    final isCurrent = movie.id == widget.currentMovie.id;
    final isLast = index == _parts.length - 1;
    final year = movie.releaseDate.length >= 4
        ? movie.releaseDate.substring(0, 4)
        : '—';
    final userAction = MovieActionService().getAction(movie.id);
    final hasRating = userAction?.rating != null;
    final rating = userAction?.rating?.toInt() ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? Colors.white
                        : const Color(0xFF2A2A2A),
                    border: Border.all(
                      color: isCurrent
                          ? Colors.white
                          : const Color(0xFF3A3A3A),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.black
                          : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MovieDetailPage(movie: movie),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                        child: movie.posterPath.isNotEmpty
                            ? Image.network(
                          'https://image.tmdb.org/t/p/w200${movie.posterPath}',
                          width: 70,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 70,
                            height: 100,
                            color: const Color(0xFF2A2A2A),
                          ),
                        )
                            : Container(
                          width: 70,
                          height: 100,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isCurrent)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'CE FILM',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ),
                              Text(
                                movie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                year,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              if (hasRating) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                          (i) => Icon(
                                        i < (rating / 2).round()
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: Colors.white54,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$rating/10',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white24,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}