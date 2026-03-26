import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/records.dart';
import 'panel.dart';

class DeliveryFeedPanel extends StatelessWidget {
  const DeliveryFeedPanel({super.key, required this.events});

  final List<EventRecord> events;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Delivery Feed',
      subtitle: 'Push attempts, acknowledgements, and escalation activity.',
      action: 'View logs',
      child: ListView.separated(
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final event = events[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(event.icon, color: event.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppPalette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.detail,
                        style: const TextStyle(
                          color: AppPalette.textSoft,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  event.time,
                  style: const TextStyle(
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
