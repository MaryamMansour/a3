import 'package:flutter/material.dart';
import 'package:acter/features/home/providers/events.dart';
import 'package:acter/features/events/widgets/events_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyEventsSection extends ConsumerWidget {
  const MyEventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(myEventsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: EventsCalendar(events: events),
    );
  }
}
