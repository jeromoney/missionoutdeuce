import 'package:flutter/material.dart';

import '../app_palette.dart';

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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 420,
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppPalette.textSoft,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (action != null)
                primaryAction
                    ? FilledButton.icon(
                        onPressed: onActionPressed,
                        icon: const Icon(Icons.add_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        label: Text(action!),
                      )
                    : FilledButton.tonal(
                        onPressed: onActionPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDCE8F4),
                          foregroundColor: AppPalette.text,
                        ),
                        child: Text(action!),
                      ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}
