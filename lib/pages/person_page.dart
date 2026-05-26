import 'package:flutter/material.dart';
import '../constants.dart';
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
  late TabController _tabController;

  static const _red           = Color(0xFFFF0000);
  static const _surfaceColor  = Color(0xFF111111);
  static const _cardColor     = Color(0xFF1A1A1A);
  static const _mutedColor    = Color(0xFF888888);
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
      final person =
      await MovieService().getPersonDetails(widget.personId);
      if (mounted) {
        setState(() {
          _person    = person;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Set<int> get _ratedIds => MovieActionService()
      .getRatedMovies()
      .map((a) => a.movieId)
      .toSet();

  int _countSeen(List<PersonMovie> credits, Set<int> ratedIds) =>
      credits.where((m) => ratedIds.contains(m.id)).length;

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
          ? _PersonErrorView(
          onBack: () => Navigator.of(context).pop())
          : _buildContent(_person!),
    );
  }

  Widget _buildContent(Person person) {
    final hasActing    = person.actingCredits.isNotEmpty;
    final hasDirecting = person.directingCredits.isNotEmpty;
    final showTabs     = hasActing && hasDirecting;
    final ratedIds     = _ratedIds;

    return CustomScrollView(
      slivers: [
        _buildAppBar(person),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonHero(person: person),
              _PersonStats(
                person:   person,
                ratedIds: ratedIds,
                surfaceColor:   _surfaceColor,
                mutedColor:     _mutedColor,
                secondaryColor: _secondaryColor,
              ),
              _PopularityBadge(
                  popularity: person.popularity,
                  red: _red,
                  mutedColor: _mutedColor),
              if (person.biography.isNotEmpty)
                _Biography(
                    biography: person.biography,
                    red: _red,
                    secondaryColor: _secondaryColor),
              const SizedBox(height: 28),
              if (hasActing || hasDirecting)
                showTabs
                    ? _FilmographyTabs(
                  person:        person,
                  tabController: _tabController,
                  ratedIds:      ratedIds,
                  red:           _red,
                  mutedColor:    _mutedColor,
                  cardColor:     _cardColor,
                  countSeen:     _countSeen,
                )
                    : _SingleFilmography(
                  person:    person,
                  ratedIds:  ratedIds,
                  red:       _red,
                  mutedColor: _mutedColor,
                  cardColor:  _cardColor,
                  countSeen:  _countSeen,
                ),
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
}

class _PersonErrorView extends StatelessWidget {
  final VoidCallback onBack;
  static const _mutedColor = Color(0xFF888888);

  const _PersonErrorView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: _mutedColor, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger les informations.',
            style: TextStyle(color: _mutedColor, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onBack,
            child: const Text('Retour',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PersonHero extends StatelessWidget {
  final Person person;
  static const _cardColor = Color(0xFF1A1A1A);
  static const _red       = Color(0xFFFF0000);

  const _PersonHero({required this.person});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        person.profilePath.isNotEmpty
            ? SizedBox(
          height: 320,
          width: double.infinity,
          child: Image.network(
            '${AppConstants.tmdbImageBaseUrl}/w780${person.profilePath}',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(height: 320, color: _cardColor),
          ),
        )
            : Container(
          height: 320,
          color: _cardColor,
          child: const Center(
            child: Icon(Icons.person,
                color: Color(0xFF333333), size: 80),
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
              _DepartmentBadge(person: person, red: _red),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepartmentBadge extends StatelessWidget {
  final Person person;
  final Color red;

  const _DepartmentBadge({required this.person, required this.red});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: red.withOpacity(0.85),
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
}

class _PersonStats extends StatelessWidget {
  final Person person;
  final Set<int> ratedIds;
  final Color surfaceColor;
  final Color mutedColor;
  final Color secondaryColor;

  const _PersonStats({
    required this.person,
    required this.ratedIds,
    required this.surfaceColor,
    required this.mutedColor,
    required this.secondaryColor,
  });

  int get _totalAndSeen {
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final allIds = <int>{
      ...person.actingCredits.map((m) => m.id),
      ...person.directingCredits.map((m) => m.id),
    };
    final allCredits = [
      ...person.actingCredits,
      ...person.directingCredits,
    ].where((m) => allIds.remove(m.id)).toList();

    final seen  = allCredits.where((m) => ratedIds.contains(m.id)).length;
    final total = allIds.length + allCredits.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (person.birthday.isNotEmpty)
            _StatChip(
              icon:  Icons.cake_outlined,
              label: person.age,
              surfaceColor:   surfaceColor,
              mutedColor:     mutedColor,
              secondaryColor: secondaryColor,
            ),
          if (person.placeOfBirth.isNotEmpty)
            _StatChip(
              icon:  Icons.place_outlined,
              label: person.placeOfBirth.length > 24
                  ? '${person.placeOfBirth.substring(0, 24)}…'
                  : person.placeOfBirth,
              surfaceColor:   surfaceColor,
              mutedColor:     mutedColor,
              secondaryColor: secondaryColor,
            ),
          _StatChip(
            icon:  Icons.movie_outlined,
            label: '$seen vus sur $total films',
            surfaceColor:   surfaceColor,
            mutedColor:     mutedColor,
            secondaryColor: secondaryColor,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color surfaceColor;
  final Color mutedColor;
  final Color secondaryColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.surfaceColor,
    required this.mutedColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: mutedColor, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style:
              TextStyle(color: secondaryColor, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PopularityBadge extends StatelessWidget {
  final double popularity;
  final Color red;
  final Color mutedColor;

  const _PopularityBadge({
    required this.popularity,
    required this.red,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final pop   = popularity;
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
        ? const Color(0xFF39EF00)
        : pop > 20
        ? red
        : mutedColor;

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
}

class _Biography extends StatefulWidget {
  final String biography;
  final Color red;
  final Color secondaryColor;

  const _Biography({
    required this.biography,
    required this.red,
    required this.secondaryColor,
  });

  @override
  State<_Biography> createState() => _BiographyState();
}

class _BiographyState extends State<_Biography> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
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
            widget.biography,
            maxLines:  _expanded ? null : 4,
            overflow:  _expanded ? null : TextOverflow.ellipsis,
            style: TextStyle(
              color:  widget.secondaryColor,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Voir moins' : 'Voir plus',
              style: TextStyle(
                  color: widget.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmographyTabs extends StatelessWidget {
  final Person person;
  final TabController tabController;
  final Set<int> ratedIds;
  final Color red;
  final Color mutedColor;
  final Color cardColor;
  final int Function(List<PersonMovie>, Set<int>) countSeen;

  const _FilmographyTabs({
    required this.person,
    required this.tabController,
    required this.ratedIds,
    required this.red,
    required this.mutedColor,
    required this.cardColor,
    required this.countSeen,
  });

  double _estimateGridHeight(int count) =>
      (count / 3).ceil() * 220.0 + 20;

  @override
  Widget build(BuildContext context) {
    final actingSeen    = countSeen(person.actingCredits, ratedIds);
    final directingSeen = countSeen(person.directingCredits, ratedIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TabBar(
            controller: tabController,
            indicatorColor: red,
            labelColor: Colors.white,
            unselectedLabelColor: mutedColor,
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
            controller: tabController,
            children: [
              _MovieGrid(
                  credits: person.actingCredits,
                  ratedIds: ratedIds,
                  red: red,
                  mutedColor: mutedColor,
                  cardColor: cardColor),
              _MovieGrid(
                  credits: person.directingCredits,
                  ratedIds: ratedIds,
                  red: red,
                  mutedColor: mutedColor,
                  cardColor: cardColor),
            ],
          ),
        ),
      ],
    );
  }
}

class _SingleFilmography extends StatelessWidget {
  final Person person;
  final Set<int> ratedIds;
  final Color red;
  final Color mutedColor;
  final Color cardColor;
  final int Function(List<PersonMovie>, Set<int>) countSeen;

  const _SingleFilmography({
    required this.person,
    required this.ratedIds,
    required this.red,
    required this.mutedColor,
    required this.cardColor,
    required this.countSeen,
  });

  @override
  Widget build(BuildContext context) {
    final credits = person.actingCredits.isNotEmpty
        ? person.actingCredits
        : person.directingCredits;
    final label = person.actingCredits.isNotEmpty
        ? 'Filmographie'
        : 'Films réalisés';
    final seen = countSeen(credits, ratedIds);

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
                style: TextStyle(color: mutedColor, fontSize: 13),
              ),
            ],
          ),
        ),
        _MovieGrid(
          credits:   credits,
          ratedIds:  ratedIds,
          red:       red,
          mutedColor: mutedColor,
          cardColor:  cardColor,
        ),
      ],
    );
  }
}

class _MovieGrid extends StatelessWidget {
  final List<PersonMovie> credits;
  final Set<int> ratedIds;
  final Color red;
  final Color mutedColor;
  final Color cardColor;

  const _MovieGrid({
    required this.credits,
    required this.ratedIds,
    required this.red,
    required this.mutedColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    if (credits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Aucun film disponible.',
            style: TextStyle(color: mutedColor, fontSize: 14),
          ),
        ),
      );
    }

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
        final m      = credits[index];
        final isSeen = ratedIds.contains(m.id);
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MovieDetailPage(
                movie: Movie(
                  id:           m.id,
                  title:        m.title,
                  overview:     '',
                  posterPath:   m.posterPath,
                  backdropPath: '',
                  voteAverage:  m.voteAverage,
                  releaseDate:  m.releaseDate,
                  genres:       [],
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
                            Container(color: cardColor),
                      )
                          : Container(
                        color: cardColor,
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
                            color: red,
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
                  style: TextStyle(color: mutedColor, fontSize: 10),
                ),
            ],
          ),
        );
      },
    );
  }
}