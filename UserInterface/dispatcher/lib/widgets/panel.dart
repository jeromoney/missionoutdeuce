import 'package:flutter/material.dart';

import '../app_palette.dart';
import 'common_widgets.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    this.primaryAction = false,
    this.onActionPressed,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? action;
  final bool primaryAction;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionEyebrow(label: title),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppPalette.textSoft,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null)
                primaryAction
                    ? FilledButton.icon(
                        onPressed: onActionPressed,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(action!),
                      )
                    : OutlinedButton(
                        onPressed: onActionPressed,
                        child: Text(action!),
                      ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(child: child),
        ],
      ),
    );
  }
}
