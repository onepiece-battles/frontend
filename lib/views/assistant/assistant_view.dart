import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../ai/assistant_api.dart';
import '../../ai/assistant_action_card.dart';
import '../../ai/assistant_message.dart';
import '../../ai/assistant_session.dart';
import '../../ai/assistant_scroll_controller.dart';
import '../../ai/rich_message.dart';
import '../../ai/speech_input.dart';
import '../../constants/onepiece_colors.dart';
import '../../repository/battle_dao.dart';
import 'widgets/assistant_composer.dart';

/// The post-login landing: an AI control room. The user asks in natural
/// language (typed, spoken, or via a preset) and the assistant answers using
/// the app's own data, with inline links that jump to each resource. The
/// DeepSeek key lives on the server; only the NIKA super-admin can set it.
class AssistantView extends StatefulWidget {
  const AssistantView({super.key});

  @override
  State<AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<AssistantView> {
  final GetIt _getIt = GetIt.instance;
  final TextEditingController _input = TextEditingController();
  late final AssistantScrollController _scroll =
      AssistantScrollController(_session);
  bool _scrollQueued = false;
  bool _userScrolling = false;
  final SpeechInput _speech = SpeechInput();

  bool _listening = false;
  bool _loadingHistory = true;
  bool _configured =
      true; // assume ok until told otherwise (non-admins can't check)
  bool _creatingBattle = false;
  OverlayEntry? _copyToast;

  late final AssistantSession _session = _getIt<AssistantSession>();
  List<AiChatMessage> get _messages => _session.messages;
  Set<AiChatMessage> get _handledProposals => _session.handledProposals;
  bool get _busy => _session.busy;

  AssistantApi get _api => _getIt<AssistantApi>();

  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';

  bool get _isAdmin {
    try {
      return _getIt<User>().loginRole == UserRole.NIKA;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    _bootstrap();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
    if (_session.followLatest) _scheduleScrollToEnd();
  }

  Future<void> _bootstrap() async {
    // Load persisted history only once per app session; on later entries the
    // messages are already in the session singleton. The model's own context
    // (including earlier lookups) is replayed by the server.
    if (!_session.loaded) {
      try {
        final history = await _api.listMessages();
        final knownResources = history
            .expand((m) => m.resources)
            .map((r) => ResourceRef(r.type, r.id, r.name))
            .toList();
        _messages.addAll(history.map((m) {
          final resources = m.resources
              .map((r) => ResourceRef(r.type, r.id, r.name))
              .toList();
          return AiChatMessage(
            m.role,
            m.role == 'assistant'
                ? normalizeResourceLinks(m.content, knownResources)
                : m.content,
            resources: resources,
            actionProposals: m.actionProposals,
          );
        }));
      } catch (_) {
        // History is best-effort; an empty start is fine.
      }
      _session.loaded = true;
    }
    if (_isAdmin) {
      try {
        final setting = await _api.getSetting();
        if (mounted) setState(() => _configured = setting.configured);
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _loadingHistory = false);
      if (_session.followLatest) _scheduleScrollToEnd();
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _copyToast?.remove();
    _copyToast?.dispose();
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

  /// Explicitly sending a message resumes following the newest reply.
  void _scrollToEnd() {
    _userScrolling = false;
    _session.followLatest = true;
    _scheduleScrollToEnd();
  }

  void _scheduleScrollToEnd() {
    if (_scrollQueued || !mounted) return;
    _scrollQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollQueued = false;
      if (mounted && _session.followLatest && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if ((notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle)) {
      _userScrolling = true;
      _session.followLatest = false;
    }
    if (notification is ScrollEndNotification && _userScrolling) {
      _userScrolling = false;
      _session.followLatest = notification.metrics.extentAfter <= 8;
      if (_session.followLatest) _scheduleScrollToEnd();
    }
    return false;
  }

  /// Asks the server-side assistant and streams its answer into a pending
  /// bubble. The server stores both the question and the answer.
  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    // Read the locale now: the view may be gone before the answer finishes.
    final zh = _zh;
    var reply = AiChatMessage('assistant', '', pending: true);
    _messages
      ..add(AiChatMessage('user', text))
      ..add(reply);
    _session.busy = true;
    _session.changed();
    _scrollToEnd();

    // All state lives in the session, which notifies whichever view is
    // showing it, so the answer keeps arriving if the user opens a resource.
    void show(AiChatMessage next) {
      final index = _messages.indexOf(reply);
      if (index < 0) return; // the thread was cleared meanwhile
      _messages[index] = next;
      reply = next;
      _session.changed();
    }

    var answer = '';
    var ended = false;
    try {
      await for (final event
          in _api.ask(text, language: zh ? 'zh_CN' : 'en_US')) {
        switch (event) {
          case AssistantStatus(:final label):
            // A tool is about to run: text streamed so far was a preamble.
            answer = '';
            show(AiChatMessage('assistant', '', pending: true, status: label));
          case AssistantDelta(text: final fragment):
            answer += fragment;
            show(AiChatMessage('assistant', answer, pending: true));
          case AssistantDone done:
            ended = true;
            final updated = _session.applyActionUpdates(done.actionProposals);
            show(AiChatMessage(
              'assistant',
              done.content,
              resources: done.resources
                  .map((r) => ResourceRef(r.type, r.id, r.name))
                  .toList(),
              battleProposal: done.battleProposal,
              actionProposals: done.actionProposals
                  .where((p) => !updated.contains(p.code))
                  .toList(),
            ));
          case AssistantFailure(:final code, :final message):
            ended = true;
            if (code == AssistantFailure.notConfigured) {
              _messages.remove(reply);
              _session.changed();
              _showNotConfigured(zh);
            } else {
              show(AiChatMessage('assistant', '⚠️ $message'));
            }
        }
      }
      if (!ended) {
        show(AiChatMessage(
            'assistant',
            zh
                ? '⚠️ 连接中断了，请重试'
                : '⚠️ The connection dropped. Please try again.'));
      }
    } catch (e) {
      show(AiChatMessage('assistant', '⚠️ $e'));
    } finally {
      _session.busy = false;
      _session.changed();
    }
  }

  void _showNotConfigured(bool zh) {
    if (!mounted) return;
    setState(() => _configured = false);
    if (_isAdmin) {
      _promptForKey();
    } else {
      _snack(zh
          ? 'AI 助手尚未配置，请联系管理员'
          : 'The assistant is not set up yet — please contact an admin');
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
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
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
    final keyController = TextEditingController();
    final modelController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_zh ? '配置 DeepSeek API Key' : 'Set DeepSeek API key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText:
                    _zh ? 'sk-…（留空则保留现有密钥）' : 'sk-… (blank keeps current)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'deepseek-chat',
              ),
            ),
          ],
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
    if (saved == true) {
      try {
        await _api.setSetting(
          apiKey: keyController.text.trim(),
          model: modelController.text.trim().isEmpty
              ? null
              : modelController.text.trim(),
        );
        final setting = await _api.getSetting();
        if (mounted) {
          setState(() => _configured = setting.configured);
          _snack(_zh ? '已保存' : 'Saved');
        }
      } catch (e) {
        if (mounted) _snack(_zh ? '保存失败：$e' : 'Could not save: $e');
      }
    }
  }

  void _openResource(String type, String id, String name) {
    switch (type) {
      case 'character':
        context.goNamed('characterDetails',
            extra: id, pathParameters: {'name': name});
        break;
      case 'fruit':
        context
            .goNamed('fruitDetails', extra: id, pathParameters: {'name': name});
        break;
      case 'battle':
        context.goNamed('battleDetails', extra: id, pathParameters: {'id': id});
        break;
      case 'group':
        context
            .goNamed('groupDetails', extra: id, pathParameters: {'name': name});
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
          if (_isAdmin && !_configured) _keyBanner(),
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : (_messages.isEmpty ? _emptyState() : _messageList()),
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
        if (_isAdmin)
          IconButton(
            tooltip: _zh ? 'API Key' : 'API key',
            onPressed: _promptForKey,
            icon: const Icon(Icons.key_outlined,
                size: 20, color: OnepieceColors.secondaryLabel),
          ),
        if (_messages.isNotEmpty)
          IconButton(
            tooltip: _zh ? '清空' : 'Clear',
            onPressed: _busy ? null : _clear,
            icon: const Icon(Icons.delete_outline,
                size: 20, color: OnepieceColors.secondaryLabel),
          ),
      ]),
    );
  }

  Future<void> _clear() async {
    _session.reset();
    try {
      await _api.clearMessages();
    } catch (_) {}
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
            Text(_zh ? '问我任何关于这个世界的问题' : 'Ask me anything about this world',
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
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView.builder(
        key: const ValueKey('assistant_messages'),
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        itemCount: _messages.length,
        itemBuilder: (context, i) => _bubble(_messages[i]),
      ),
    );
  }

  Widget _bubble(AiChatMessage m) {
    final isUser = m.role == 'user';
    final text =
        isUser ? _session.displayCommand(m.text, zh: _zh) : m.displayText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (m.pending || text.trim().isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? OnepieceColors.fancyBlue
                      : OnepieceColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                // Streamed text renders as it arrives; dots only until the first fragment.
                child: m.pending && m.text.isEmpty
                    ? _pendingIndicator(m.status)
                    : (isUser
                        ? SelectableText(
                            text,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: Colors.white),
                          )
                        : RichMessage(
                            data: text,
                            onResource: _openResource,
                          )),
              ),
            ),
          if (!m.pending && m.text.trim().isNotEmpty) _copyButton(m, isUser),
          for (final proposal in m.actionProposals)
            AssistantActionCard(
              key: ValueKey(proposal.code),
              proposal: proposal,
              busy: _busy || _creatingBattle,
              onConfirm: () =>
                  _send('${_zh ? '确认' : 'confirm'} ${proposal.code}'),
              onCancel: () =>
                  _send('${_zh ? '取消' : 'cancel'} ${proposal.code}'),
              onResource: _openResource,
            ),
          if (m.battleProposal != null &&
              m.actionProposals.isEmpty &&
              !_handledProposals.contains(m))
            _proposalCard(m),
        ],
      ),
    );
  }

  /// Typing dots, plus what the assistant is looking up while a tool runs.
  Widget _pendingIndicator(String? status) {
    if (status == null || status.isEmpty) return const _TypingDots();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const _TypingDots(),
      const SizedBox(width: 8),
      Flexible(
        child: Text(status,
            style: const TextStyle(
                fontSize: 12, color: OnepieceColors.secondaryLabel)),
      ),
    ]);
  }

  Widget _copyButton(AiChatMessage m, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: InkWell(
        onTap: () => _copy(m),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.copy_rounded,
                size: 13, color: OnepieceColors.secondaryLabel),
            const SizedBox(width: 3),
            Text(_zh ? '复制' : 'Copy',
                style: const TextStyle(
                    fontSize: 11, color: OnepieceColors.secondaryLabel)),
          ]),
        ),
      ),
    );
  }

  void _copy(AiChatMessage m) {
    final text = m.role == 'user' ? m.text : _plainText(m.text);
    Clipboard.setData(ClipboardData(text: text));
    _copyToast?.remove();
    _copyToast?.dispose();
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Material(
              color: OnepieceColors.primaryLabel,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(_zh ? '已复制' : 'Copied',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ),
        ),
      ),
    );
    _copyToast = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
    Future.delayed(const Duration(seconds: 1), () {
      if (_copyToast != entry) return;
      entry.remove();
      entry.dispose();
      _copyToast = null;
    });
  }

  /// Strip the Markdown/link syntax so the clipboard gets clean prose.
  static String _plainText(String markdown) {
    var s = markdown;
    s = s.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\((?:[^)]+)\)'), (m) => m.group(1)!);
    s = s.replaceAll(RegExp(r'onepiece://[A-Za-z_]+/[^\s)\]]+'), '');
    s = s.replaceAll('**', '');
    s = s.replaceAll(RegExp(r'^#{1,3}\s+', multiLine: true), '');
    return s.trim();
  }

  Widget _proposalCard(AiChatMessage m) {
    final p = m.battleProposal!;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OnepieceColors.separator),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: OnepieceColors.surface,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.sports_martial_arts_rounded,
                size: 16, color: OnepieceColors.fancyBlue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_zh ? '创建战斗' : 'Create battle',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(p.label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: OnepieceColors.primaryLabel)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _creatingBattle || _busy
                  ? null
                  : () => setState(() => _handledProposals.add(m)),
              child: Text(_zh ? '取消' : 'Cancel'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: OnepieceColors.fancyBlue,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  _creatingBattle || _busy ? null : () => _confirmBattle(m, p),
              child: _creatingBattle
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_zh ? '确认创建' : 'Create'),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _confirmBattle(AiChatMessage m, BattleProposal p) async {
    if (_busy || _creatingBattle) return;
    setState(() => _creatingBattle = true);
    try {
      final resp = await _getIt<BattleDao>().createBattle(CreateBattleRequest(
        userId: _getIt<User>().id,
        starterId: p.starterId,
        receiverId: p.receiverId,
      ));
      if (!mounted) return;
      setState(() {
        _creatingBattle = false;
        _handledProposals.add(m);
      });
      final battleId = resp?.battleId;
      if (battleId != null) {
        context.goNamed('battleDetails',
            extra: battleId, pathParameters: {'id': battleId});
      } else {
        _snack(_zh ? '创建战斗失败' : 'Could not create the battle');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingBattle = false);
      _snack(_zh ? '创建战斗失败：$e' : 'Could not create the battle: $e');
    }
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

  Widget _composer() => AssistantComposer(
        controller: _input,
        hint: _zh ? '输入指令或问题…' : 'Type a command or question…',
        busy: _busy,
        onSend: _send,
        zh: _zh,
        leading: !_speech.isSupported
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: IconButton.filledTonal(
                  tooltip: _listening
                      ? (_zh ? '停止语音输入' : 'Stop voice input')
                      : (_zh ? '语音输入' : 'Voice input'),
                  onPressed: _busy ? null : _toggleVoice,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                    backgroundColor: OnepieceColors.surface,
                    foregroundColor: _listening
                        ? OnepieceColors.fancyBlue
                        : OnepieceColors.primaryLabel,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none, size: 20),
                ),
              ),
      );
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
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
