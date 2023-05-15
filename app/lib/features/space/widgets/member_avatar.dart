import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_avatar/acter_avatar.dart';

final membersProfileProvider =
    FutureProvider.family<UserProfile, Member>((ref, member) async {
  return await member.getProfile();
});

class MemberAvatar extends ConsumerWidget {
  final Member member;
  const MemberAvatar({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(membersProfileProvider(member));

    return profile.when(
      data: (data) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.neutral4,
                ),
                shape: BoxShape.circle,
              ),
              child: ActerAvatar(
                mode: DisplayMode.User,
                uniqueId: member.userId().toString(),
                size: 20,
                avatarProviderFuture: remapForAvatar(data.getAvatar()),
                displayName: data.getDisplayName(),
              ),
            ),
          ],
        );
      },
      error: (error, _) => const Text('Couldn\'t load avatar'),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
