import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../constants.dart';
import 'movie_detail_page.dart';

enum _ResultType { movie, person }

class _SearchResult {
  final _ResultType type;
  final Movie? movie;
  final _Person? person;

  const _SearchResult.movie(this.movie)
      : type = _ResultType.movie,
        person = null;

  const _SearchResult.person(this.person)
      : type = _ResultType.person,
        movie = null;
}

class _Person {
  final int id;
  final String name;
  final String profilePath;
  final String knownForDepartment;
  final List<String> knownForTitles;

  const _Person({
    required this.id,
    required this.name,
    required this.profilePath,
    required this.knownForDepartment,
    required this.knownForTitles,
  });

  factory _Person.fromJson(Map<String, dynamic> json) {
    final knownFor = (json['known_for'] as List? ?? [])
        .map((e) => (e['title'] ?? e['name'] ?? '') as String)
        .where((t) => t.isNotEmpty)
        .take(2)
        .toList();
    return _Person(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      profilePath: json['profile_path'] as String? ?? '',
      knownForDepartment: json['known_for_department'] as String? ?? '',
      knownForTitles: knownFor,
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  List<_SearchResult> _results = [];
  List<Map<String, dynamic>> _genres = [];
  Set<int> _selectedGenreIds = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;

  double _minRating = 0.0;
  int? _selectedYear;

  bool get _hasActiveFilters =>
      _selectedGenreIds.isNotEmpty || _minRating > 0 || _selectedYear != null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadGenres();
    _fetch(page: 1, reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadGenres() async {
    final uri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/genre/movie/list?language=fr-FR',
    );
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${AppConstants.tmdbToken}',
    });
    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _genres = List<Map<String, dynamic>>.from(data['genres']);
      });
    }
  }

  Future<void> _fetch({required int page, bool reset = false}) async {
    if (_isLoading || (_isLoadingMore && !reset)) return;
    setState(() {
      if (reset) {
        _isLoading = true;
        _results = [];
      } else {
        _isLoadingMore = true;
      }
    });
    try {
      final query = _searchController.text.trim();
      final (newResults, totalPages) = query.isNotEmpty
          ? await _searchMulti(query, page)
          : await _discoverMovies(page);
      if (!mounted) return;
      setState(() {
        _currentPage = page;
        _totalPages = totalPages;
        _results = reset ? newResults : [..._results, ...newResults];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<(List<_SearchResult>, int)> _searchMulti(
      String query, int page) async {
    final uri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/search/multi'
          '?query=${Uri.encodeComponent(query)}'
          '&page=$page'
          '&language=fr-FR'
          '&include_adult=false',
    );
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${AppConstants.tmdbToken}',
    });
    if (response.statusCode != 200) return (<_SearchResult>[], 0);
    final data = jsonDecode(response.body);
    final results = <_SearchResult>[];
    for (final item in data['results'] as List) {
      final type = item['media_type'] as String?;
      if (type == 'movie') {
        final movie = Movie.fromJson(item);
        if (movie.posterPath.isNotEmpty) results.add(_SearchResult.movie(movie));
      } else if (type == 'person') {
        final person = _Person.fromJson(item);
        if (person.name.isNotEmpty) results.add(_SearchResult.person(person));
      }
    }
    return (results, data['total_pages'] as int);
  }

  Future<(List<_SearchResult>, int)> _discoverMovies(int page) async {
    final buffer = StringBuffer(
      '${AppConstants.tmdbBaseUrl}/discover/movie'
          '?page=$page'
          '&language=fr-FR'
          '&include_adult=false'
          '&sort_by=popularity.desc',
    );
    if (_selectedGenreIds.isNotEmpty) {
      buffer.write('&with_genres=${_selectedGenreIds.join(",")}');
    }
    if (_minRating > 0) {
      buffer.write('&vote_average.gte=$_minRating&vote_count.gte=100');
    }
    if (_selectedYear != null) {
      buffer.write('&primary_release_year=$_selectedYear');
    }
    final response = await http.get(Uri.parse(buffer.toString()), headers: {
      'Authorization': 'Bearer ${AppConstants.tmdbToken}',
    });
    if (response.statusCode != 200) return (<_SearchResult>[], 0);
    final data = jsonDecode(response.body);
    final results = (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .where((m) => m.posterPath.isNotEmpty)
        .map((m) => _SearchResult.movie(m))
        .toList();
    return (results, data['total_pages'] as int);
  }

  void _loadMore() {
    if (!_isLoadingMore && _currentPage < _totalPages) {
      _fetch(page: _currentPage + 1);
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
          () => _fetch(page: 1, reset: true),
    );
    setState(() {});
  }

  void _clearFilters() {
    setState(() {
      _selectedGenreIds = {};
      _minRating = 0.0;
      _selectedYear = null;
    });
    _fetch(page: 1, reset: true);
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltersSheet(
        genres: _genres,
        selectedGenreIds: Set.from(_selectedGenreIds),
        minRating: _minRating,
        selectedYear: _selectedYear,
        onApply: (genreIds, rating, year) {
          setState(() {
            _selectedGenreIds = genreIds;
            _minRating = rating;
            _selectedYear = year;
          });
          _fetch(page: 1, reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_hasActiveFilters) _buildActiveFiltersBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: false,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Titre, acteur, réalisateur...',
                  hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 15),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _fetch(page: 1, reset: true);
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openFilters,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _hasActiveFilters ? Colors.white : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasActiveFilters ? Colors.white : Colors.white10,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: _hasActiveFilters ? Colors.black : Colors.white,
                    size: 20,
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    final parts = <String>[];
    if (_selectedGenreIds.isNotEmpty) {
      final names = _selectedGenreIds
          .map((id) {
        final g = _genres.firstWhere(
              (g) => g['id'] == id,
          orElse: () => <String, dynamic>{},
        );
        return g['name'] as String? ?? '';
      })
          .where((n) => n.isNotEmpty)
          .join(', ');
      if (names.isNotEmpty) parts.add(names);
    }
    if (_minRating > 0) parts.add('${_minRating.toStringAsFixed(1)}+');
    if (_selectedYear != null) parts.add('$_selectedYear');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            child: const Text(
              'Effacer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Aucun résultat pour "${_searchController.text}"'
                  : 'Aucun film trouvé',
              style: const TextStyle(color: Colors.white38, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: _results.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (_, index) {
        if (index >= _results.length) return _buildSkeletonCard();
        final result = _results[index];
        if (result.type == _ResultType.person) {
          return _buildPersonCard(result.person!);
        }
        return _buildMovieCard(result.movie!);
      },
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => MovieDetailPage(movie: movie),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              '${AppConstants.tmdbImageBaseUrl}/w342${movie.posterPath}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1E1E1E),
                child: const Icon(Icons.broken_image_rounded,
                    color: Colors.white12, size: 40),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD000000)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                        const Spacer(),
                        if (movie.releaseDate.length >= 4)
                          Text(
                            movie.releaseDate.substring(0, 4),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(_Person person) {
    final hasPhoto = person.profilePath.isNotEmpty;
    final dept = person.knownForDepartment;
    final label = dept == 'Directing'
        ? 'Réalisateur'
        : dept == 'Acting'
        ? 'Acteur'
        : dept;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 65,
            child: hasPhoto
                ? Image.network(
              '${AppConstants.tmdbImageBaseUrl}/w342${person.profilePath}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _personPlaceholder(),
            )
                : _personPlaceholder(),
          ),
          Expanded(
            flex: 35,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (label.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (person.knownForTitles.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      person.knownForTitles.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                      const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personPlaceholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.person_rounded, color: Colors.white12, size: 48),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final List<Map<String, dynamic>> genres;
  final Set<int> selectedGenreIds;
  final double minRating;
  final int? selectedYear;
  final void Function(Set<int>, double, int?) onApply;

  const _FiltersSheet({
    required this.genres,
    required this.selectedGenreIds,
    required this.minRating,
    required this.selectedYear,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late Set<int> _genreIds;
  late double _rating;
  late int? _year;

  final _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _genreIds = Set.from(widget.selectedGenreIds);
    _rating = widget.minRating;
    _year = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Text(
                    'Filtres avancés',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _genreIds = {};
                      _rating = 0.0;
                      _year = null;
                    }),
                    child: const Text(
                      'Réinitialiser',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                children: [
                  _buildSection('Genres', _buildGenreChips()),
                  const SizedBox(height: 28),
                  _buildSection(
                    _rating > 0
                        ? 'Note minimale : ${_rating.toStringAsFixed(1)} / 10'
                        : 'Note minimale : toutes',
                    _buildRatingSlider(),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    _year != null ? 'Année : $_year' : 'Année : toutes',
                    _buildYearSlider(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApply(_genreIds, _rating, _year);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Appliquer les filtres',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildGenreChips() {
    if (widget.genres.isEmpty) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.genres.map((genre) {
        final id = genre['id'] as int;
        final isSelected = _genreIds.contains(id);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _genreIds.remove(id);
            } else {
              _genreIds.add(id);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white12,
              ),
            ),
            child: Text(
              genre['name'] as String,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            thumbColor: Colors.white,
            overlayColor: Colors.white12,
            inactiveTrackColor: Colors.white12,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _rating,
            min: 0,
            max: 9,
            divisions: 18,
            onChanged: (value) => setState(() => _rating = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Toutes',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text('9.0',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYearSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            thumbColor: Colors.white,
            overlayColor: Colors.white12,
            inactiveTrackColor: Colors.white12,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: (_year ?? _currentYear).toDouble(),
            min: 1950,
            max: _currentYear.toDouble(),
            divisions: _currentYear - 1950,
            onChanged: (value) => setState(() => _year = value.toInt()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1950',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              GestureDetector(
                onTap: () => setState(() => _year = null),
                child: const Text(
                  'Toutes les années',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$_currentYear',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}