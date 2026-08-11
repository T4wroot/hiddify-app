import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:roozaneh/features/connection/model/connection_status.dart';
import 'package:roozaneh/features/connection/notifier/connection_notifier.dart';
import 'package:roozaneh/features/stats/notifier/stats_notifier.dart';
import 'package:roozaneh/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:roozaneh/utils/number_formatters.dart';

class LiveSpeedGauge extends HookConsumerWidget {
  const LiveSpeedGauge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(
      connectionNotifierProvider.select((value) => value.valueOrNull ?? const Disconnected()),
    );

    if (connectionState != const Connected()) {
      return const SizedBox.shrink();
    }

    final stats = ref.watch(statsNotifierProvider).asData?.value ?? SystemInfo.create();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA).withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Download Speed
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "دانلود",
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    stats.downlink.toInt().speed(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            height: 24,
            width: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          // Upload Speed
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF26522).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 16,
                  color: Color(0xFFF26522),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "آپلود",
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    stats.uplink.toInt().speed(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF26522),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
