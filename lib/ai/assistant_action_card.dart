import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';
import 'assistant_events.dart';
import 'rich_message.dart';

/// A server-owned action proposal. Buttons submit explicit user commands to
/// the assistant; they never call the resource creation APIs directly.
class AssistantActionCard extends StatefulWidget {
  const AssistantActionCard({
    super.key,
    required this.proposal,
    required this.busy,
    required this.onConfirm,
    required this.onCancel,
    required this.onResource,
  });

  final AiActionProposal proposal;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final void Function(String type, String id, String name) onResource;

  @override
  State<AssistantActionCard> createState() => _AssistantActionCardState();
}

class _AssistantActionCardState extends State<AssistantActionCard> {
  Timer? _expiryTimer;
  bool _expired = false;

  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _watchExpiry();
  }

  @override
  void didUpdateWidget(AssistantActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposal != widget.proposal) _watchExpiry();
  }

  void _watchExpiry() {
    _expiryTimer?.cancel();
    _expired = widget.proposal.expired;
    if (widget.proposal.status != 'pending' || _expired) return;
    _expiryTimer =
        Timer(widget.proposal.expiresAt.difference(DateTime.now()), () {
      if (mounted) setState(() => _expired = true);
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  String _title(AiActionProposal p) {
    if (p.operation == 'create_battle') return _zh ? '创建战斗' : 'Create battle';
    if (p.operation == 'start_battle') return _zh ? '开始战斗' : 'Start battle';
    return p.title;
  }

  String _confirmLabel(AiActionProposal p) {
    if (p.operation.startsWith('create_')) return _zh ? '确认创建' : 'Create';
    if (p.operation == 'start_battle') return _zh ? '确认开始' : 'Start';
    return _zh ? '确认执行' : 'Confirm';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.proposal;
    final expired = _expired || p.expired;
    final pending = p.status == 'pending' && !expired;
    final completed = p.status == 'completed';
    final cancelled = p.status == 'cancelled';
    final status = completed
        ? (p.operation == 'start_battle'
            ? (_zh ? '已提交' : 'Submitted')
            : (_zh ? '已完成' : 'Completed'))
        : cancelled
            ? (_zh ? '已取消' : 'Cancelled')
            : expired
                ? (_zh ? '已过期' : 'Expired')
                : pending
                    ? (_zh ? '待确认' : 'Pending')
                    : (_zh ? '不可用' : 'Unavailable');
    AiResourceLink? target;
    for (final resource in p.resources) {
      if (target == null || resource.type == 'battle') target = resource;
    }
    final result = target;
    // The heading is already shown in the card; retain every field/link below it.
    final lines = p.summary.split('\n');
    final summary = lines.length > 1 ? lines.skip(1).join('\n') : p.summary;
    final help = expired
        ? (_zh ? '提案已过期，请重新提出操作。' : 'This proposal expired. Request a new one.')
        : cancelled
            ? (_zh ? '没有修改数据。' : 'No data was changed.')
            : completed
                ? (p.operation == 'start_battle'
                    ? (_zh
                        ? '已提交战斗，可在详情中查看进度与战报。'
                        : 'Open the battle to follow its progress and report.')
                    : (_zh
                        ? '操作已完成，可以查看资源详情。'
                        : 'The change is complete. Open the resource for details.'))
                : (_zh
                    ? '确认后才会执行，提案 15 分钟内有效。'
                    : 'Nothing changes until you confirm. Valid for 15 minutes.');
    final explanation = pending && p.operation == 'create_battle'
        ? (_zh
            ? '确认后创建待开始的战斗，不会自动开打。15 分钟内有效。'
            : 'Creates a waiting battle without starting it. Valid for 15 minutes.')
        : help;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 560),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OnepieceColors.separator, width: 0.75),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
              completed
                  ? Icons.check_circle_outline_rounded
                  : Icons.task_alt_rounded,
              size: 20,
              color: completed
                  ? OnepieceColors.fancyBlue
                  : OnepieceColors.secondaryLabel),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_title(p),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OnepieceColors.primaryLabel))),
          const SizedBox(width: 8),
          Text(status,
              style: const TextStyle(
                  fontSize: 12, color: OnepieceColors.secondaryLabel)),
        ]),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          RichMessage(data: summary, onResource: widget.onResource),
        ],
        const SizedBox(height: 8),
        Text(explanation,
            style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: OnepieceColors.secondaryLabel)),
        if (pending) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: OutlinedButton(
              onPressed: widget.busy ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  foregroundColor: OnepieceColors.primaryLabel,
                  side: const BorderSide(color: OnepieceColors.separator)),
              child: Text(_zh ? '取消' : 'Cancel'),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: FilledButton(
              onPressed: widget.busy ? null : widget.onConfirm,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  backgroundColor: OnepieceColors.fancyBlue,
                  foregroundColor: Colors.white),
              child: Text(_confirmLabel(p)),
            )),
          ]),
        ] else if (completed && result != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () =>
                widget.onResource(result.type, result.id, result.name),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(result.type == 'battle'
                ? (_zh ? '查看战斗' : 'View battle')
                : (_zh ? '查看详情' : 'View details')),
          ),
        ],
      ]),
    );
  }
}
