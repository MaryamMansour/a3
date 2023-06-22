import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class TopNavBar extends StatefulWidget {
  const TopNavBar({super.key});

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabLabels = [
    'Overview',
    'Chat',
    'Spaces',
  ];
  final List<IconData> tabIcons = const [
    Atlas.layout_half_thin,
    Atlas.chats_thin,
    Atlas.connection_thin,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: tabLabels.length);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return (constraints.maxWidth > 600)
            ? Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  color: Theme.of(context).colorScheme.background,
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  labelColor: Colors.white,
                  indicatorColor: Theme.of(context).colorScheme.tertiary,
                  tabs: List.generate(
                    tabLabels.length,
                    (index) => Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tabIcons[index]),
                          const SizedBox(width: 10),
                          Text(tabLabels[index]),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  labelColor: Colors.white,
                  labelPadding: const EdgeInsets.all(8),
                  indicatorColor: Theme.of(context).colorScheme.tertiary,
                  tabs: List.generate(
                    tabLabels.length,
                    (index) => Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(tabIcons[index]),
                          const SizedBox(height: 5),
                          Text(tabLabels[index]),
                        ],
                      ),
                    ),
                  ),
                ),
              );
      },
    );
  }
}
