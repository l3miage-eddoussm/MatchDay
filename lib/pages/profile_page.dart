import 'package:flutter/material.dart';
import '../models/user_movie_action.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/movie_action_service.dart';
import '../services/movie_service.dart';
import 'login_page.dart';
import '../widgets/stats_share_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  int _selectedYear = DateTime.now().year;
  List<int> _years = [];
  int _activeTab = 0;

  String? _filterLevel;
  int _page = 1;
  static const int _pageSize = 10;

  String? _actorImageUrl;
  String? _directorImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadYears();
  }

  void _loadYears() {
    final years = MovieActionService().getRatedYears();
    final current = DateTime.now().year;
    if (!years.contains(current)) years.insert(0, current);
    setState(() {
      _years = years;
      _selectedYear = years.first;
    });
    _loadHighlightImages();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _loadHighlightImages() async {
    final actor = MovieActionService().getMostWatchedActorForYear(_selectedYear);
    final director = MovieActionService().getMostWatchedDirectorForYear(_selectedYear);

    if (actor != null) {
      final url = await MovieService().searchPersonImage(actor);
      if (mounted) setState(() => _actorImageUrl = url);
    }
    if (director != null) {
      final url = await MovieService().searchPersonImage(director);
      if (mounted) setState(() => _directorImageUrl = url);
    }
  }

  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
      _filterLevel = null;
      _page = 1;
      _actorImageUrl = null;
      _directorImageUrl = null;
    });
    _loadHighlightImages();
  }

  String get _initials {
    if (_user == null) return '?';
    final f = _user!.firstName.isNotEmpty ? _user!.firstName[0] : '';
    final l = _user!.lastName.isNotEmpty ? _user!.lastName[0] : '';
    return '${f.toUpperCase()}${l.toUpperCase()}';
  }

  List<UserMovieAction> get _filteredMovies {
    final movies = MovieActionService().getRatedMoviesForYear(_selectedYear);
    if (_filterLevel == null) return movies;
    return movies.where((m) {
      final r = m.rating ?? 0;
      if (_filterLevel == 'good') return r >= 7;
      if (_filterLevel == 'medium') return r >= 4 && r < 7;
      return r < 4;
    }).toList();
  }

  Future<void> _logout() async {
    await AuthService().logout();
    MovieActionService().clearUser();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMovies = _filteredMovies;
    final paginatedMovies = allMovies.take(_page * _pageSize).toList();
    final trophies = MovieActionService().getTrophiesForYear(_selectedYear);
    final watchLater = MovieActionService().getWatchLaterList();
    final avg = MovieActionService().getAverageRatingForYear(_selectedYear);
    final dist = MovieActionService().getRatingDistributionForYear(_selectedYear);
    final actor = MovieActionService().getMostWatchedActorForYear(_selectedYear);
    final director = MovieActionService().getMostWatchedDirectorForYear(_selectedYear);
    final genre = MovieActionService().getMostWatchedGenreForYear(_selectedYear);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeader(avg, allMovies.length, trophies.length)),
          SliverToBoxAdapter(child: _buildYearPicker()),
          if (dist.isNotEmpty) SliverToBoxAdapter(child: _buildChart(dist)),
          if (dist.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: StatsShareCard(
                  year: _selectedYear,
                  username: _user != null
                      ? '${_user!.firstName} ${_user!.lastName}'
                      : '',
                  initials: _initials,
                ),
              ),
            ),
          if (actor != null || director != null || genre != null)
            SliverToBoxAdapter(child: _buildHighlights(actor, director, genre)),
          SliverToBoxAdapter(
            child: _buildTabBar(
              MovieActionService().getRatedMoviesForYear(_selectedYear).length,
              trophies.length,
              watchLater.length,
            ),
          ),
          if (_activeTab == 0) ...[
            SliverToBoxAdapter(child: _buildFilters()),
            ..._buildMoviesList(paginatedMovies),
            if (paginatedMovies.length < allMovies.length)
              SliverToBoxAdapter(child: _buildLoadMore()),
          ],
          if (_activeTab == 1) ..._buildTrophiesList(trophies),
          if (_activeTab == 2) ..._buildWatchLaterList(watchLater),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Profil',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _logout,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: const [
                Icon(Icons.logout_rounded, size: 14, color: Color(0xFF444444)),
                SizedBox(width: 5),
                Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFF1A1A1A)),
      ),
    );
  }

  Widget _buildHeader(double avg, int filmCount, int trophyCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF111111))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user != null ? '${_user!.firstName} ${_user!.lastName}' : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user?.email ?? '',
                      style: const TextStyle(
                        color: Color(0xFF3A3A3A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatCard('$filmCount', 'Films vus', Icons.movie_rounded)),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  avg > 0 ? avg.toStringAsFixed(1) : '—',
                  'Note moy.',
                  Icons.star_rounded,
                  accent: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('$trophyCount', 'Trophées', Icons.emoji_events_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: accent ? const Color(0xFFE53935) : const Color(0xFF333333),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent ? const Color(0xFFE53935) : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PÉRIODE',
            style: TextStyle(
              color: Color(0xFF2E2E2E),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _years.length,
              itemBuilder: (_, i) {
                final year = _years[i];
                final selected = year == _selectedYear;
                return GestureDetector(
                  onTap: () => _onYearChanged(year),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE53935) : const Color(0xFF0F0F0F),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: selected ? const Color(0xFFE53935) : const Color(0xFF1E1E1E),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF444444),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Map<int, int> dist) {
    final maxCount = dist.values.reduce((a, b) => a > b ? a : b);
    final total = dist.values.fold(0, (a, b) => a + b);

    Color barColor(int score) {
      if (score >= 8) return const Color(0xFFE53935);
      if (score >= 6) return const Color(0xFFAB2424);
      if (score >= 4) return const Color(0xFF6B1515);
      return const Color(0xFF2A0A0A);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DISTRIBUTION',
                style: TextStyle(
                  color: Color(0xFF2E2E2E),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$total films notés',
                style: const TextStyle(color: Color(0xFF2E2E2E), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF141414)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(10, (i) {
                final score = i + 1;
                final count = dist[score] ?? 0;
                final ratio = maxCount > 0 ? count / maxCount : 0.0;
                final bc = barColor(score);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (count > 0)
                          Text(
                            '$count',
                            style: TextStyle(
                              color: bc,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: count > 0 ? 52.0 * ratio + 4 : 3,
                          decoration: BoxDecoration(
                            color: count > 0 ? bc : const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$score',
                          style: TextStyle(
                            color: count > 0 ? const Color(0xFF444444) : const Color(0xFF1E1E1E),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFF111111)),
        ],
      ),
    );
  }

  Widget _buildHighlights(String? actor, String? director, String? genre) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP $_selectedYear',
            style: const TextStyle(
              color: Color(0xFF2E2E2E),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          if (actor != null || director != null)
            Row(
              children: [
                if (actor != null)
                  Expanded(
                    child: _HighlightTile(
                      icon: Icons.person_rounded,
                      label: 'ACTEUR',
                      value: actor,
                      imageUrl: _actorImageUrl,
                    ),
                  ),
                if (actor != null && director != null) const SizedBox(width: 10),
                if (director != null)
                  Expanded(
                    child: _HighlightTile(
                      icon: Icons.videocam_rounded,
                      label: 'RÉALISATEUR',
                      value: director,
                      imageUrl: _directorImageUrl,
                    ),
                  ),
              ],
            ),
          if (genre != null) ...[
            if (actor != null || director != null) const SizedBox(height: 10),
            _GenreHighlightTile(genre: genre),
          ],
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFF111111)),
        ],
      ),
    );
  }

  Widget _buildTabBar(int movieCount, int trophyCount, int watchCount) {
    final tabs = [
      ('Films', movieCount),
      ('Trophées', trophyCount),
      ('À voir', watchCount),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _activeTab == i;
          return GestureDetector(
            onTap: () => setState(() {
              _activeTab = i;
              _filterLevel = null;
              _page = 1;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE53935) : const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? const Color(0xFFE53935) : const Color(0xFF1A1A1A),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[i].$1,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF444444),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tabs[i].$2}',
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF3A3A3A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      ('good', 'Bon', Color(0xFF4CAF50)),
      ('medium', 'Moyen', Color(0xFFFF9800)),
      ('low', 'Faible', Color(0xFFE53935)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          ...filters.map((f) {
            final selected = _filterLevel == f.$1;
            return GestureDetector(
              onTap: () => setState(() {
                _filterLevel = selected ? null : f.$1;
                _page = 1;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? f.$3.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? f.$3 : const Color(0xFF1E1E1E),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: f.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f.$2,
                      style: TextStyle(
                        color: selected ? f.$3 : const Color(0xFF444444),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    final allCount = _filteredMovies.length;
    final shown = _page * _pageSize;
    final remaining = allCount - shown;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: GestureDetector(
        onTap: () => setState(() => _page++),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E1E1E)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.expand_more_rounded, color: Color(0xFF444444), size: 16),
              const SizedBox(width: 6),
              Text(
                'Voir $remaining films de plus',
                style: const TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMoviesList(List<UserMovieAction> movies) {
    if (movies.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: _EmptyState(
            icon: Icons.movie_creation_outlined,
            message: 'Aucun film pour ce filtre',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final a = movies[i];
              final rating = a.rating ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 1),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF0F0F0F))),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: a.posterPath.isNotEmpty
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w200${a.posterPath}',
                              width: 38,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _posterFallback(),
                            )
                          : _posterFallback(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.movieTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (a.directors.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              a.directors.join(', '),
                              style: const TextStyle(
                                color: Color(0xFF3A3A3A),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (a.genres.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: a.genres.take(2).map((g) => Container(
                                margin: const EdgeInsets.only(right: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111111),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF1A1A1A)),
                                ),
                                child: Text(
                                  g,
                                  style: const TextStyle(
                                    color: Color(0xFF3A3A3A),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F0F),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF1A1A1A)),
                          ),
                          child: Text(
                            '${rating.toStringAsFixed(0)}/10',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (s) {
                            final filled = (s + 1) * 2 <= rating;
                            final half = !filled && s * 2 < rating && (s + 1) * 2 > rating;
                            return Icon(
                              filled
                                  ? Icons.star_rounded
                                  : half
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded,
                              color: const Color(0xFFE53935),
                              size: 12,
                            );
                          }),
                        ),
                        if (a.trophy != null) ...[
                          const SizedBox(height: 4),
                          Text(a.trophy!.emoji, style: const TextStyle(fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
            childCount: movies.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildTrophiesList(List<UserMovieAction> trophies) {
    if (trophies.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: _EmptyState(
            icon: Icons.emoji_events_outlined,
            message: 'Passe des quiz pour gagner des trophées',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final a = trophies[i];
              final t = a.trophy!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF141414)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1E1E1E)),
                      ),
                      alignment: Alignment.center,
                      child: Text(t.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.movieTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.label,
                            style: const TextStyle(
                              color: Color(0xFF444444),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (a.posterPath.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          'https://image.tmdb.org/t/p/w200${a.posterPath}',
                          width: 32,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                  ],
                ),
              );
            },
            childCount: trophies.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildWatchLaterList(List<UserMovieAction> list) {
    if (list.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: _EmptyState(
            icon: Icons.bookmark_border_rounded,
            message: 'Ajoute des films à voir plus tard',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final a = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 1),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF0F0F0F))),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: a.posterPath.isNotEmpty
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w200${a.posterPath}',
                              width: 38,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _posterFallback(),
                            )
                          : _posterFallback(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        a.movieTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.bookmark_rounded, color: Color(0xFFE53935), size: 18),
                  ],
                ),
              );
            },
            childCount: list.length,
          ),
        ),
      ),
    ];
  }

  Widget _posterFallback() => Container(
    width: 38,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(5),
    ),
  );
}

class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? imageUrl;

  const _HighlightTile({
    required this.icon,
    required this.label,
    required this.value,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF141414)),
    ),
    child: Row(
      children: [
        ClipOval(
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _iconFallback(),
                )
              : _iconFallback(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2E2E2E),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _iconFallback() => Container(
    width: 42,
    height: 42,
    decoration: const BoxDecoration(
      color: Color(0xFF111111),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: const Color(0xFF333333), size: 18),
  );
}

class _GenreHighlightTile extends StatelessWidget {
  final String genre;

  const _GenreHighlightTile({required this.genre});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF141414)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A1A1A)),
          ),
          child: const Icon(Icons.local_movies_rounded, color: Color(0xFF333333), size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GENRE FAVORI',
              style: TextStyle(
                color: Color(0xFF2E2E2E),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              genre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1E1E1E), size: 12),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF1A1A1A), size: 40),
        const SizedBox(height: 14),
        Text(
          message,
          style: const TextStyle(
            color: Color(0xFF2E2E2E),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
