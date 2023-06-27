import 'package:acter/common/utils/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TabEntry {
  final Key key;
  final String label;
  final String target;
  final Widget icon;

  const TabEntry({
    required this.key,
    required this.icon,
    required this.label,
    required this.target,
  });
}

final tabsProvider =
    Provider.family<List<TabEntry>, BuildContext>((ref, context) {
  final features = ref.watch(featuresProvider);
  bool isActive(f) => features.isActive(f);
  List<TabEntry> tabs = [
    const TabEntry(
      key: Key('overview'),
      label: 'Overview',
      icon: Icon(Atlas.layout_half_thin),
      target: '/',
    ),
  ];

  if (isActive(LabsFeature.pins)) {
    tabs.add(
      const TabEntry(
        key: Key('pins'),
        label: 'Pins',
        icon: Icon(Atlas.pin_thin),
        target: '/pins',
      ),
    );
  }

  if (isActive(LabsFeature.tasks)) {
    tabs.add(
      TabEntry(
        key: const Key('tasks'),
        label: 'Tasks',
        icon: SvgPicture.asset(
          'assets/images/tasks.svg',
          semanticsLabel: 'tasks',
          width: 24,
          height: 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        target: '/tasks',
      ),
    );
  }

  if (isActive(LabsFeature.events)) {
    tabs.add(
      const TabEntry(
        key: Key('events'),
        label: 'Events',
        icon: Icon(Atlas.calendar_schedule_thin),
        target: '/events',
      ),
    );
  }

  tabs.add(
    const TabEntry(
      key: Key('chat'),
      label: 'Chat',
      icon: Icon(Atlas.chats_thin),
      target: '/chat',
    ),
  );
  tabs.add(
    const TabEntry(
      key: Key('spaces'),
      label: 'Spaces',
      icon: Icon(Atlas.connection_thin),
      target: '/spaces',
    ),
  );
  return tabs;
});

class TopNavBar extends ConsumerStatefulWidget {
  const TopNavBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopNavBarState();
}

class _TopNavBarState extends ConsumerState<TopNavBar>
    with SingleTickerProviderStateMixin {
  late final AutoDisposeProviderFamily<TabController, BuildContext>
      recentWatchScreenTabStateTestProvider;

  @override
  void initState() {
    recentWatchScreenTabStateTestProvider =
        Provider.autoDispose.family<TabController, BuildContext>(
      (ref, context) => TabController(
        length: ref.watch(tabsProvider(context)).length,
        vsync: this,
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(tabsProvider(context));

    final _tabController =
        ref.watch(recentWatchScreenTabStateTestProvider(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        print(constraints.maxWidth);
        final useCols = constraints.maxWidth < (150 * tabs.length);
        int minItemWidth = useCols ? 90 : 150;
        final minTotalWidth = minItemWidth * tabs.length;
        bool scroll_bar = false;
        if (minTotalWidth > constraints.maxWidth) {
          scroll_bar = true;
        }
        return Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            color: Theme.of(context).colorScheme.background,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TabBar(
            controller: _tabController,
            isScrollable: scroll_bar,
            labelStyle: useCols
                ? Theme.of(context).textTheme.labelSmall
                : Theme.of(context).textTheme.bodySmall,
            labelColor: Colors.white,
            labelPadding: useCols ? const EdgeInsets.all(8) : null,
            indicatorColor: Theme.of(context).colorScheme.tertiary,
            tabs: List.generate(
              tabs.length,
              (index) {
                final tabItem = tabs[index];
                final children = [
                  tabItem.icon,
                  useCols
                      ? const SizedBox(height: 5)
                      : const SizedBox(width: 10),
                  Text(tabItem.label),
                ];
                return Tab(
                  key: tabItem.key,
                  child: useCols
                      ? SizedBox(
                          width: minItemWidth.toDouble(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: children,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: children,
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
