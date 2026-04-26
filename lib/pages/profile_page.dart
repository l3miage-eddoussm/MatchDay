import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/user_movie_action.dart';
import '../services/movie_action_service.dart';
import 'movie_detail_page.dart';
import '../models/movie.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserMovieAction> _watchLater = [];
  List<UserMovieAction> _rated      = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _watchLater = MovieActionService().getWatchLaterList();
      _rated      = MovieActionService().getRatedMovies()
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    });
  }

  Future<void> _openMovie(UserMovieAction action) async {
    final movie = Movie(
      id:           action.movieId,
      title:        action.movieTitle,
      posterPath:   action.posterPath,
      backdropPath: '',
      overview:     '',
      releaseDate:  '',
      voteAverage:  0,
      genres:       [],
    );
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MovieDetailPage(movie: movie),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWatchLaterTab(),
                _buildRatedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final initials =
    '${widget.user.firstName[0]}${widget.user.lastName[0]}'.toUpperCase();

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0D0D0D)],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops:  [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left:   24,
              right:  24,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape:  BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF333333), width: 2),
                    ),
                    child: CircleAvatar(
                      radius:          38,
                      backgroundColor: const Color(0xFF2A2A2A),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.user.firstName} ${widget.user.lastName}',
                          style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w800,
                            height:     1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email,
                          style: const TextStyle(
                            color:    Color(0xFF666666),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final avgRating = _rated.isEmpty
        ? 0.0
        : _rated.fold(0.0, (sum, a) => sum + (a.rating ?? 0)) / _rated.length;

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color:        const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        children: [
          _StatItem(value: '${_watchLater.length}', label: 'À revoir'),
          _StatDivider(),
          _StatItem(value: '${_rated.length}',      label: 'Notés'),
          _StatDivider(),
          _StatItem(
            value: _rated.isEmpty ? '—' : avgRating.toStringAsFixed(1),
            label: 'Moy. notes',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color:        const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: TabBar(
          controller:          _tabController,
          indicatorSize:       TabBarIndicatorSize.tab,
          dividerColor:        Colors.transparent,
          indicator: BoxDecoration(
            color:        const Color(0xFF222222),
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor:          Colors.white,
          unselectedLabelColor: const Color(0xFF555555),
          labelStyle: const TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_outline, size: 15),
                  const SizedBox(width: 6),
                  Text('À revoir (${_watchLater.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_outline_rounded, size: 15),
                  const SizedBox(width: 6),
                  Text('Notés (${_rated.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchLaterTab() {
    if (_watchLater.isEmpty) {
      return const _EmptyState(
        icon:     Icons.bookmark_border_rounded,
        title:    'Aucun film sauvegardé',
        subtitle: 'Ajoutez des films à revoir depuis la page d\'accueil.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
        childAspectRatio: 0.58,
      ),
      itemCount: _watchLater.length,
      itemBuilder: (_, i) => _ActionMovieCard(
        action:   _watchLater[i],
        onTap:    () => _openMovie(_watchLater[i]),
        onRemove: () {
          MovieActionService().toggleWatchLater(
            _watchLater[i].movieId,
            _watchLater[i].movieTitle,
            _watchLater[i].posterPath,
          );
          _refresh();
        },
      ),
    );
  }

  Widget _buildRatedTab() {
    if (_rated.isEmpty) {
      return const _EmptyState(
        icon:     Icons.star_border_rounded,
        title:    'Aucun film noté',
        subtitle: 'Notez des films depuis leur page de détails.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _rated.length,
      itemBuilder: (_, i) => _RatedMovieRow(
        action:   _rated[i],
        rank:     i + 1,
        onTap:    () => _openMovie(_rated[i]),
        onRemove: () {
          MovieActionService().removeRating(_rated[i].movieId);
          _refresh();
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFF222222));
  }
}

class _ActionMovieCard extends StatelessWidget {
  final UserMovieAction action;
  final VoidCallback    onTap;
  final VoidCallback    onRemove;

  const _ActionMovieCard({
    required this.action,
    required this.onTap,
    required this.onRemove,
  });

  String get _posterUrl => 'https://image.tmdb.org/t/p/w300${action.posterPath}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                      : _placeholder(),
                ),
                Positioned(
                  top: 5, right: 5,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            action.movieTitle,
            style: const TextStyle(
              color:      Color(0xFFDDDDDD),
              fontSize:   10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF1A1A1A),
    child: const Center(
      child: Icon(Icons.movie, color: Color(0xFF333333), size: 24),
    ),
  );
}

class _RatedMovieRow extends StatelessWidget {
  final UserMovieAction action;
  final int             rank;
  final VoidCallback    onTap;
  final VoidCallback    onRemove;

  const _RatedMovieRow({
    required this.action,
    required this.rank,
    required this.onTap,
    required this.onRemove,
  });

  String get _posterUrl => 'https://image.tmdb.org/t/p/w200${action.posterPath}';

  Color get _ratingColor {
    final r = action.rating ?? 0;
    if (r >= 8) return const Color(0xFF4CAF50);
    if (r >= 6) return const Color(0xFFFFD700);
    return const Color(0xFFFF5722);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color:      Color(0xFF444444),
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: action.posterPath.isNotEmpty
                  ? Image.network(
                _posterUrl,
                width: 46, height: 66,
                fit:   BoxFit.cover,
                errorBuilder: (_, __, ___) => _smallPlaceholder(),
              )
                  : _smallPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.movieTitle,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:        _ratingColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _ratingColor.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          color: _ratingColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${action.rating?.toInt() ?? 0}/10',
                        style: TextStyle(
                          color:      _ratingColor,
                          fontSize:   12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: const Text(
                    'Supprimer',
                    style: TextStyle(
                        color: Color(0xFF444444), fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallPlaceholder() => Container(
    width: 46, height: 66,
    color: const Color(0xFF1A1A1A),
    child: const Center(
      child: Icon(Icons.movie, color: Color(0xFF333333), size: 16),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF2A2A2A), size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color:      Color(0xFF555555),
                fontSize:   15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                  color: Color(0xFF333333), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}