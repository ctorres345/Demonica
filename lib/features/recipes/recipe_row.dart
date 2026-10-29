import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

/// "A (Race 4) × B (Race 2)   ≈ 1 020 ¥" with an optional caret and tap.
/// Ingredients that can be recruited get a [RecruitMark].
class RecipeRow extends ConsumerWidget {
  const RecipeRow({
    super.key,
    required this.recipe,
    required this.data,
    required this.cost,
    this.expanded,
    this.onTap,
    this.onIngredientTap,
    this.highlight = false,
    this.trailing,
  });

  final Recipe recipe;
  final GameData data;
  final int cost;

  /// null hides the caret; true/false draws it open/closed.
  final bool? expanded;
  final VoidCallback? onTap;
  final void Function(String demonName)? onIngredientTap;
  final bool highlight;

  /// Shown after the price, e.g. the bookmark button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = context.dc;
    final recruitable = ref.watch(recruitableProvider);
    final spans = <InlineSpan>[];
    for (var i = 0; i < recipe.ingredients.length; i++) {
      final name = recipe.ingredients[i];
      final d = data.demons[name];
      if (i > 0) {
        // Non-breaking spaces keep the × with the second name when the row wraps.
        spans.add(TextSpan(text: '\u00A0 ×\u00A0', style: context.tt.labelMedium));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: InkWell(
            onTap: onIngredientTap == null ? null : () => onIngredientTap!(name),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: name,
                    style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (d != null)
                    TextSpan(text: ' ${d.race} ${d.level}', style: context.tt.labelMedium),
                  if (recruitable.contains(name)) ...[
                    const TextSpan(text: ' '),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: RecruitMark(size: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    final kindTag = switch (recipe.kind) {
      RecipeKind.special => Tag('Special', color: dc.accent),
      RecipeKind.element => const Tag('Element'),
      RecipeKind.sameRace => const Tag('Same race'),
      RecipeKind.normal => null,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.borderSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? dc.accent.withValues(alpha: 0.10) : dc.surface,
          border: Border.all(color: highlight ? dc.accent : dc.outline),
          borderRadius: Radii.borderSmall,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (expanded != null) ...[
              SizedBox(
                width: 18,
                child: Text(
                  expanded! ? '▾' : '▸',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Fonts.mono,
                    color: expanded! ? dc.accent : dc.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(child: Text.rich(TextSpan(children: spans))),
            const SizedBox(width: 8),
            if (kindTag != null) ...[kindTag, const SizedBox(width: 8)],
            Text(macca(cost), style: context.tt.labelMedium),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
