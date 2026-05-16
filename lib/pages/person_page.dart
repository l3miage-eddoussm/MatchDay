import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../services/movie_action_service.dart';
import 'movie_detail_page.dart';

class PersonPage extends StatefulWidget {
  final int personId;
  final String personName;

  const PersonPage({
    super.key,
    required this.personId,
    required this.personName,
  });

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage>
    with SingleTickerProviderStateMixin {
  Person? _person;
  bool _isLoading = true;
  bool _bioExpanded = false;
  late TabController _tabController;

  static const _purple = Color(0xFF7C3AED);
  static const _surfaceColor = Color(0xFF111111);
  static const _cardColor = Color(0xFF1A1A1A);
  static const _mutedColor = Color(0xFF888888);
  static const _secondaryColor = Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPerson();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPerson() async {
    try {
      final person = await MovieService().getPersonDetails(widget.personId);
      if (mounted) {
        setState(() {
          _person = person;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _countSeenMovies(List<PersonMovie> credits) {
    final ratedIds = MovieActionService()
        .getRatedMovies()
        .map((a) => a.movieId)
        .toSet();
    return credits.where((m) => ratedIds.contains(m.id)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2),
      )
          : _person == null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: _mutedColor, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger les informations.',
            style: TextStyle(color: _mutedColor, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final person = _person!;
    final hasActing = person.actingCredits.isNotEmpty;
    final hasDirecting = person.directingCredits.isNotEmpty;
    final showTabs = hasActing && hasDirecting;

    return CustomScrollView(
      slivers: [
        _buildAppBar(person),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(person),
              _buildStats(person),
              _buildPopularityBadge(person),
              if (person.biography.isNotEmpty) _buildBiography(person),
              const SizedBox(height: 28),
              if (hasActing || hasDirecting)
                showTabs
                    ? _buildTabsSection(person)
                    : _buildSingleFilmography(person),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(Person person) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        person.name,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildHeroSection(Person person) {
    return Stack(
      children: [
        if (person.profilePath.isNotEmpty)
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Image.network(
              'https://image.tmdb.org/t/p/w780${person.profilePath}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(height: 320, color: _cardColor),
            ),
          )
        else
          Container(
            height: 320,
            color: _cardColor,
            child: const Center(
              child:
              Icon(Icons.person, color: Color(0xFF333333), size: 80),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              _buildDepartmentBadge(person),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentBadge(Person person) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        person.isActor
            ? 'Acteur'
            : person.isDirector
            ? 'Réalisateur'
            : person.knownForDepartment,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStats(Person person) {
    final allIds = {
      ...person.actingCredits.map((m) => m.id),
      ...person.directingCredits.map((m) => m.id),
    };
    final allCredits = [
      ...person.actingCredits,
      ...person.directingCredits,
    ].where((m) => allIds.remove(m.id)).toList();

    final seen = _countSeenMovies(allCredits);
    final total = allIds.length + allCredits.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (person.birthday.isNotEmpty)
            _statChip(Icons.cake_outlined, person.age),
          if (person.placeOfBirth.isNotEmpty)
            _statChip(
              Icons.place_outlined,
              person.placeOfBirth.length > 24
                  ? '${person.placeOfBirth.substring(0, 24)}…'
                  : person.placeOfBirth,
            ),
          _statChip(Icons.movie_outlined, '$seen vus sur $total films'),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _mutedColor, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: _secondaryColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPopularityBadge(Person person) {
    final pop = person.popularity;
    final label = pop > 100
        ? 'Très populaire'
        : pop > 50
        ? 'Populaire'
        : pop > 20
        ? 'Connu'
        : 'Émergent';
    final color = pop > 100
        ? const Color(0xFFFFD700)
        : pop > 50
        ? const Color(0xFF22C55E)
        : pop > 20
        ? _purple
        : _mutedColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label · Popularité ${pop.toStringAsFixed(0)}',
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBiography(Person person) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biographie',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            person.biography,
            maxLines: _bioExpanded ? null : 4,
            overflow:
            _bioExpanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(
              color: _secondaryColor,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                setState(() => _bioExpanded = !_bioExpanded),
            child: Text(
              _bioExpanded ? 'Voir moins' : 'Voir plus',
              style: const TextStyle(
                  color: _purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection(Person person) {
    final actingSeen = _countSeenMovies(person.actingCredits);
    final directingSeen =
    _countSeenMovies(person.directingCredits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TabBar(
            controller: _tabController,
            indicatorColor: _purple,
            labelColor: Colors.white,
            unselectedLabelColor: _mutedColor,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: const Color(0xFF2A2A2A),
            tabs: [
              Tab(
                text:
                'Acteur (${person.actingCredits.length} · $actingSeen vus)',
              ),
              Tab(
                text:
                'Réalisateur (${person.directingCredits.length} · $directingSeen vus)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: _estimateGridHeight(
            [
              person.actingCredits.length,
              person.directingCredits.length,
            ].reduce((a, b) => a > b ? a : b),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMovieGrid(person.actingCredits),
              _buildMovieGrid(person.directingCredits),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleFilmography(Person person) {
    final credits = person.actingCredits.isNotEmpty
        ? person.actingCredits
        : person.directingCredits;
    final label = person.actingCredits.isNotEmpty
        ? 'Filmographie'
        : 'Films réalisés';
    final seen = _countSeenMovies(credits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                '${credits.length} films · $seen vus',
                style: const TextStyle(
                    color: _mutedColor, fontSize: 13),
              ),
            ],
          ),
        ),
        _buildMovieGrid(credits),
      ],
    );
  }

  double _estimateGridHeight(int count) {
    final rows = (count / 3).ceil();
    return rows * 220.0 + 20;
  }

  Widget _buildMovieGrid(List<PersonMovie> credits) {
    if (credits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Aucun film disponible.',
            style: TextStyle(color: _mutedColor, fontSize: 14),
          ),
        ),
      );
    }

    final ratedIds = MovieActionService()
        .getRatedMovies()
        .map((a) => a.movieId)
        .toSet();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: credits.length,
      itemBuilder: (context, index) {
        final m = credits[index];
        final isSeen = ratedIds.contains(m.id);
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MovieDetailPage(
                movie: Movie(
                  id: m.id,
                  title: m.title,
                  overview: '',
                  posterPath: m.posterPath,
                  backdropPath: '',
                  voteAverage: m.voteAverage,
                  releaseDate: m.releaseDate,
                  genres: [],
                ),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: m.posterPath.isNotEmpty
                          ? Image.network(
                        m.posterUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: _cardColor),
                      )
                          : Container(
                        color: _cardColor,
                        child: const Center(
                          child: Icon(Icons.movie,
                              color: Color(0xFF333333),
                              size: 28),
                        ),
                      ),
                    ),
                    if (isSeen)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _purple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 11),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                m.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              if (m.year.isNotEmpty)
                Text(
                  m.year,
                  style: const TextStyle(
                      color: _mutedColor, fontSize: 10),
                ),
            ],
          ),
        );
      },
    );
  }
}