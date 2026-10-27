import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ai/ai_config.dart';
import '../../ai/deepseek_service.dart';
import '../../ai/resource_tools.dart';
import '../../ai/speech_input.dart';
import '../../constants/onepiece_colors.dart';

/// The post-login landing: an AI control room. The user asks in natural
/// language (typed, spoken, or via a preset) and the assistant answers using
/// the app's own data, surfacing clickable chips that jump to each resource.
class AssistantView extends StatefulWidget {
  const AssistantView({super.key});

  @override
  State<AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<AssistantView> {
  final DeepSeekAssistant _assistant = DeepSeekAssistant();
  final List<AiChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final SpeechInput _speech = SpeechInput();

  bool _busy = false;
  bool _listening = false;
  bool _hasKey = false;

  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    AiConfig.getKey().then((k) {
      if (mounted) setState(() => _hasKey = k != null);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _speech.stop();
    super.dispose();
  }

  List<String> get _presets => _zh
      ? const [
          '路飞和赤犬谁更强？',
          '谁吃了闪闪果实？',
          '战力最高的角色有哪些？',
          '介绍一下艾斯的战斗记录',
        ]
      : const [
          "Who's stronger, Luffy or Akainu?",
          'Who ate the Glint-Glint Fruit?',
          'Who are the strongest characters?',
          "Tell me about Ace's battles",
        ];

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _messages.add(AiChatMessage('user', text));
      _messages.add(AiChatMessage('assistant', '', pending: true));
      _busy = true;
    });
    _scrollToEnd();
    try {
      final reply = await _assistant.ask(text);
      if (!mounted) return;
      setState(() => _messages[_messages.length - 1] = reply);
    } on AiKeyMissing {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _hasKey = false;
      });
      _promptForKey();
    } on AiError catch (e) {
      if (!mounted) return;
      setState(() => _messages[_messages.length - 1] =
          AiChatMessage('assistant', '⚠️ ${e.message}'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages[_messages.length - 1] =
          AiChatMessage('assistant', '⚠️ $e'));
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  void _toggleVoice() {
    if (_listening) {
      _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_speech.isSupported) {
      _snack(_zh ? '当前浏览器不支持语音识别' : 'Voice input is not supported here');
      return;
    }
    setState(() => _listening = true);
    _speech.start(
      lang: _zh ? 'zh-CN' : 'en-US',
      onResult: (t) {
        _input.text = t;
        _input.selection =
            TextSelection.collapsed(offset: _input.text.length);
      },
      onEnd: () {
        if (mounted) setState(() => _listening = false);
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _promptForKey() async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_zh ? '配置 DeepSeek API Key' : 'Set DeepSeek API key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'sk-...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_zh ? '取消' : 'Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_zh ? '保存' : 'Save')),
        ],
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty) {
      await AiConfig.setKey(controller.text);
      if (mounted) setState(() => _hasKey = true);
    }
  }

  void _openResource(ResourceRef r) {
    switch (r.type) {
      case 'character':
        context.goNamed('characterDetails',
            extra: r.id, pathParameters: {'name': r.name});
        break;
      case 'fruit':
        context.goNamed('fruitDetails',
            extra: r.id, pathParameters: {'name': r.name});
        break;
      case 'battle':
        context.goNamed('battleDetails',
            extra: r.id, pathParameters: {'id': r.id});
        break;
      case 'group':
        context.goNamed('groupDetails',
            extra: r.id, pathParameters: {'name': r.name});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _header(),
          if (!_hasKey) _keyBanner(),
          Expanded(
            child: _messages.isEmpty ? _emptyState() : _messageList(),
          ),
          _presetRow(),
          _composer(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: OnepieceColors.separator, width: 0.5)),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: OnepieceColors.fancyBlue,
              borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_zh ? 'AI 控制室' : 'AI control room',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: OnepieceColors.primaryLabel)),
              Text(
                  _zh
                      ? '用对话查询角色、果实与战斗'
                      : 'Query characters, fruits and battles by chat',
                  style: const TextStyle(
                      fontSize: 11, color: OnepieceColors.secondaryLabel)),
            ],
          ),
        ),
        IconButton(
          tooltip: _zh ? 'API Key' : 'API key',
          onPressed: _promptForKey,
          icon: const Icon(Icons.key_outlined,
              size: 20, color: OnepieceColors.secondaryLabel),
        ),
        if (_messages.isNotEmpty)
          IconButton(
            tooltip: _zh ? '清空' : 'Clear',
            onPressed: () => setState(() => _messages.clear()),
            icon: const Icon(Icons.delete_outline,
                size: 20, color: OnepieceColors.secondaryLabel),
          ),
      ]),
    );
  }

  Widget _keyBanner() {
    return Material(
      color: OnepieceColors.surface,
      child: InkWell(
        onTap: _promptForKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.info_outline,
                size: 18, color: OnepieceColors.fancyBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  _zh
                      ? '尚未配置 DeepSeek API Key，点击设置后即可开始对话'
                      : 'Set your DeepSeek API key to start chatting',
                  style: const TextStyle(
                      fontSize: 13, color: OnepieceColors.primaryLabel)),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: OnepieceColors.secondaryLabel),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome,
                size: 44, color: OnepieceColors.fancyBlue),
            const SizedBox(height: 14),
            Text(
                _zh
                    ? '问我任何关于这个世界的问题'
                    : 'Ask me anything about this world',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel)),
            const SizedBox(height: 6),
            Text(
                _zh
                    ? '例如：谁最强、谁吃了某个果实、某角色的战斗记录'
                    : 'e.g. who is strongest, who ate a fruit, a character’s battles',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: OnepieceColors.secondaryLabel)),
          ],
        ),
      ),
    );
  }

  Widget _messageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(AiChatMessage m) {
    final isUser = m.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isUser ? OnepieceColors.fancyBlue : OnepieceColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: m.pending
                  ? const _TypingDots()
                  : SelectableText(
                      m.text,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: isUser
                              ? Colors.white
                              : OnepieceColors.primaryLabel),
                    ),
            ),
          ),
          if (m.resources.isNotEmpty) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: m.resources.map(_chip).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(ResourceRef r) {
    final icon = switch (r.type) {
      'character' => Icons.person_outline,
      'fruit' => Icons.spa_outlined,
      'battle' => Icons.bolt_outlined,
      'group' => Icons.groups_outlined,
      _ => Icons.link,
    };
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openResource(r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OnepieceColors.separator),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: OnepieceColors.fancyBlue),
            const SizedBox(width: 5),
            Text(r.name.isEmpty ? r.type : r.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: OnepieceColors.fancyBlue)),
            const SizedBox(width: 2),
            const Icon(Icons.north_east,
                size: 11, color: OnepieceColors.secondaryLabel),
          ]),
        ),
      ),
    );
  }

  Widget _presetRow() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final p in _presets)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              child: ActionChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                backgroundColor: OnepieceColors.surface,
                side: BorderSide.none,
                onPressed: _busy ? null : () => _send(p),
              ),
            ),
        ],
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: OnepieceColors.separator, width: 0.5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (_speech.isSupported)
          IconButton(
            onPressed: _busy ? null : _toggleVoice,
            icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                color: _listening
                    ? OnepieceColors.fancyBlue
                    : OnepieceColors.secondaryLabel),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: OnepieceColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                hintText: _zh ? '输入指令或问题…' : 'Type a command or question…',
                hintStyle: const TextStyle(
                    fontSize: 14, color: OnepieceColors.secondaryLabel),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: OnepieceColors.fancyBlue,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _busy ? null : () => _send(_input.text),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++) ...[
            Opacity(
              opacity: 0.3 + 0.7 * (((_c.value * 3 - i) % 3).clamp(0, 1)),
              child: const Icon(Icons.circle,
                  size: 7, color: OnepieceColors.secondaryLabel),
            ),
            if (i < 2) const SizedBox(width: 4),
          ],
        ]);
      },
    );
  }
}
