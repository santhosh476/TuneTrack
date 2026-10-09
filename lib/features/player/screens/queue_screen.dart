import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/network_or_asset_image.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerServiceProvider);
    final queueAsync = ref.watch(playerQueueStreamProvider);
    final queue = queueAsync.value ?? audio.queue;
    final currentIndex = audio.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Playback Queue', style: AppTypography.titleLarge),
        actions: [
          if (queue.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(audioPlayerServiceProvider).clearQueue();
                Navigator.of(context).pop();
              },
              child: Text(
                'Clear',
                style:
                    AppTypography.labelLarge.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: queue.isEmpty
          ? Center(
              child: Text(
                'Queue is empty',
                style: AppTypography.bodyLarge
                    .copyWith(color: AppColors.secondaryText),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: queue.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(audioPlayerServiceProvider)
                    .reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final track = queue[index];
                final isCurrent = index == currentIndex;

                return Container(
                  key: ValueKey('queue_item_${track.id}_$index'),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primaryAccent.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primaryAccent
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.volume_up_rounded,
                                color: AppColors.primaryAccent, size: 20),
                          ),
                        NetworkOrAssetImage(
                          imageUrl: track.artworkUrl,
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    title: Text(
                      track.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isCurrent
                            ? AppColors.primaryAccent
                            : AppColors.primaryText,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artistName,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.secondaryText),
                          onPressed: () {
                            ref
                                .read(audioPlayerServiceProvider)
                                .removeQueueItem(index);
                          },
                        ),
                        const Icon(Icons.drag_handle_rounded,
                            color: AppColors.secondaryText),
                      ],
                    ),
                    onTap: () {
                      ref
                          .read(audioPlayerServiceProvider)
                          .playTrackAtIndex(index);
                    },
                  ),
                );
              },
            ),
    );
  }
}
