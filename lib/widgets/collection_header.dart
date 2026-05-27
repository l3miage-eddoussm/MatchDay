import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/collection_detail.dart';

class CollectionHeader extends StatelessWidget {
  final CollectionDetail collection;

  const CollectionHeader({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _CollectionBackdrop(collection: collection),
            const _CollectionGradient(),
            _CollectionInfo(collection: collection),
          ],
        ),
      ),
    );
  }
}

class _CollectionBackdrop extends StatelessWidget {
  final CollectionDetail collection;

  const _CollectionBackdrop({required this.collection});

  @override
  Widget build(BuildContext context) {
    if (collection.backdropPath.isEmpty) {
      return const ColoredBox(color: AppColors.surfaceDark);
    }
    return Image.network(
      collection.backdropUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.surfaceDark),
    );
  }
}

class _CollectionGradient extends StatelessWidget {
  const _CollectionGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.overlayDark, AppColors.background],
          stops: [0.3, 1.0],
        ),
      ),
    );
  }
}

class _CollectionInfo extends StatelessWidget {
  final CollectionDetail collection;

  const _CollectionInfo({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilmCountBadge(count: collection.parts.length),
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
    );
  }
}

class _FilmCountBadge extends StatelessWidget {
  final int count;

  const _FilmCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        '$count FILMS',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}