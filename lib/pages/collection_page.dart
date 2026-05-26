import 'package:flutter/material.dart';
import '../models/collection_detail.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/collection_movie_card.dart';
import '../widgets/collection_timeline_dot.dart';

class CollectionPage extends StatefulWidget {
  final Movie currentMovie;

  const CollectionPage({super.key, required this.currentMovie});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  bool _isLoading = true;
  CollectionDetail? _collection;

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
        _collection = data;
        _isLoading  = false;
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
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2),
      )
          : CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTimelineItem(index),
                childCount: _collection?.parts.length ?? 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final collection = _collection;
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
            collection != null && collection.backdropPath.isNotEmpty
                ? Image.network(
              collection.backdropUrl,
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
            if (collection != null)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        '${collection.parts.length} FILMS',
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
                      collection.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (collection.overview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        collection.overview,
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
    final parts   = _collection!.parts;
    final movie   = parts[index];
    final isLast  = index == parts.length - 1;
    final isCurrent = movie.id == widget.currentMovie.id;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CollectionTimelineDot(
            index:     index,
            isCurrent: isCurrent,
            isLast:    isLast,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CollectionMovieCard(
              movie:     movie,
              isCurrent: isCurrent,
              isLast:    isLast,
            ),
          ),
        ],
      ),
    );
  }
}