import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChangeDisplayName extends StatefulWidget {
  final AccountProfile account;
  const ChangeDisplayName({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  _ChangeDisplayNameState createState() => _ChangeDisplayNameState();
}

class _ChangeDisplayNameState extends State<ChangeDisplayName> {
  final TextEditingController newUsername = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    newUsername.text = widget.account.profile.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return AlertDialog(
      title: const Text('Change your display name'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: newUsername,
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
              final currentUserName = account.profile.displayName;
              final newDisplayName = newUsername.text;
              if (currentUserName != newDisplayName) {
                Navigator.pop(context, newDisplayName);
              } else {
                Navigator.pop(context, null);
              }
              return;
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class MyProfile extends ConsumerWidget {
  const MyProfile({super.key});

  Future<void> updateDisplayName(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final newUsername = await showDialog<String?>(
      context: context,
      builder: (BuildContext context) => ChangeDisplayName(account: profile),
    );
    if (newUsername != null) {
      popUpDialog(
        context: context,
        title: Text(
          'Updating Displayname',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        isLoader: true,
      );
      await profile.account.setDisplayName(newUsername);
      ref.invalidate(accountProfileProvider);
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(context, 'Display Name update submitted');
    }
  }

  void _handleAvatarUpload(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Upload Avatar',
      type: FileType.image,
    );
    if (result != null) {
      final file = result.files.first;
      await profile.account.uploadAvatar(file.path!);
      customMsgSnackbar(context, 'Avatar uploaded');
    } else {
      // user cancelled the picker
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProfileProvider);
    return account.when(
      data: (account) => Scaffold(
        appBar: AppBar(
          title: const Text('My profile'),
          actions: [
            IconButton(
              icon: const Icon(Atlas.construction_tools_thin),
              onPressed: () {
                context.go('/settings');
              },
            ),
            PopupMenuButton(
              color: Theme.of(context).colorScheme.surface,
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                PopupMenuItem(
                  onTap: () => logoutConfirmationDialog(context, ref),
                  child: Row(
                    children: [
                      const Icon(Atlas.exit_thin),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          AppLocalizations.of(context)!.logOut,
                          style: Theme.of(context).textTheme.labelSmall,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    width: double.infinity,
                    height: 230,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: const SizedBox(),
                    ),
                  ),
                  Positioned(
                    left: 50,
                    top: 40,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 100,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _handleAvatarUpload(
                              account,
                              context,
                              ref,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(width: 5),
                              ),
                              child: ActerAvatar(
                                mode: DisplayMode.User,
                                uniqueId: account.account.userId().toString(),
                                avatar: account.profile.getAvatarImage(),
                                displayName: account.profile.displayName,
                                size: 100,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(account.profile.displayName ?? ''),
                              IconButton(
                                iconSize: 14,
                                icon: const Icon(Atlas.pencil_edit_thin),
                                onPressed: () async {
                                  await updateDisplayName(
                                    account,
                                    context,
                                    ref,
                                  );
                                },
                              ),
                            ],
                          ),
                          Text(account.account.userId().toString()),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 25),
              DefaultTabController(
                length: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const TabBar(
                      tabs: [
                        Tab(
                          child: Text('News'),
                        ),
                        Tab(
                          child: Text('Feed'),
                        ),
                        Tab(
                          child: Text('More details'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 100,
                      child: const TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          Text(''),
                          Text(''),
                          Text(''),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      error: (e, trace) => Text('error: $e'),
      loading: () => const Text('loading'),
    );
  }
}
