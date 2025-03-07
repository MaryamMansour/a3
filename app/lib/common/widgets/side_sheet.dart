import 'package:flutter/material.dart';

class SideSheet extends StatelessWidget {
  final String header;
  final Widget body;
  final bool addBackIconButton;
  final bool addCloseIconButton;
  final bool addActions;
  final bool addDivider;
  final String confirmActionTitle;
  final String cancelActionTitle;
  final String? closeButtonTooltip;
  final String? backButtonTooltip;
  final List<Widget>? actions;

  final void Function()? confirmActionOnPressed;
  final void Function()? cancelActionOnPressed;

  const SideSheet({
    super.key,
    required this.header,
    required this.body,
    this.actions,
    this.addBackIconButton = false,
    this.addActions = false,
    this.addDivider = false,
    this.cancelActionOnPressed,
    this.confirmActionOnPressed,
    this.cancelActionTitle = 'Cancel',
    this.confirmActionTitle = 'Save',
    this.closeButtonTooltip,
    this.backButtonTooltip,
    this.addCloseIconButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 1,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
      child: Container(
        constraints: BoxConstraints(
          minWidth: 256,
          maxWidth: size.width <= 600 ? size.width : 400,
          minHeight: size.height,
          maxHeight: size.height,
        ),
        child: Column(
          children: [
            _SheetHeader(
              header: header,
              addBackIconButton: addBackIconButton,
              addCloseIconButton: addCloseIconButton,
              backButtonTooltip: backButtonTooltip,
              closeButtonTooltip: closeButtonTooltip,
            ),
            Expanded(child: body),
            Visibility(
              visible: addActions,
              child: _SheetFooter(
                addDivider: addDivider,
                confirmActionTitle: confirmActionTitle,
                cancelActionTitle: cancelActionTitle,
                actions: actions,
                confirmActionOnPressed: confirmActionOnPressed,
                cancelActionOnPressed: cancelActionOnPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String header;
  final bool addBackIconButton;
  final bool addCloseIconButton;
  final String? backButtonTooltip;
  final String? closeButtonTooltip;

  const _SheetHeader({
    Key? key,
    required this.header,
    required this.addBackIconButton,
    required this.addCloseIconButton,
    this.backButtonTooltip,
    this.closeButtonTooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(addBackIconButton ? 16 : 24, 16, 16, 16),
      child: Row(
        children: [
          Visibility(
            visible: addBackIconButton,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                tooltip: backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
          Text(
            header,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall,
          ),
          Flexible(
            fit: FlexFit.tight,
            child: SizedBox(width: addCloseIconButton ? 12 : 8),
          ),
          Visibility(
            visible: addCloseIconButton,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: closeButtonTooltip,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  final bool addDivider;
  final String confirmActionTitle;
  final String cancelActionTitle;
  final List<Widget>? actions;

  final void Function()? confirmActionOnPressed;
  final void Function()? cancelActionOnPressed;

  const _SheetFooter({
    Key? key,
    required this.addDivider,
    required this.confirmActionTitle,
    required this.cancelActionTitle,
    this.actions,
    this.confirmActionOnPressed,
    this.cancelActionOnPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: addDivider,
          child: const Divider(indent: 24, endIndent: 24),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions ??
                [
                  FilledButton(
                    onPressed: confirmActionOnPressed,
                    child: Text(confirmActionTitle),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      if (cancelActionOnPressed == null) {
                        Navigator.pop(context);
                      } else {
                        cancelActionOnPressed!();
                      }
                    },
                    child: Text(cancelActionTitle),
                  ),
                ],
          ),
        ),
      ],
    );
  }
}
