import 'dart:async';
import 'package:flutter/material.dart';
import '../models/genre.dart';
import '../models/search_result.dart';
import '../services/movie_service.dart';
import '../widgets/search_movie_card.dart';
import '../widgets/search_person_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  List<SearchResult> _results        = [];
  List<Genre>        _genres         = [];
  Set<int>           _selectedGenreIds = {};

  bool   _isLoading     = false;
  bool   _isLoadingMore = false;
  int    _currentPage   = 1;
  int    _totalPages    = 1;
  double _minRating     = 0.0;
  int?   _selectedYear;

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
    final genres = await MovieService().getGenres();
    if (mounted) setState(() => _genres = genres);
  }

  Future<void> _fetch({required int page, bool reset = false}) async {
    if (reset) {
      _debounceTimer?.cancel();
      setState(() {
        _isLoading     = true;
        _isLoadingMore = false;
        _results       = [];
      });
    } else {
      if (_isLoadingMore || _isLoading) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final query = _searchController.text.trim();
      final (newResults, totalPages) = query.isNotEmpty
          ? await MovieService().searchMulti(query, page)
          : await MovieService().discoverMovies(
        page:      page,
        genreIds:  _selectedGenreIds,
        minRating: _minRating,
        year:      _selectedYear,
      );
      if (!mounted) return;
      setState(() {
        _currentPage = page;
        _totalPages  = totalPages;
        _results     = reset ? newResults : [..._results, ...newResults];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading     = false;
          _isLoadingMore = false;
        });
      }
    }
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
      _minRating        = 0.0;
      _selectedYear     = null;
    });
    _fetch(page: 1, reset: true);
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltersSheet(
        genres:          _genres,
        selectedGenreIds: Set.from(_selectedGenreIds),
        minRating:       _minRating,
        selectedYear:    _selectedYear,
        onApply: (genreIds, rating, year) {
          setState(() {
            _selectedGenreIds = genreIds;
            _minRating        = rating;
            _selectedYear     = year;
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 18),
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
                  hintStyle: const TextStyle(
                      color: Colors.white38, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.white38, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white38, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _fetch(page: 1, reset: true);
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 15),
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
                color: _hasActiveFilters
                    ? Colors.white
                    : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                  _hasActiveFilters ? Colors.white : Colors.white10,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded,
                      color: _hasActiveFilters
                          ? Colors.black
                          : Colors.white,
                      size: 20),
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
          .map((id) => _genres
          .firstWhere((g) => g.id == id,
          orElse: Genre.empty)
          .name)
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
          const Icon(Icons.filter_list_rounded,
              size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(' · '),
              style:
              const TextStyle(color: Colors.white38, fontSize: 12),
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
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Aucun résultat pour "${_searchController.text}"'
                  : 'Aucun film trouvé',
              style:
              const TextStyle(color: Colors.white38, fontSize: 15),
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
        crossAxisCount:   2,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
        childAspectRatio: 0.62,
      ),
      itemCount: _results.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (_, index) {
        if (index >= _results.length) return _buildSkeletonCard();
        return switch (_results[index]) {
          MovieResult(:final movie)   => SearchMovieCard(movie: movie),
          PersonResult(:final person) => SearchPersonCard(person: person),
        };
      },
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
  final List<Genre> genres;
  final Set<int>    selectedGenreIds;
  final double      minRating;
  final int?        selectedYear;
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
  late double   _rating;
  late int?     _year;

  final _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _genreIds = Set.from(widget.selectedGenreIds);
    _rating   = widget.minRating;
    _year     = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
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
                      _rating   = 0.0;
                      _year     = null;
                    }),
                    child: const Text('Réinitialiser',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 13)),
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
                    _AppSlider(
                      value:     _rating,
                      min:       0,
                      max:       9,
                      divisions: 18,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Toutes',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11)),
                        Text('9.0',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    _year != null ? 'Année : $_year' : 'Année : toutes',
                    _AppSlider(
                      value:     (_year ?? _currentYear).toDouble(),
                      min:       1950,
                      max:       _currentYear.toDouble(),
                      divisions: _currentYear - 1950,
                      onChanged: (v) =>
                          setState(() => _year = v.toInt()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('1950',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11)),
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
                        Text('$_currentYear',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
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
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
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
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.genres.map((genre) {
        final isSelected = _genreIds.contains(genre.id);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _genreIds.remove(genre.id);
            } else {
              _genreIds.add(genre.id);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                isSelected ? Colors.white : Colors.white12,
              ),
            ),
            child: Text(
              genre.name,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AppSlider extends StatelessWidget {
  final double              value;
  final double              min;
  final double              max;
  final int                 divisions;
  final ValueChanged<double> onChanged;

  const _AppSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor:   Colors.white,
        thumbColor:         Colors.white,
        overlayColor:       Colors.white12,
        inactiveTrackColor: Colors.white12,
        trackHeight:        3,
        thumbShape:
        const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        value:     value,
        min:       min,
        max:       max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}