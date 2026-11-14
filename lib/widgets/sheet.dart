import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom panel that holds all actions of the game screen (thumb zone).
class GameSheet extends StatelessWidget {
  final List<Widget> children;
  final Color color;

  const GameSheet({
    super.key,
    required this.children,
    this.color = AppColors.raised,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(14, 10, 14, 14 + bottom),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // Keep the controls a comfortable width on tablets.
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            for (final c in children) ...[const SizedBox(height: 10), c],
          ],
        ),
      ),
    );
  }
}

/// Large thumb-friendly button with an optional second line.
class SheetButton extends StatelessWidget {
  final String label;
  final String? detail;
  final VoidCallback? onPressed;
  final bool primary;
  final Color? background;
  final Color? labelColor;
  final bool compact;
  final IconData? icon;

  const SheetButton({
    super.key,
    required this.label,
    this.detail,
    this.onPressed,
    this.primary = false,
    this.background,
    this.labelColor,
    this.compact = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? (primary ? AppColors.amber : AppColors.table);
    final fg = labelColor ??
        (primary || background != null && background != AppColors.table
            ? (bg == AppColors.amber ? AppColors.amberInk : Colors.white)
            : AppColors.fg);
    final sub = fg.withValues(alpha: 0.72);
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: bg == AppColors.table ? AppColors.line : bg, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 10, vertical: 9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: fg),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display(compact ? 20 : 15.5,
                              weight: 700, color: fg),
                        ),
                      ),
                    ],
                  ),
                  if (detail != null && detail!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(10.5,
                          weight: FontWeight.w500, color: sub),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Option row in the decision sheet: title, explanation and a big tag.
class ChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color accent;
  final bool highlighted;
  final VoidCallback onPressed;

  const ChoiceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accent,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.table,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: highlighted ? accent : AppColors.line,
            width: highlighted ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.display(16, weight: 700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: AppText.body(11.5,
                            color: AppColors.muted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(tag, style: AppText.display(22, color: accent)),
            ],
          ),
        ),
      ),
    );
  }
}
