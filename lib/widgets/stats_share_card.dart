import 'package:flutter/material.dart';
import '../services/movie_action_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

const double _kCardWidth = 500.0;
const double _kPad = 16.0;
const int _kCols = 5;
const double _kGap = 5.0;

double _posterW() =>
    (_kCardWidth - _kPad * 2 - _kGap * (_kCols - 1)) / _kCols;

double _posterH() => _posterW() * 1.45;

class StatsShareCard extends StatefulWidget {
  final int year;
  final String username;
  final String initials;

  const StatsShareCard({
    super.key,
    required this.year,
    required this.username,
    required this.initials,
  });

  @override
  State<StatsShareCard> createState() => _StatsShareCardState();
}

class _StatsShareCardState extends State<StatsShareCard> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _share() async {
    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/stats_${widget.year}.png');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Mes stats ciné ${widget.year} sur CINEART',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de générer la carte.'),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _share,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E1E1E)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.ios_share_rounded, color: Colors.white54, size: 15),
                SizedBox(width: 8),
                Text(
                  'Partager mes stats',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: -4000,
          top: 0,
          child: SizedBox(
            width: _kCardWidth,
            child: Screenshot(
              controller: _screenshotController,
              child: _StatsCard(
                year: widget.year,
                username: widget.username,
                initials: widget.initials,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int year;
  final String username;
  final String initials;

  const _StatsCard({
    required this.year,
    required this.username,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final allMovies = MovieActionService().getRatedMoviesForYear(year);
    final sorted = [...allMovies]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    final avg = MovieActionService().getAverageRatingForYear(year);
    final trophies = MovieActionService().getTrophiesForYear(year).length;
    final actor = MovieActionService().getMostWatchedActorForYear(year);
    final director = MovieActionService().getMostWatchedDirectorForYear(year);
    final genre = MovieActionService().getMostWatchedGenreForYear(year);

    return Container(
      width: _kCardWidth,
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildHeroSection(allMovies.length, avg, trophies),
          _buildHighlightsRow(actor, director, genre),
          _buildThinDivider(),
          if (sorted.isNotEmpty) _buildPosterGrid(sorted),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 18, _kPad, 0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text(
            'CINEART',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(int total, double avg, int trophies) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 12, _kPad, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$year',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    height: 0.88,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'mon année ciné',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statBlock('$total', 'films'),
              const SizedBox(width: 18),
              _statBlockColored(
                avg > 0 ? avg.toStringAsFixed(1) : '—',
                'moy.',
                const Color(0xFFE53935),
              ),
              const SizedBox(width: 18),
              _statBlock('$trophies', 'trophées'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1,
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _statBlockColored(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1,
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsRow(String? actor, String? director, String? genre) {
    final items = <(String, String)>[
      if (actor != null) ('ACTEUR', actor),
      if (director != null) ('RÉAL.', director),
      if (genre != null) ('GENRE', genre),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 12),
      child: Row(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Container(
              width: 1,
              height: 26,
              color: const Color(0xFF111111),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            );
          }
          final item = items[i ~/ 2];
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.$2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildThinDivider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 1,
      color: const Color(0xFF0D0D0D),
    );
  }

  Widget _buildPosterGrid(List movies) {
    final pw = _posterW();
    final ph = _posterH();
    final rows = <List>[];
    for (int i = 0; i < movies.length; i += _kCols) {
      rows.add(movies.sublist(i, (i + _kCols).clamp(0, movies.length)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CLASSEMENT',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(rows.length, (ri) {
            final row = rows[ri];
            return Padding(
              padding: const EdgeInsets.only(bottom: _kGap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(row.length, (ci) {
                    final action = row[ci];
                    final rank = ri * _kCols + ci + 1;
                    final rating = action.rating?.toInt();
                    final posterPath = action.posterPath ?? '';
                    final title = action.movieTitle ?? '';
                    return Container(
                      margin: EdgeInsets.only(
                          right: ci < row.length - 1 ? _kGap : 0),
                      width: pw,
                      height: ph,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: posterPath.isNotEmpty
                                ? Image.network(
                              'https://image.tmdb.org/t/p/w185$posterPath',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _emptyPoster(title),
                            )
                                : _emptyPoster(title),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xF2000000),
                                    Colors.transparent
                                  ],
                                  stops: [0.0, 0.65],
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(6),
                                  bottomRight: Radius.circular(6),
                                ),
                              ),
                              padding:
                              const EdgeInsets.fromLTRB(5, 20, 18, 5),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.none,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            left: 5,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$rank',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          if (rating != null)
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.88),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFE53935)
                                        .withOpacity(0.75),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '$rating',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (row.length < _kCols)
                    ...List.generate(
                      _kCols - row.length,
                          (fi) => Container(
                        margin: EdgeInsets.only(
                          right: fi < (_kCols - row.length - 1) ? _kGap : 0,
                        ),
                        width: pw,
                        height: ph,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _emptyPoster(String title) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF141414)),
      ),
      child: title.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 7,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 10, _kPad, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'CINEART',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}