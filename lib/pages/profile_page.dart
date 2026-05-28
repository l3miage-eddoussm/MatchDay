import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/user_movie_action.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/movie_action_service.dart';
import '../services/movie_service.dart';
import 'login_page.dart';
import '../widgets/stats_share_card.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/movie_row.dart';
import '../widgets/trophy_row.dart';
import '../widgets/highlight_section.dart';

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
  String? _actorImageUrl;
  String? _directorImageUrl;

  static const int _pageSize = 10;
  static const _text1 = Color(0xFF2E2E2E);


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
    final svc = MovieActionService();
    final actor = svc.getMostWatchedActorForYear(_selectedYear);
    final director = svc.getMostWatchedDirectorForYear(_selectedYear);
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
    final svc = MovieActionService();
    final allMovies = _filteredMovies;
    final paginatedMovies = allMovies.take(_page * _pageSize).toList();
    final trophies = svc.getTrophiesForYear(_selectedYear);
    final watchLater = svc.getWatchLaterList();
    final avg = svc.getAverageRatingForYear(_selectedYear);
    final dist = svc.getRatingDistributionForYear(_selectedYear);
    final actor = svc.getMostWatchedActorForYear(_selectedYear);
    final director = svc.getMostWatchedDirectorForYear(_selectedYear);
    final genre = svc.getMostWatchedGenreForYear(_selectedYear);
    final ratedCount = svc.getRatedMoviesForYear(_selectedYear).length;

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
                  username: _user != null ? '${_user!.firstName} ${_user!.lastName}' : '',
                  initials: _initials,
                ),
              ),
            ),
          if (actor != null || director != null || genre != null)
            SliverToBoxAdapter(
              child: HighlightSection(
                year: _selectedYear,
                actor: actor,
                director: director,
                genre: genre,
                actorImageUrl: _actorImageUrl,
                directorImageUrl: _directorImageUrl,
              ),
            ),
          SliverToBoxAdapter(
            child: _buildTabBar(ratedCount, trophies.length, watchLater.length),
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
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
      actions: [
        GestureDetector(
          onTap: _logout,
          child: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 14, color: AppColors.secondary),
                SizedBox(width: 5),
                Text('Déconnexion', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: ColoredBox(color: Color(0xFF1A1A1A), child: SizedBox(height: 1)),
      ),
    );
  }

  Widget _buildHeader(double avg, int filmCount, int trophyCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.card))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(initials: _initials),
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
                      style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: StatCard(value: '$filmCount', label: 'Films vus', icon: Icons.movie_rounded)),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  value: avg > 0 ? avg.toStringAsFixed(1) : '—',
                  label: 'Note moy.',
                  icon: Icons.star_rounded,
                  accent: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: StatCard(value: '$trophyCount', label: 'Trophées', icon: Icons.emoji_events_rounded)),
            ],
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
            style: TextStyle(color: _text1, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2),
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
                      color: selected ? AppColors.accent : AppColors.card,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: selected ? AppColors.accent : AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.secondary,
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
      if (score >= 8) return AppColors.accent;
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
                style: TextStyle(color: _text1, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2),
              ),
              Text('$total films notés', style: const TextStyle(color: _text1, fontSize: 10)),
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
                          Text('$count', style: TextStyle(color: bc, fontSize: 8, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: count > 0 ? 52.0 * ratio + 4 : 3,
                          decoration: BoxDecoration(
                            color: count > 0 ? bc : AppColors.card,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$score',
                          style: TextStyle(
                            color: count > 0 ? AppColors.secondary : AppColors.border,
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
          const ColoredBox(color: AppColors.card, child: SizedBox(height: 1, width: double.infinity)),
        ],
      ),
    );
  }

  Widget _buildTabBar(int movieCount, int trophyCount, int watchCount) {
    final tabs = [('Films', movieCount), ('Trophées', trophyCount), ('À voir', watchCount)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _activeTab == i;
          return GestureDetector(
            onTap: () => setState(() { _activeTab = i; _filterLevel = null; _page = 1; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppColors.accent : AppColors.surfaceDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[i].$1,
                    style: TextStyle(color: selected ? Colors.white : AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.2) : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tabs[i].$2}',
                      style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800),
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
      ('low', 'Faible', AppColors.accent),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: filters.map((f) {
          final selected = _filterLevel == f.$1;
          return GestureDetector(
            onTap: () => setState(() { _filterLevel = selected ? null : f.$1; _page = 1; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? f.$3.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? f.$3 : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: f.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(f.$2, style: TextStyle(color: selected ? f.$3 : AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadMore() {
    final remaining = _filteredMovies.length - _page * _pageSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: GestureDetector(
        onTap: () => setState(() => _page++),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.expand_more_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 6),
              Text('Voir $remaining films de plus', style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMoviesList(List<UserMovieAction> movies) {
    if (movies.isEmpty) {
      return [const SliverToBoxAdapter(child: EmptyState(icon: Icons.movie_creation_outlined, message: 'Aucun film pour ce filtre'))];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (_, i) => MovieRow(action: movies[i], showRating: true),
            childCount: movies.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildTrophiesList(List<UserMovieAction> trophies) {
    if (trophies.isEmpty) {
      return [const SliverToBoxAdapter(child: EmptyState(icon: Icons.emoji_events_outlined, message: 'Passe des quiz pour gagner des trophées'))];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (_, i) => TrophyRow(action: trophies[i]),
            childCount: trophies.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildWatchLaterList(List<UserMovieAction> list) {
    if (list.isEmpty) {
      return [const SliverToBoxAdapter(child: EmptyState(icon: Icons.bookmark_border_rounded, message: 'Ajoute des films à voir plus tard'))];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (_, i) => MovieRow(action: list[i], showRating: false),
            childCount: list.length,
          ),
        ),
      ),
    ];
  }
}