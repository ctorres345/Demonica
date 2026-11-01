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
    final tt = context.tt;
    final divider = Divider(height: 1, thickness: 1, color: dc.outline);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x2),
                      color: dc.surfaceHigh,
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border, size: Space.x4, color: dc.accent),
                          const SizedBox(width: Space.x2),
                          Expanded(
                            child: Text(
                              'FUSION CHECKLIST',
                              style: tt.labelSmall?.copyWith(color: dc.accent),
                            ),
                          ),
                          const Tag('0 SAVED'),
                        ],
                      ),
                    ),
                    divider,
                    Padding(
                      padding: const EdgeInsets.all(Space.x4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nothing saved yet', style: tt.headlineSmall),
                          const SizedBox(height: Space.x2),
                          Text(
                            'Keep demons, recipes, and multi-step fusion plans here. '
                            'Tick off each step as you fuse, and add notes for skills or levels.',
                            style: tt.bodySmall,
                          ),
                          const SizedBox(height: Space.x3),
                          SizedBox(
                            width: double.infinity,
                            child: _Panel(
                              color: dc.bg,
                              radius: Radii.borderSmall,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Space.x3,
                                vertical: Space.x2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EXAMPLE',
                                    style: tt.labelSmall?.copyWith(color: dc.textMuted),
                                  ),
                                  const SizedBox(height: Space.x1),
                                  const _ExampleStep(
                                    done: true,
                                    pair: '1. Centaur × Fuxi',
                                    result: 'Angel',
                                  ),
                                  const SizedBox(height: Space.x1),
                                  const _ExampleStep(
                                    done: false,
                                    pair: '2. Angel × Tam Lin',
                                    result: 'Senri',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SectionHeader('How to save'),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HowToSaveRow(
                      icon: Icons.bookmark_border,
                      title: 'Demon or recipe',
                      tag: 'BOOKMARK',
                      body: 'Tap the bookmark icon on a demon page or next to any recipe.',
                    ),
                    divider,
                    const _HowToSaveRow(
                      icon: Icons.account_tree_outlined,
                      title: 'Recipe tree path',
                      tag: 'SAVE PATH',
                      body:
                          'Open a fusion chain in the recipe tree, then tap SAVE PATH at the top.',
                    ),
                    divider,
                    const _HowToSaveRow(
                      icon: Icons.route_outlined,
                      title: 'Skill plan',
                      tag: 'PLAN',
                      body: 'Find fusions in Plan, then bookmark the result or tick any step.',
                    ),
                  ],
                ),
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

/// A bordered box for the empty state's cards.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color, this.radius, this.padding});

  final Widget child;
  final Color? color;
  final BorderRadius? radius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? dc.surface,
        border: Border.all(color: dc.outline),
        borderRadius: radius ?? Radii.borderMedium,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// One line of the empty state's sample plan. It only illustrates; nothing taps.
class _ExampleStep extends StatelessWidget {
  const _ExampleStep({required this.done, required this.pair, required this.result});

  final bool done;
  final String pair;
  final String result;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final style = context.tt.labelMedium?.copyWith(
      color: done ? dc.textMuted : dc.text,
      decoration: done ? TextDecoration.lineThrough : null,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_box : Icons.check_box_outline_blank,
          size: Space.x4,
          color: done ? dc.accent : dc.textMuted,
        ),
        const SizedBox(width: Space.x2),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: pair),
                TextSpan(
                  text: ' → ',
                  style: done ? null : style?.copyWith(color: dc.accent),
                ),
                TextSpan(text: result),
              ],
            ),
            style: style,
          ),
        ),
      ],
    );
  }
}

class _HowToSaveRow extends StatelessWidget {
  const _HowToSaveRow({
    required this.icon,
    required this.title,
    required this.tag,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String tag;
  final String body;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.all(Space.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Panel(
            color: dc.surfaceHigh,
            radius: Radii.borderSmall,
            padding: const EdgeInsets.all(Space.x2),
            child: Icon(icon, size: Space.x4, color: dc.accent),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: tt.titleMedium)),
                    const SizedBox(width: Space.x2),
                    Tag(tag),
                  ],
                ),
                const SizedBox(height: Space.x1),
                Text(body, style: tt.bodySmall),
              ],
            ),
          ),
        ],
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
                        if (entry.type != SavedType.demon && ref.watch(showPricesProvider))
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
                  IconButton(
                    tooltip: 'Remove',
                    icon: Icon(Icons.delete_outline, size: 18, color: dc.textMuted),
                    onPressed: () => _remove(context, ref),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.x1),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: dc.outline.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _editNote(context, ref),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: Text(entry.note.isEmpty ? 'Add note' : 'Edit note'),
                ),
                TextButton.icon(
                  onPressed: () => _openTree(context, ref),
                  icon: const Icon(Icons.account_tree_outlined, size: 16),
                  label: const Text('Open in tree'),
                ),
              ],
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
class _StepLine extends ConsumerWidget {
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

  Widget _stepText(BuildContext context) {
    final dc = context.dc;
    return Text.rich(
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = context.dc;
    // Only the tick box and the step text toggle the step, so a tap on the
    // number, the price or the gaps while scrolling does not tick it.
    return Container(
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => onChanged(!step.done),
                borderRadius: Radii.borderSmall,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: Space.x1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in step.levelUps.entries)
                        Text(
                          'First level ${e.key} to Lv ${e.value}',
                          style: context.tt.labelSmall?.copyWith(color: dc.accent),
                        ),
                      _stepText(context),
                      if (step.skills.isNotEmpty)
                        Text('Keep: ${step.skills.join(', ')}', style: context.tt.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (step.macca > 0 && ref.watch(showPricesProvider))
            Padding(
              padding: const EdgeInsets.only(left: Space.x2),
              child: Text(macca(step.macca), style: context.tt.labelSmall),
            ),
        ],
      ),
    );
  }
}
