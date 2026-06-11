import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/web_socket_service.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:openapi/api.dart';
import '../app_router.dart';
import '../constants/onepiece_fonts.dart';

class ChatInputField extends StatefulWidget {
  final WebSocketService webSocketManager;
  final TextEditingController textEditingController;
  final ValueNotifier<Chat?> selectedChatNotifier;
  final int minLines;
  final int maxLines;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final Color sendButtonColor;
  final bool enabled;

  const ChatInputField({
    super.key,
    required this.webSocketManager,
    required this.selectedChatNotifier,
    this.minLines = 1,
    this.maxLines = 5,
    required this.textEditingController,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.textStyle,
    this.sendButtonColor = Colors.blue,
    this.enabled = true,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  late FocusNode _focusNode;
  bool _canSend = false;

  TextEditingController get textEditingController =>
      widget.textEditingController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    textEditingController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = textEditingController.text.trim().isNotEmpty;
    if (hasText != _canSend) {
      setState(() => _canSend = hasText);
    }
  }

  void _handleSend() {
    final SendMessageRequest request = SendMessageRequest(
      content: textEditingController.text,
      userId: getIt<User>().id,
      conversationId: widget.selectedChatNotifier.value!.id!,
      preMessageId: null,
    );
    final String jsonMessage = jsonEncode(request.toJson());
    widget.webSocketManager.sendMessage(jsonMessage);
    textEditingController.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    textEditingController.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Outer safe area & padding is expected from parent screen.
    return Container(
      padding: widget.padding,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              width: 200,
              child: TextField(
                controller: textEditingController,
                focusNode: _focusNode,
                enabled: widget.enabled,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                style: widget.textStyle,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  labelStyle: OnepieceFonts.dropDownItemStyle,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: OnepieceColors.iconGreen, width: 1.5)),
                ),
                onSubmitted: (_) {
                  // onSubmitted typically triggered by "done" key; keep send via button
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: _canSend && widget.enabled ? _handleSend : null,
              style: OnepieceButtonStyle.getDefaultStyle(),
              child: Text(
                AppLocalizations.of(context)!.send,
                style: TextStyle(
                  color: _canSend ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
