import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/receipt_controller.dart';
import 'package:effektio/models/JoinedRoom.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatListItem extends StatefulWidget {
  final Client client;
  final JoinedRoom room;

  const ChatListItem({
    Key? key,
    required this.client,
    required this.room,
  }) : super(key: key);

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  final ReceiptController recieptController = Get.find<ReceiptController>();
  final ChatListController chatListController = Get.find<ChatListController>();

  List<Member> activeMembers = [];

  @override
  void initState() {
    super.initState();
    chatListController.setRoomProfile(widget.room.conversation, widget.room);
    getActiveMembers();
  }

  @override
  Widget build(BuildContext context) {
    String roomId = widget.room.conversation.getRoomId();
    // ToDo: UnreadCounter
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          onTap: () => handleTap(context),
          leading: CustomAvatar(
            uniqueKey: roomId,
            avatar: widget.room.avatar,
            displayName: widget.room.displayName,
            radius: 25,
            cacheHeight: 62,
            cacheWidth: 60,
            isGroup: true,
            stringName: simplifyRoomId(roomId)!,
          ),
          title: _TitleWidget(
            displayName: widget.room.displayName,
            context: context,
          ),
          subtitle: GetBuilder<ChatListController>(
            id: 'chatroom-$roomId-subtitle',
            builder: (_) => _SubtitleWidget(
              typingUsers: widget.room.typingUsers,
              latestMessage: widget.room.latestMessage,
            ),
          ),
          trailing: _TrailingWidget(
            controller: recieptController,
            room: widget.room.conversation,
            latestMessage: widget.room.latestMessage,
            activeMembers: activeMembers,
            userId: widget.client.account().userId(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Divider(
            indent: 75,
            endIndent: 10,
            color: AppCommonTheme.dividerColor,
          ),
        ),
      ],
    );
  }

  void handleTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          client: widget.client,
          conversation: widget.room.conversation,
          name: widget.room.displayName,
          avatar: widget.room.avatar,
        ),
      ),
    );
  }

  Future<void> getActiveMembers() async {
    activeMembers = (await widget.room.conversation.activeMembers()).toList();
  }
}

class _TitleWidget extends StatelessWidget {
  const _TitleWidget({
    required this.displayName,
    required this.context,
  });

  final String? displayName;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    if (displayName == null) {
      return Text(
        AppLocalizations.of(context)!.loadingName,
        style: ChatTheme01.chatTitleStyle,
      );
    }
    return Text(
      displayName!,
      style: ChatTheme01.chatTitleStyle,
    );
  }
}

class _SubtitleWidget extends StatelessWidget {
  const _SubtitleWidget({
    required this.typingUsers,
    required this.latestMessage,
  });
  final List<types.User> typingUsers;
  final RoomMessage? latestMessage;

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          getUserPlural(typingUsers),
          style: ChatTheme01.latestChatStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    if (latestMessage == null) {
      return const SizedBox.shrink();
    }
    RoomEventItem? eventItem = latestMessage!.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }

    String sender = eventItem.sender();
    String eventType = eventItem.eventType();

    // message event
    switch (eventType) {
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
      case 'm.key.verification.accept':
      case 'm.key.verification.cancel':
      case 'm.key.verification.done':
      case 'm.key.verification.key':
      case 'm.key.verification.mac':
      case 'm.key.verification.ready':
      case 'm.key.verification.start':
      case 'm.reaction':
      case 'm.room.encrypted':
      case 'm.room.redaction':
      case 'm.sticker':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: const TextStyle(color: ChatTheme01.chatBodyTextColor),
              ),
            ),
            Text(
              eventItem.textDesc()!.body(),
              style: const TextStyle(color: ChatTheme01.chatBodyTextColor),
            ),
          ],
        );
      case 'm.room.message':
        TextDesc? textDesc = eventItem.textDesc();
        if (textDesc == null) {
          return const SizedBox();
        }
        String body = textDesc.body();
        String? formattedBody = textDesc.formattedBody();
        if (formattedBody != null) {
          body = simplifyBody(formattedBody);
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: const TextStyle(color: ChatTheme01.chatBodyTextColor),
              ),
            ),
            Flexible(
              child: Html(
                padding: const EdgeInsets.symmetric(vertical: 10),
                // ignore: unnecessary_string_interpolations
                data: '''$body''',
                maxLines: 1,
                defaultTextStyle: const TextStyle(
                  color: ChatTheme01.chatBodyTextColor,
                  overflow: TextOverflow.ellipsis,
                ),
                onLinkTap: (url) => {},
              ),
            ),
          ],
        );
    }
    return const SizedBox.shrink();
  }

  String getUserPlural(List<types.User> authors) {
    if (authors.isEmpty) {
      return '';
    } else if (authors.length == 1) {
      return '${authors[0].firstName} is typing...';
    } else if (authors.length == 2) {
      return '${authors[0].firstName} and ${authors[1].firstName} is typing...';
    } else {
      return '${authors[0].firstName} and ${authors.length - 1} others typing...';
    }
  }
}

class _TrailingWidget extends StatelessWidget {
  const _TrailingWidget({
    required this.controller,
    required this.room,
    required this.activeMembers,
    this.latestMessage,
    required this.userId,
  });
  final ReceiptController controller;
  final Conversation room;
  final List<Member> activeMembers;
  final RoomMessage? latestMessage;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (latestMessage == null) {
      return const SizedBox.shrink();
    }
    RoomEventItem? eventItem = latestMessage!.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }
    String senderID = '';
    types.Status? messageStatus;
    int ts = eventItem.originServerTs();

    List<String> seenByList = controller.getSeenByList(
      room.getRoomId(),
      ts,
    );

    senderID = latestMessage!.eventItem()!.sender();

    messageStatus = seenByList.isEmpty
        ? types.Status.sent
        : seenByList.length < activeMembers.length
            ? types.Status.delivered
            : types.Status.seen;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat.Hm().format(
            DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true),
          ),
          style: ChatTheme01.latestChatDateStyle,
        ),
        senderID == userId
            ? _CustomStatusWidget(status: messageStatus)
            : const SizedBox.shrink(),
      ],
    );
  }
}

class _CustomStatusWidget extends StatelessWidget {
  const _CustomStatusWidget({
    required this.status,
  });

  final types.Status status;

  @override
  Widget build(BuildContext context) {
    if (status == types.Status.delivered) {
      return SvgPicture.asset('assets/images/deliveredIcon.svg');
    } else if (status == types.Status.seen) {
      return SvgPicture.asset('assets/images/seenIcon.svg');
    } else if (status == types.Status.sending) {
      return const Center(
        child: SizedBox(
          height: 10,
          width: 10,
          child: CircularProgressIndicator(
            backgroundColor: Colors.transparent,
            strokeWidth: 1.5,
          ),
        ),
      );
    } else {
      return SvgPicture.asset(
        'assets/images/sentIcon.svg',
        width: 12,
        height: 12,
      );
    }
  }
}
