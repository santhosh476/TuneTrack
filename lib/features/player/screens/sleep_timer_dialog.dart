import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';

class SleepTimerDialog extends ConsumerWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.read(audioPlayerServiceProvider);
    final currentTimer = audio.sleepTimerTarget;

    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: Text('Sleep Timer', style: AppTypography.headlineSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentTimer != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: AppColors.primaryAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Timer active: stops in ${currentTimer.difference(DateTime.now()).inMinutes + 1}m',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.primaryAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _buildOption(
              context, '15 Minutes', const Duration(minutes: 15), audio),
          _buildOption(
              context, '30 Minutes', const Duration(minutes: 30), audio),
          _buildOption(
              context, '45 Minutes', const Duration(minutes: 45), audio),
          _buildOption(context, '1 Hour', const Duration(hours: 1), audio),
          _buildOption(
              context, 'End of Track', const Duration(minutes: 5), audio),
          if (currentTimer != null)
            ListTile(
              leading: const Icon(Icons.close_rounded, color: AppColors.error),
              title: Text('Turn Off Timer',
                  style:
                      AppTypography.bodyLarge.copyWith(color: AppColors.error)),
              onTap: () {
                audio.cancelSleepTimer();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, String title, Duration duration, dynamic audio) {
    return ListTile(
      title: Text(title, style: AppTypography.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.secondaryText, size: 20),
      onTap: () {
        audio.setSleepTimer(duration);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sleep timer set for $title')),
        );
      },
    );
  }
}
