import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import 'saved_model.dart';

/// Saved recipes and plans, newest first, kept on the device.
class SavedNotifier extends Notifier<List<SavedEntry>> {
  static const _key = 'demonica.saved.v1';

  @override
  List<SavedEntry> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final loaded = SavedFile.decode(raw).items;
      // Keep anything saved while loading.
      final ids = state.map((e) => e.id).toSet();
      state = [...state, ...loaded.where((e) => !ids.contains(e.id))];
    } on FormatException {
      // A broken store should not take the app down; start empty.
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, SavedFile.encode(state));
  }

  void _set(List<SavedEntry> next) {
    state = next;
    _save();
  }

  bool contains(String id) => state.any((e) => e.id == id);

  /// Adds [e] at the top, or moves an existing entry with the same id there
  /// (keeping its note and ticks).
  void add(SavedEntry e) {
    final old = state.where((x) => x.id == e.id).firstOrNull;
    _set([old ?? e, ...state.where((x) => x.id != e.id)]);
  }

  void remove(String id) => _set([...state.where((e) => e.id != id)]);

  /// Puts back an entry removed by mistake, at its old position.
  void restore(SavedEntry e, int index) {
    if (contains(e.id)) return;
    final next = [...state]..insert(index.clamp(0, state.length), e);
    _set(next);
  }

  void toggleRecipe(Recipe r, int macca) {
    final id = SavedEntry.recipeId(r);
    contains(id) ? remove(id) : add(SavedEntry.recipe(r, macca));
  }

  void toggleDemon(String name) {
    final id = SavedEntry.demonId(name);
    contains(id) ? remove(id) : add(SavedEntry.demon(name));
  }

  void _update(String id, SavedEntry Function(SavedEntry) f) =>
      _set([for (final e in state) e.id == id ? f(e) : e]);

  void setNote(String id, String note) => _update(id, (e) => e.copyWith(note: note.trim()));
  void setDone(String id, bool v) => _update(id, (e) => e.withDone(v));
  void setStepDone(String id, int step, bool v) => _update(id, (e) => e.withStepDone(step, v));

  String export() => SavedFile.encode(state, pretty: true);

  /// Merges a file into the list. An entry with an id already on the device
  /// is replaced by the one from the file.
  ({int added, int updated, int skipped}) import(String text) {
    final data = ref.read(gameDataProvider).value;
    final parsed = SavedFile.decode(
      text,
      knownDemon: data == null ? null : (n) => data.demons.containsKey(n),
    );
    final incoming = {for (final e in parsed.items) e.id: e};
    var updated = 0;
    final next = <SavedEntry>[];
    for (final e in state) {
      final replacement = incoming.remove(e.id);
      if (replacement != null) updated++;
      next.add(replacement ?? e);
    }
    final added = incoming.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    _set([...added, ...next]);
    return (added: added.length, updated: updated, skipped: parsed.skipped);
  }
}

final savedProvider = NotifierProvider<SavedNotifier, List<SavedEntry>>(SavedNotifier.new);

/// Ids of everything saved, for the filled bookmark icons.
final savedIdsProvider = Provider<Set<String>>(
  (ref) => {for (final e in ref.watch(savedProvider)) e.id},
);
