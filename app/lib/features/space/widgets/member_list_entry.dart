import 'dart:async';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/services.dart';

class ChangePowerLevel extends StatefulWidget {
  final Member member;
  final Member? myMembership;
  const ChangePowerLevel({
    Key? key,
    required this.member,
    this.myMembership,
  }) : super(key: key);

  @override
  _ChangePowerLevelState createState() => _ChangePowerLevelState();
}

class _ChangePowerLevelState extends State<ChangePowerLevel> {
  final TextEditingController dropDownMenuCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? currentMemberStatus;
  int? customValue;

  @override
  void initState() {
    super.initState();
    currentMemberStatus = widget.member.membershipStatusStr();
  }

  void _updateMembershipStatus(String? value) {
    setState(() {
      currentMemberStatus = value;
    });
  }

  void _newCustomLevel(String? value) {
    setState(() {
      customValue = value != null ? int.tryParse(value) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final memberStatus = member.membershipStatusStr();
    final currentPowerLevel = member.powerLevel();
    return AlertDialog(
      title: const Text('Update Power level'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Change the power level of'),
            Text(member.userId().toString()),
            // Row(
            //   children: [
            Text('from $memberStatus ($currentPowerLevel) to '),
            Padding(
              padding: const EdgeInsets.all(5),
              child: DropdownButtonFormField(
                value: currentMemberStatus,
                onChanged: _updateMembershipStatus,
                items: const [
                  DropdownMenuItem(
                    child: Text('Admin'),
                    // leadingIcon: Icon(Atlas.crown_winner_thin),
                    value: 'Admin',
                  ),
                  DropdownMenuItem(
                    child: Text('Moderator'),
                    // leadingIcon: Icon(Atlas.shield_star_win_thin),
                    value: 'Mod',
                  ),
                  DropdownMenuItem(
                    child: Text('Regular'),
                    value: 'Regular',
                  ),
                  DropdownMenuItem(
                    child: Text('Custom'),
                    value: 'Custom',
                  ),
                ],
              ),
            ),
            Visibility(
              visible: currentMemberStatus == 'Custom',
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'any number',
                    labelText: 'Custom power level',
                  ),
                  onChanged: _newCustomLevel,
                  initialValue: currentPowerLevel.toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ], // Only numbers
                  validator: (String? value) {
                    return currentMemberStatus == 'Custom' &&
                            (value == null || int.tryParse(value) == null)
                        ? 'You need to enter the custom value as a number.'
                        : null;
                  },
                ),
              ),
            ),
          ],
          //   ),
          // ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final freshMemberStatus = widget.member.membershipStatusStr();
              if (freshMemberStatus == currentMemberStatus) {
                // nothing to do, all the same.
                Navigator.pop(context, null);
                return;
              }
              int? newValue;
              if (currentMemberStatus == 'Admin') {
                newValue = 100;
              } else if (currentMemberStatus == 'Mod') {
                newValue = 50;
              } else if (currentMemberStatus == 'Regular') {
                newValue = 0;
              } else {
                newValue = customValue ?? 0;
              }

              if (currentPowerLevel == newValue) {
                // nothing to be done.
                newValue = null;
              }

              Navigator.pop(context, newValue);
              return;
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class MemberListEntry extends ConsumerWidget {
  final Member member;
  final Space space;
  final Member? myMembership;

  const MemberListEntry({
    super.key,
    required this.member,
    required this.space,
    this.myMembership,
  });

  Future<void> changePowerLevel(BuildContext context, WidgetRef ref) async {
    final newPowerlevel = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) =>
          ChangePowerLevel(member: member, myMembership: myMembership),
    );
    if (newPowerlevel != null) {
      final userId = member.userId().toString();
      popUpDialog(
        context: context,
        title: Text(
          'Updating Power level of $userId',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        isLoader: true,
      );
      await space.updatePowerLevel(userId, newPowerlevel);
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(context, 'PowerLevel update submitted');
    }
  }

  Widget submenu(BuildContext context, WidgetRef ref) {
    final List<PopupMenuEntry> submenu = [];

    submenu.add(
      PopupMenuItem(
        onTap: () {
          Clipboard.setData(
            ClipboardData(
              text: member.userId().toString(),
            ),
          );
          customMsgSnackbar(
            context,
            'Username copied to clipboard',
          );
        },
        child: const Text('Copy username'),
      ),
    );

    if (myMembership != null) {
      submenu.add(const PopupMenuDivider());
      if (myMembership!.canString('CanUpdatePowerLevels')) {
        submenu.add(
          PopupMenuItem(
            onTap: () async {
              await changePowerLevel(context, ref);
            },
            child: const Text('Change Power Level'),
          ),
        );
      }

      if (myMembership!.canString('CanKick')) {
        submenu.add(
          PopupMenuItem(
            onTap: () => customMsgSnackbar(
              context,
              'Kicking not yet implemented yet',
            ),
            child: const Text('Kick User'),
          ),
        );

        if (myMembership!.canString('CanBan')) {
          submenu.add(
            PopupMenuItem(
              onTap: () => customMsgSnackbar(
                context,
                'Kicking not yet implemented yet',
              ),
              child: const Text('Kick & Ban User'),
            ),
          );
        }
      }

      // if (submenu.isNotEmpty) {
      //   // add divider
      //   submenu.add(const PopupMenuDivider());
      // }
      // submenu.add(
      //   PopupMenuItem(
      //     onTap: () => _handleLeaveSpace(context, space, ref),
      //     child: const Text('Leave Space'),
      //   ),
      // );
    }

    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.neutral5,
      ),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder: (BuildContext context) => submenu,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileProvider(member));
    final userId = member.userId().toString();
    final memberStatus = member.membershipStatusStr();
    final List<Widget> trailing = [];
    debugPrint(memberStatus);
    if (memberStatus == 'Admin') {
      trailing.add(
        const Tooltip(
          message: 'Space Admin',
          child: Icon(Atlas.crown_winner_thin),
        ),
      );
    } else if (memberStatus == 'Mod') {
      trailing.add(
        const Tooltip(
          message: 'Space Moderator',
          child: Icon(Atlas.shield_star_win_thin),
        ),
      );
    } else if (memberStatus == 'Custom') {
      trailing.add(
        Tooltip(
          message: 'Custom Power Level (${member.powerLevel()})',
          child: const Icon(Atlas.star_medal_award_thin),
        ),
      );
    }
    if (myMembership != null) {
      trailing.add(submenu(context, ref));
    }
    return Card(
      child: ListTile(
        leading: profile.when(
          data: (data) => ActerAvatar(
            mode: DisplayMode.User,
            uniqueId: member.userId().toString(),
            size: 18,
            avatar: data.getAvatarImage(),
            displayName: data.displayName,
          ),
          loading: () => const Text('loading'),
          error: (e, t) => Text('loading avatar failed: $e'),
        ),
        title: profile.when(
          data: (data) => Text(data.displayName ?? userId),
          loading: () => Text(userId),
          error: (e, s) => Text('loading profile failed: $e'),
        ),
        subtitle: Text(userId),
        trailing: Row(
          children: trailing,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
        ),
      ),
    );
  }
}
