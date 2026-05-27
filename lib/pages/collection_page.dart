import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/collection_detail.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/collection_header.dart';
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
    if (collection == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await MovieService().getCollection(collection.id);
      if (!mounted) return;
      setState(() {
        _collection = data;
        _isLoading  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      )
          : CustomScrollView(
        slivers: [
          if (_collection != null) CollectionHeader(collection: _collection!),
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

  Widget _buildTimelineItem(int index) {
    final parts     = _collection?.parts ?? [];
    if (parts.isEmpty) return const SizedBox.shrink();
    final movie     = parts[index];
    final isLast    = index == parts.length - 1;
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