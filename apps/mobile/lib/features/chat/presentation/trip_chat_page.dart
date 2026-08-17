import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../application/chat_controller.dart';

class TripChatPage extends ConsumerStatefulWidget {
  const TripChatPage({
    super.key,
    required this.tripId,
    this.routeLabel,
  });

  final String tripId;
  final String? routeLabel;

  @override
  ConsumerState<TripChatPage> createState() => _TripChatPageState();
}

class _TripChatPageState extends ConsumerState<TripChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final ok = await ref
        .read(tripChatControllerProvider(widget.tripId).notifier)
        .send(text);
    if (ok) {
      _controller.clear();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripChatControllerProvider(widget.tripId));
    final uid = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeLabel ?? 'Chat del viaje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.tripDetail, extra: widget.tripId);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(tripChatControllerProvider(widget.tripId).notifier)
                    .refresh(),
                child: state.isLoading && state.messages.isEmpty
                    ? const FletegoLoadingState()
                    : state.error != null && state.messages.isEmpty
                    ? FletegoErrorState(
                        message: state.error!,
                        onRetry: () => ref
                            .read(
                              tripChatControllerProvider(
                                widget.tripId,
                              ).notifier,
                            )
                            .refresh(),
                      )
                    : state.messages.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          FletegoEmptyState(
                            title: 'Sin mensajes',
                            message:
                                'Coordina recogida y entrega aquí. Fotos/docs: Phase 9 storage listo.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(FletegoSpacing.md),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final mine = msg.isMine(uid);
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? FletegoColors.primary.withValues(
                                        alpha: 0.12,
                                      )
                                    : FletegoColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: FletegoColors.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.body,
                                    style:
                                        FletegoTypography.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmt(msg.createdAt),
                                    style:
                                        FletegoTypography.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (state.error != null && state.messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  state.error!,
                  style: FletegoTypography.textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isSending ? null : _send,
                    icon: state.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}
