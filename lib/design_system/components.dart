import 'package:flutter/material.dart';
import 'package:fusion_core/fusion_core.dart';

import 'tokens.dart';

/// Small monospace label with an outline, e.g. "SPECIAL", "DLC", "LAW".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color, this.filled = false});
  final String text;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.dc.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? c : null,
        border: Border.all(color: filled ? c : c.withValues(alpha: 0.6)),
        borderRadius: Radii.borderSmall,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: Fonts.mono,
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w500,
          color: filled ? context.dc.onAccent : c,
        ),
      ),
    );
  }
}

/// Alignment tag: LAW / NEUTRAL / CHAOS colored.
class AlignmentTag extends StatelessWidget {
  const AlignmentTag(this.alignment, {super.key, this.full = false});
  final String alignment;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final lc = alignment.split('-').last;
    final label = full ? alignment : (lc == 'Neutral' ? 'NEUT' : lc);
    return Tag(label, color: context.dc.alignmentColor(alignment));
  }
}

/// How a demon is obtained, as a tag. Returns nothing for plain fusions.
class FusionTag extends StatelessWidget {
  const FusionTag(this.demon, {super.key});
  final Demon demon;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return switch (demon.fusion) {
      FusionKind.special => Tag('Special', color: dc.accent),
      FusionKind.accident => Tag('Accident', color: dc.danger),
      FusionKind.enemy => Tag('Enemy only', color: dc.textMuted),
      FusionKind.normal => switch (demon.unlockCategory) {
        'Downloadable Content' => const Tag('DLC'),
        'New Game+' => const Tag('NG+'),
        'Challenge Quests' => const Tag('Quest'),
        'Fiend Encounters' => const Tag('Fiend'),
        _ => const SizedBox.shrink(),
      },
    };
  }
}

/// Level number with a small "LV" caption, monospace.
class LevelBadge extends StatelessWidget {
  const LevelBadge(this.level, {super.key, this.size = 17});
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$level',
          style: TextStyle(
            fontFamily: Fonts.mono,
            fontSize: size,
            fontWeight: FontWeight.w500,
            height: 1,
            color: context.dc.text,
          ),
        ),
        Text('LV', style: context.tt.labelSmall),
      ],
    );
  }
}

/// Colored square used before skill names and in legends.
class ElementDot extends StatelessWidget {
  const ElementDot(this.element, {super.key, this.size = 9});
  final String element;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.ec.of(element),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// One row in a demon list.
class DemonTile extends StatelessWidget {
  const DemonTile({
    super.key,
    required this.demon,
    required this.onTap,
    this.selected = false,
    this.subtitle,
  });

  final Demon demon;
  final VoidCallback onTap;
  final bool selected;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x2),
        decoration: BoxDecoration(
          color: selected ? dc.surfaceHigh : null,
          border: Border(
            bottom: BorderSide(color: dc.outline),
            left: BorderSide(color: selected ? dc.accent : Colors.transparent, width: 3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 40, child: LevelBadge(demon.level)),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(demon.name, style: context.tt.titleMedium),
                  Text(
                    subtitle ?? demon.race,
                    style: context.tt.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.x2),
            FusionTag(demon),
            if (demon.fusion == FusionKind.normal && demon.unlockCategory == null)
              AlignmentTag(demon.alignment),
          ],
        ),
      ),
    );
  }
}

/// WK / RS / NU / RP / DR cells for the 8 elements.
class ResistRow extends StatelessWidget {
  const ResistRow({super.key, required this.resists, required this.order});
  final Map<String, Resist> resists;
  final List<String> order;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Row(
      children: [
        for (final e in order)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Text(
                    elementLabels[e]!.toUpperCase(),
                    style: context.tt.labelSmall?.copyWith(fontSize: 9),
                  ),
                  const SizedBox(height: 3),
                  _ResistCell(resists[e] ?? Resist.none, dc),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ResistCell extends StatelessWidget {
  const _ResistCell(this.r, this.dc);
  final Resist r;
  final DemonicaColors dc;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg, border) = switch (r) {
      Resist.none => ('–', dc.textMuted, null, dc.outline),
      Resist.weak => ('WK', Colors.white, dc.danger, dc.danger),
      Resist.resist => ('RS', dc.text, null, dc.textMuted),
      Resist.nullify => ('NU', dc.accent, null, dc.accent),
      Resist.repel => ('RP', dc.accent, null, dc.accent),
      Resist.drain => ('DR', dc.accent, null, dc.accent),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: Radii.borderSmall,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: Fonts.mono,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

/// A skill line: element dot, name, cost, and when it is learned.
class SkillRow extends StatelessWidget {
  const SkillRow({
    super.key,
    required this.skill,
    required this.learnedAt,
    this.onTap,
    this.trailing,
  });
  final Skill skill;
  final int? learnedAt;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final cost = skill.costMp == 0 ? '' : ' · ${skill.costMp} MP';
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.borderSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: dc.surface,
          border: Border.all(color: dc.outline),
          borderRadius: Radii.borderSmall,
        ),
        child: Row(
          children: [
            ElementDot(skill.element),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                skill.name,
                style: context.tt.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${elementLabels[skill.element]!.toUpperCase()}$cost',
              style: context.tt.labelSmall,
            ),
            if (learnedAt != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                child: Text(
                  learnedAt == 0 ? 'innate' : 'Lv $learnedAt',
                  textAlign: TextAlign.right,
                  style: context.tt.labelSmall?.copyWith(
                    color: learnedAt == 0 ? dc.accent : dc.textMuted,
                  ),
                ),
              ),
            ],
            if (skill.unique) ...[const SizedBox(width: 6), Tag('Unique', color: dc.danger)],
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Small header line for a section: "SKILLS   3 innate · 5 free slots".
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.x4, bottom: Space.x2),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: context.tt.labelSmall),
          const Spacer(),
          if (trailing != null)
            Text(trailing!, style: context.tt.labelSmall?.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

/// Title row of a bottom sheet: "Title          CLEAR  DONE".
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key, required this.onClear});
  final String title;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x2, Space.x2),
      child: Row(
        children: [
          Text(title, style: context.tt.titleLarge),
          const Spacer(),
          TextButton(onPressed: onClear, child: const Text('Clear')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }
}

/// Opens a bottom sheet with a 1 to 99 level slider. [onChanged] gets the
/// level when the slider is released, and null when the user taps Clear.
Future<void> showLevelSheet(
  BuildContext context, {
  required String title,
  required String help,
  required int? current,
  required ValueChanged<int?> onChanged,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) =>
        _LevelSheet(title: title, help: help, initial: current ?? 99, onChanged: onChanged),
  );
}

class _LevelSheet extends StatefulWidget {
  const _LevelSheet({
    required this.title,
    required this.help,
    required this.initial,
    required this.onChanged,
  });
  final String title;
  final String help;
  final int initial;
  final ValueChanged<int?> onChanged;

  @override
  State<_LevelSheet> createState() => _LevelSheetState();
}

class _LevelSheetState extends State<_LevelSheet> {
  late double _v = widget.initial.toDouble();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            widget.title,
            onClear: () {
              widget.onChanged(null);
              Navigator.pop(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _v,
                    min: 1,
                    max: 99,
                    divisions: 98,
                    onChanged: (v) => setState(() => _v = v),
                    onChangeEnd: (v) => widget.onChanged(v.round()),
                  ),
                ),
                SizedBox(width: 56, child: LevelBadge(_v.round(), size: 22)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.x4),
            child: Text(widget.help, style: context.tt.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Macca formatted with thin spaces: 36710 -> "36 710 ¥".
String macca(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b ¥';
}
