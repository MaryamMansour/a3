import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'dart:math';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();

    const int minCount = 2;
    // get platform of context.
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: StaggeredGrid.count(
          crossAxisSpacing: 20,
          axisDirection: AxisDirection.down,
          crossAxisCount: min(widthCount, minCount),
          children: const [
            MyTasksSection(limit: 5),
            MySpacesSection(limit: 5),
            MyEventsSection(),
          ],
        ),
      ),
    );
  }
}
