import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:themed/themed.dart';

class CustomChatInput extends StatelessWidget {
  final Function()? onButtonPressed;
  final controller = Get.put(ChatRoomController());
  final bool isChatScreen;
  final String roomName;
  static const List<List<String>> attachmentNameList = [
    ['camera', 'Camera'],
    ['gif', 'GIF'],
    ['document', 'File'],
    ['location', 'Location'],
  ];

  CustomChatInput({
    Key? key,
    required this.isChatScreen,
    this.onButtonPressed,
    required this.roomName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    return Column(
      children: [
        GetBuilder<ChatRoomController>(
          builder: (control) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: AppCommonTheme.backgroundColorLight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      isChatScreen
                          ? Obx(
                              () => InkWell(
                                onTap: () {
                                  controller.isEmojiVisible.value = false;
                                  controller.isAttachmentVisible.value =
                                      !controller.isAttachmentVisible.value;
                                  controller.focusNode.unfocus();
                                  controller.focusNode.canRequestFocus = true;
                                },
                                child: controller.isAttachmentVisible.value
                                    ? Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppCommonTheme.backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/images/add_rotate.svg',
                                          fit: BoxFit.none,
                                        ),
                                      )
                                    : SvgPicture.asset(
                                        'assets/images/add.svg',
                                        fit: BoxFit.none,
                                      ),
                              ),
                            )
                          : const SizedBox(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            onChanged: ((value) async {
                              controller.sendButtonUpdate();
                              await controller.typingNotice(true);
                            }),
                            maxLines: MediaQuery.of(context).orientation ==
                                    Orientation.portrait
                                ? 6
                                : 2,
                            minLines: 1,
                            controller: controller.textEditingController,
                            focusNode: controller.focusNode,
                            style: const TextStyleRef(
                              TextStyle(color: ChatTheme01.chatInputTextColor),
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              suffixIcon: InkWell(
                                onTap: () {
                                  controller.isAttachmentVisible.value = false;
                                  controller.isEmojiVisible.value =
                                      !controller.isEmojiVisible.value;
                                  controller.focusNode.unfocus();
                                  controller.focusNode.canRequestFocus = true;
                                },
                                child: SvgPicture.asset(
                                  'assets/images/emoji.svg',
                                  fit: BoxFit.none,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  width: 0,
                                  style: BorderStyle.none,
                                ),
                              ),
                              filled: true,
                              fillColor: AppCommonTheme.backgroundColor,
                              hintText: isChatScreen
                                  ? AppLocalizations.of(context)!.newMessage
                                  : '${AppLocalizations.of(context)!.messageTo} $roomName',
                              contentPadding: const EdgeInsets.all(15),
                              hintStyle: ChatTheme01.chatInputPlaceholderStyle,
                              hintMaxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      if (controller.isSendButtonVisible || !isChatScreen)
                        InkWell(
                          onTap: onButtonPressed,
                          child: SvgPicture.asset('assets/images/sendIcon.svg'),
                        ),
                      if (!controller.isSendButtonVisible && isChatScreen)
                        InkWell(
                          onTap: () {
                            controller.handleMultipleImageSelection(
                              context,
                              roomName,
                            );
                          },
                          child: SvgPicture.asset(
                            'assets/images/camera.svg',
                            fit: BoxFit.none,
                          ),
                        ),
                      const SizedBox(width: 10),
                      if (!controller.isSendButtonVisible && isChatScreen)
                        SvgPicture.asset(
                          'assets/images/microphone-2.svg',
                          fit: BoxFit.none,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        EmojiPickerWidget(controller: controller, size: _size),
        AttachmentWidget(
          controller: controller,
          attachmentNameList: attachmentNameList,
          roomName: roomName,
          size: _size,
        ),
      ],
    );
  }
}

class AttachmentWidget extends StatelessWidget {
  final ChatRoomController controller;
  final List<List<String>> attachmentNameList;
  final String roomName;
  final Size size;

  const AttachmentWidget({
    Key? key,
    required this.controller,
    required this.attachmentNameList,
    required this.roomName,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Offstage(
        offstage: !controller.isAttachmentVisible.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          width: double.infinity,
          height: size.height * 0.3,
          color: AppCommonTheme.backgroundColorLight,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: size.height * 0.172,
                decoration: BoxDecoration(
                  color: AppCommonTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        AppLocalizations.of(context)!.grantAccessText,
                        style: ChatTheme01.chatTitleStyle + FontWeight.w400,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text(AppLocalizations.of(context)!.settings),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          AppCommonTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (List<String> item in attachmentNameList)
                        InkWell(
                          onTap: () {
                            switch (item[0]) {
                              case 'camera':
                                controller.isAttachmentVisible.value = false;
                                controller.handleMultipleImageSelection(
                                  context,
                                  roomName,
                                );
                                break;
                              case 'gif':
                                //gif handle
                                break;
                              case 'document':
                                controller.handleFileSelection(context);
                                break;
                              case 'location':
                                //location handle
                                break;
                            }
                          },
                          child: Container(
                            width: 85,
                            decoration: BoxDecoration(
                              color: AppCommonTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/${item[0]}.svg',
                                  fit: BoxFit.none,
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  item[1],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmojiPickerWidget extends StatelessWidget {
  final ChatRoomController controller;
  final Size size;

  const EmojiPickerWidget({
    Key? key,
    required this.controller,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Offstage(
        offstage: !controller.isEmojiVisible.value,
        child: SizedBox(
          height: size.height * 0.3,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              controller.textEditingController.text += emoji.emoji;
              controller.sendButtonUpdate();
            },
            onBackspacePressed: () {
              controller.textEditingController.text = controller
                  .textEditingController.text.characters
                  .skipLast(1)
                  .string;
              if (controller.textEditingController.text.isEmpty) {
                controller.sendButtonUpdate();
              }
            },
            config: Config(
              columns: 7,
              verticalSpacing: 0,
              backspaceColor: AppCommonTheme.primaryColor,
              horizontalSpacing: 0,
              initCategory: Category.SMILEYS,
              bgColor: AppCommonTheme.backgroundColor,
              indicatorColor: AppCommonTheme.primaryColor,
              iconColor: AppCommonTheme.dividerColor,
              iconColorSelected: AppCommonTheme.primaryColor,
              progressIndicatorColor: AppCommonTheme.primaryColor,
              showRecentsTab: true,
              recentsLimit: 28,
              noRecents: Text(
                AppLocalizations.of(context)!.noRecents,
                style: ChatTheme01.chatBodyStyle,
              ),
              tabIndicatorAnimDuration: kTabScrollDuration,
              categoryIcons: const CategoryIcons(),
              buttonMode: ButtonMode.MATERIAL,
            ),
          ),
        ),
      ),
    );
  }
}
