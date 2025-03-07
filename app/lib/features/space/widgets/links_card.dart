import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:core';

class LinksCard extends ConsumerWidget {
  final String spaceId;
  const LinksCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(pinnedLinksProvider(spaceId));

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Links',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              direction: Axis.horizontal,
              spacing: 10,
              runSpacing: 10,
              children: [
                ...pins.when(
                  data: (pins) => pins.map(
                    (pin) => OutlinedButton(
                      onPressed: () async {
                        final target = pin.url()!;
                        await openLink(target, context);
                      },
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.neutral4,
                              style: BorderStyle.solid,
                              strokeAlign: 5,
                            ),
                          ),
                        ),
                      ),
                      child: Text(
                        pin.title(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  error: (error, stack) =>
                      [Text('Loading pins failed: $error')],
                  loading: () => [const Text('Loading')],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
