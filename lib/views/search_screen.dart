// Tetap memakai facade Flutter agar proyek juga bisa dibuka di SDK sebelum 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../data/local_places.dart';
import '../data/open_meteo.dart';
import '../models/place.dart';
import '../viewmodels/search_model.dart';
import 'style.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.api, required this.local});
  final OpenMeteo api;
  final LocalPlaces local;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  late final SearchModel _model;
  late final Listenable _state;

  @override
  void initState() {
    super.initState();
    _model = SearchModel(widget.api);
    _state = Listenable.merge([_model, widget.local]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _favorite(Place place) async {
    try {
      await widget.local.toggleFavorite(place);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorit gagal disimpan. Coba lagi.')),
        );
      }
    }
  }

  void _clear() {
    _controller.clear();
    _model.changeQuery('');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BrandBar(back: () => Navigator.pop(context), actions: const []),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Overline('02 / JELAJAH LOKASI'),
                  const SizedBox(height: 7),
                  Semantics(
                    header: true,
                    child: Text(
                      'Cari kota',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cek cuaca kota lain atau simpan kota favoritmu.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 17),
                  TextField(
                    controller: _controller,
                    onChanged: _model.changeQuery,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (text) =>
                        _model.changeQuery(text, immediate: true),
                    decoration: InputDecoration(
                      labelText: 'Nama kota',
                      hintText: 'Contoh: Bandung',
                      prefixIcon: const Icon(Icons.search_rounded, color: teal),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (_, entry, _) => entry.text.isEmpty
                            ? const SizedBox.shrink()
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: _clear,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: _state,
                    builder: (context, _) => _results(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sumber lokasi: Open-Meteo Geocoding',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _results() {
    final recent = widget.local.recent;
    final favorites = widget.local.favorites;
    final Widget result;
    if (_model.query.isEmpty) {
      result = const SizedBox.shrink();
    } else if (_model.query.length < 2) {
      result = const StatusPanel(
        icon: Icons.short_text_rounded,
        title: 'Nama kota terlalu pendek',
        message: 'Ketik minimal dua karakter untuk mencari kota.',
      );
    } else if (_model.loading) {
      result = const StatusPanel(
        icon: Icons.search,
        loading: true,
        title: 'Mencari kota',
        message: 'Mengambil hasil dari Open-Meteo…',
      );
    } else if (_model.error case final String error) {
      result = StatusPanel(
        icon: Icons.wifi_off_rounded,
        title: 'Pencarian gagal',
        message: error,
        onRetry: () => _model.changeQuery(_controller.text, immediate: true),
      );
    } else if (_model.results.isEmpty) {
      result = StatusPanel(
        icon: Icons.location_off_outlined,
        title: 'Kota tidak ditemukan',
        message:
            'Tidak ada hasil untuk “${_model.query}”. Coba ejaan atau nama kota lain.',
      );
    } else {
      result = _group('HASIL PENCARIAN', _model.results, count: true);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        result,
        if (_model.query.isEmpty || favorites.isNotEmpty) ...[
          if (_model.query.isNotEmpty) const SizedBox(height: 20),
          if (favorites.isNotEmpty)
            _group('KOTA FAVORIT', favorites, count: true)
          else
            const StatusPanel(
              icon: Icons.star_border_rounded,
              title: 'Belum ada kota favorit',
              message:
                  'Cari nama kota, lalu ketuk bintang untuk menyimpannya di sini.',
            ),
        ],
        if (_model.query.isEmpty && recent.isNotEmpty) ...[
          const SizedBox(height: 20),
          _group('TERAKHIR DIBUKA', recent),
        ],
      ],
    );
  }

  Widget _group(String label, List<Place> places, {bool count = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Overline(label),
              if (count)
                Text(
                  '${places.length} lokasi',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, place) in places.indexed) ...[
                  if (i != 0)
                    const Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 12,
                      color: line,
                    ),
                  _PlaceTile(
                    place: place,
                    favorite: widget.local.isFavorite(place),
                    onSelect: () => Navigator.pop(context, place),
                    onFavorite: () => _favorite(place),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.favorite,
    required this.onSelect,
    required this.onFavorite,
  });
  final Place place;
  final bool favorite;
  final VoidCallback onSelect, onFavorite;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onSelect,
    contentPadding: const EdgeInsets.only(left: 12, right: 6),
    leading: const CircleAvatar(
      radius: 18,
      backgroundColor: mint,
      foregroundColor: teal,
      child: Icon(Icons.location_on_outlined, size: 18),
    ),
    title: Text(
      place.name,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: place.detail.isEmpty
        ? null
        : Text(
            place.detail,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
    trailing: IconButton(
      tooltip: favorite
          ? 'Hapus ${place.name} dari favorit'
          : 'Simpan ${place.name} ke favorit',
      onPressed: onFavorite,
      icon: Icon(
        favorite ? Icons.star_rounded : Icons.star_outline_rounded,
        color: favorite ? const Color(0xFF946210) : teal,
      ),
    ),
  );
}
