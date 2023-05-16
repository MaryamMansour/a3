import 'package:acter/features/home/states/client_state.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/home/providers/navigation.dart';

class SidebarWidget extends ConsumerWidget {
  final NavigationRailLabelType labelType;
  const SidebarWidget({
    super.key,
    required this.labelType,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarNavItems = ref.watch(sidebarItemsProvider(context));
    final selectedSidebarIndex =
        ref.watch(currentSelectedSidebarIndexProvider(context));
    final isGuest = ref.watch(clientProvider)!.isGuest();

    return AdaptiveScaffold.standardNavigationRail(
      // main logic
      destinations: sidebarNavItems,
      selectedIndex: selectedSidebarIndex,
      onDestinationSelected: (tabIndex) {
        if (tabIndex != selectedSidebarIndex &&
            sidebarNavItems[tabIndex].location != null) {
          final item = sidebarNavItems[tabIndex];
          // go to the initial location of the selected tab (by index)
          if (item.pushToNavigate) {
            context.push(item.location!);
          } else {
            context.go(item.location!);
          }
        }
      },

      // configuration
      labelType: labelType,
      backgroundColor: Theme.of(context).navigationRailTheme.backgroundColor!,
      selectedIconTheme: const IconThemeData(
        size: 18,
        color: Colors.white,
      ),
      unselectedIconTheme: const IconThemeData(
        size: 18,
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(0),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: !ref.watch(clientProvider)!.isGuest(),
            child: Container(
              key: Keys.avatar,
              margin: const EdgeInsets.only(top: 8),
              child: const UserAvatarWidget(),
            ),
          ),
          const Divider(
            indent: 18,
            endIndent: 18,
          )
        ],
      ),
      trailing: Expanded(
        child: Column(
          children: [
            const Spacer(),
            const Divider(
              indent: 18,
              endIndent: 18,
            ),
            InkWell(
              onTap: () => context.push('/bug_report'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Atlas.bug_file_thin,
                      color: Colors.white,
                    ),
                    Text(
                      'Report',
                      style: Theme.of(context).textTheme.labelSmall,
                      softWrap: false,
                    )
                  ],
                ),
              ),
            ),
            const Divider(
              indent: 18,
              endIndent: 18,
            ),
            Visibility(
              visible: !isGuest,
              child: InkWell(
                key: Keys.logoutBtn,
                onTap: () => confirmationDialog(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Atlas.exit_thin,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        child: Text(
                          'Log Out',
                          style: Theme.of(context).textTheme.labelSmall,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Visibility(
              visible: isGuest,
              child: InkWell(
                key: Keys.loginBtn,
                onTap: () => context.pushNamed('login'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Atlas.entrance_thin,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        child: Text(
                          'Log In',
                          style: Theme.of(context).textTheme.labelSmall,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).build(context);
  }
}
