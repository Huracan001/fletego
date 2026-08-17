import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../application/notifications_controller.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (state.unread > 0)
            TextButton(
              onPressed: () => ref
                  .read(notificationsControllerProvider.notifier)
                  .markAllRead(),
              child: const Text('Marcar todas'),
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).refresh(),
          child: state.isLoading
              ? const FletegoLoadingState()
              : state.error != null && state.items.isEmpty
              ? FletegoErrorState(
                  message: state.error!,
                  onRetry: () => ref
                      .read(notificationsControllerProvider.notifier)
                      .refresh(),
                )
              : state.items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    FletegoEmptyState(
                      title: 'Sin notificaciones',
                      message:
                          'Te avisaremos de mensajes, ofertas y cambios de viaje.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(FletegoSpacing.lg),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: FletegoSpacing.sm),
                  itemBuilder: (context, index) {
                    final n = state.items[index];
                    return FletegoCard(
                      onTap: () async {
                        if (n.isUnread) {
                          await ref
                              .read(notificationsControllerProvider.notifier)
                              .markRead(n.id);
                        }
                        if (!context.mounted) return;
                        final tripId = n.tripId;
                        if (tripId != null && n.type == 'chat_message') {
                          context.push(
                            AppRoutes.tripChat,
                            extra: {'tripId': tripId},
                          );
                        } else if (tripId != null) {
                          context.push(AppRoutes.tripDetail, extra: tripId);
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (n.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: const BoxDecoration(
                                color: FletegoColors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style:
                                      FletegoTypography.textTheme.titleSmall,
                                ),
                                if (n.body != null && n.body!.isNotEmpty)
                                  Text(
                                    n.body!,
                                    style:
                                        FletegoTypography.textTheme.bodyMedium,
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  _fmt(n.createdAt),
                                  style:
                                      FletegoTypography.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}
