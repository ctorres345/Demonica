import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';
import '../recipes/tree_state.dart';
import 'saved_model.dart';
import 'saved_store.dart';

/// Saved recipes and plans, grouped by target demon, newest group first.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  bool _hideDone = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider).value;
    final all = ref.watch(savedProvider);
    final items = _hideDone ? all.where((e) => !e.done).toList() : all;
    // Entries are newest first, so groups come out in order of their newest entry.
    final groups = groupBy(items, (SavedEntry e) => e.result);
    final doneCount = all.where((e) => e.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAVED'),
        actions: [
          IconButton(
            tooltip: 'Import from a file',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _import,
          ),
          IconButton(
            tooltip: 'Export to a file',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: all.isEmpty ? null : _export,
          ),
        ],
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x8),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${all.length} saved · $doneCount done',
                        style: context.tt.bodySmall,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Hide done'),
                      selected: _hideDone,
                      showCheckmark: false,
                      onSelected: (v) => setState(() => _hideDone = v),
                    ),
                  ],
                ),
                for (final g in groups.entries)
                  if (data.demons[g.key] != null) ...[
                    _GroupHeader(demon: data.demon(g.key), count: g.value.length),
                    for (final e in g.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.x2),
                        child: _SavedCard(entry: e, data: data),
                      ),
                  ],
              ],
            ),
    );
  }

  Future<void> _export() async {
    final text = ref.read(savedProvider.notifier).export();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FilePicker.saveFile(
        fileName: 'demonica-saved-$today.json',
        bytes: utf8.encode(text),
        mimeType: 'application/json',
        dialogTitle: 'Export saved recipes',
      );
    } catch (_) {
      // No file dialog on this platform: fall back to the clipboard.
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save a file, so the list was copied as text.')),
      );
    }
  }

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        dialogTitle: 'Import saved recipes',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open the file picker: $e')));
      return;
    }
    if (file == null) return;
    final String text;
    try {
      text = await file.xFile.readAsString();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not read that file.')));
      return;
    }
    try {
      final r = ref.read(savedProvider.notifier).import(text);
      final parts = [
        '${r.added} added',
        if (r.updated > 0) '${r.updated} updated',
        if (r.skipped > 0) '${r.skipped} skipped (unknown demons or broken entries)',
      ];
      messenger.showSnackBar(SnackBar(content: Text('Imported: ${parts.join(', ')}.')));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border, size: 40, color: dc.accent),
              const SizedBox(height: Space.x3),
              Text('Nothing saved yet', style: context.tt.titleLarge),
              const SizedBox(height: Space.x2),
              Text(
                'Tap the bookmark next to any recipe, or on a demon\'s page, to keep it here. '
                'In the recipe tree, the bookmark at the top saves the whole open path as a '
                'step-by-step plan.',
                textAlign: TextAlign.center,
                style: context.tt.bodySmall,
              ),
              const SizedBox(height: Space.x4),
              FilledButton.icon(
                onPressed: () => context.go('/smt4/demons'),
                icon: const Icon(Icons.auto_awesome_mosaic_outlined, size: 18),
                label: const Text('BROWSE DEMONS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.demon, required this.count});
  final Demon demon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return InkWell(
      onTap: () => context.go('/smt4/demon/${demon.id}'),
      child: Padding(
        padding: const EdgeInsets.only(top: Space.x4, bottom: Space.x2),
        child: Row(
          children: [
            Text('LV ${demon.level}', style: context.tt.labelSmall?.copyWith(color: dc.accent)),
            const SizedBox(width: Space.x2),
            Text(demon.name, style: context.tt.titleMedium),
            const SizedBox(width: Space.x2),
            Text(demon.race, style: context.tt.labelMedium),
            const Spacer(),
            Text(count == 1 ? '1 saved' : '$count saved', style: context.tt.labelSmall),
            Icon(Icons.chevron_right, size: 18, color: dc.textMuted),
          ],
        ),
      ),
    );
  }
}

/// One saved entry: tick box, what it is, price, note and actions. Plans
/// list their steps with their own tick boxes.
class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.entry, required this.data});
  final SavedEntry entry;
  final GameData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = context.dc;
    final notifier = ref.read(savedProvider.notifier);
    final title = switch (entry.type) {
      SavedType.demon => 'Bookmarked · no recipe picked yet',
      SavedType.recipe => _recipeText(entry.steps.single),
      SavedType.path =>
        'Plan · ${entry.steps.length} fusions · ${entry.stepsDone}/${entry.steps.length} done',
    };
    return Container(
      decoration: BoxDecoration(
        color: dc.surface,
        border: Border.all(color: dc.outline),
        borderRadius: Radii.borderSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _openTree(context, ref),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
              child: Row(
                children: [
                  Checkbox(
                    value: entry.done,
                    onChanged: (v) => notifier.setDone(entry.id, v ?? false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: entry.done ? TextDecoration.lineThrough : null,
                            color: entry.done ? dc.textMuted : null,
                          ),
                        ),
                        if (entry.type != SavedType.demon)
                          Text(
                            entry.type == SavedType.path
                                ? 'Total ${macca(entry.macca)} to buy'
                                : macca(entry.macca),
                            style: context.tt.labelMedium,
                          ),
                      ],
                    ),
                  ),
                  if (entry.type == SavedType.recipe &&
                      entry.steps.single.kind != RecipeKind.normal)
                    Tag(entry.steps.single.kind == RecipeKind.special ? 'Special' : 'Element'),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    icon: Icon(Icons.more_vert, size: 18, color: dc.textMuted),
                    onSelected: (v) => switch (v) {
                      'note' => _editNote(context, ref),
                      'tree' => _openTree(context, ref),
                      _ => _remove(context, ref),
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'note',
                        child: Text(entry.note.isEmpty ? 'Add note' : 'Edit note'),
                      ),
                      const PopupMenuItem(value: 'tree', child: Text('Open in tree')),
                      const PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (entry.type == SavedType.path)
            for (final (i, s) in entry.steps.indexed)
              _StepLine(
                index: i,
                step: s,
                text: _recipeText(s),
                onChanged: (v) => notifier.setStepDone(entry.id, i, v),
              ),
          if (entry.note.isNotEmpty)
            InkWell(
              onTap: () => _editNote(context, ref),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x3),
                child: Text(
                  entry.note,
                  style: context.tt.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _recipeText(SavedStep s) {
    String name(String n) {
      final d = data.demons[n];
      return d == null ? n : '$n (${d.race} ${d.level})';
    }

    return s.ingredients.map(name).join(' × ');
  }

  void _openTree(BuildContext context, WidgetRef ref) {
    final demon = data.demons[entry.result];
    if (demon == null) return;
    ref.read(treeExpansionProvider(demon.name).notifier).showSteps(entry.steps);
    context.go('/smt4/demon/${demon.id}/tree');
  }

  void _remove(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(savedProvider.notifier);
    final index = ref.read(savedProvider).indexWhere((e) => e.id == entry.id);
    notifier.remove(entry.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Removed from Saved'),
          action: SnackBarAction(label: 'UNDO', onPressed: () => notifier.restore(entry, index)),
        ),
      );
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: entry.note);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          decoration: const InputDecoration(hintText: 'e.g. needs Mediarahan, do after Lv 60'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) ref.read(savedProvider.notifier).setNote(entry.id, result);
  }
}

/// "2. Nyx × Succubus → Lilith" with its own tick box.
class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.index,
    required this.step,
    required this.text,
    required this.onChanged,
  });
  final int index;
  final SavedStep step;
  final String text;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return InkWell(
      onTap: () => onChanged(!step.done),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x2, 0),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: dc.outline.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            SizedBox(width: 22, child: Text('${index + 1}.', style: context.tt.labelMedium)),
            Checkbox(
              value: step.done,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => onChanged(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: text),
                      TextSpan(
                        text: '  →  ',
                        style: TextStyle(color: dc.accent),
                      ),
                      TextSpan(
                        text: step.result,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  style: context.tt.bodySmall?.copyWith(
                    color: step.done ? dc.textMuted : dc.text,
                    decoration: step.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
            if (step.macca > 0)
              Padding(
                padding: const EdgeInsets.only(left: Space.x2),
                child: Text(macca(step.macca), style: context.tt.labelSmall),
              ),
          ],
        ),
      ),
    );
  }
}
