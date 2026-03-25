import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/records.dart';
import 'panel.dart';

class DeliveryFeedPanel extends StatelessWidget {
  const DeliveryFeedPanel({
    super.key,
    required this.events,
  });

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppPalette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(event.icon, color: event.color),
                const SizedBox(width: 10),
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
                Text(
                  event.time,
                  style: const TextStyle(
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
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
