import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roozaneh/core/localization/translations.dart';
import 'package:roozaneh/core/router/dialog/dialog_notifier.dart';
import 'package:roozaneh/features/connection/model/connection_status.dart';
import 'package:roozaneh/features/connection/notifier/connection_notifier.dart';
import 'package:roozaneh/features/proxy/active/active_proxy_notifier.dart';
import 'package:roozaneh/features/proxy/active/ip_widget.dart';
import 'package:roozaneh/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:roozaneh/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyFooter extends ConsumerWidget with InfraLogger {
  const ActiveProxyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(
      connectionNotifierProvider.select((value) => value.valueOrNull ?? const Disconnected()),
    );

    final activeProxy = ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull));
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isConnected = connectionState == const Connected() && activeProxy != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : const Color(0xFFFED7AA),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? const Color(0xFF22C55E).withValues(alpha: 0.08)
                : const Color(0xFFFF7A3C).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          context.goNamed('proxies');
        },
        child: Row(
          children: [
            // Country Flag or default icon
            if (isConnected)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IPCountryFlag(
                    countryCode: activeProxy.ipinfo.countryCode,
                    organization: activeProxy.ipinfo.org,
                    size: 36,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A3C).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.public_rounded,
                  size: 20,
                  color: Color(0xFFFF7A3C),
                ),
              ),
            const SizedBox(width: 12),
            // Server info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected
                        ? (activeProxy.tagDisplay.isEmpty ? "بهترین سرور خودکار" : activeProxy.tagDisplay)
                        : "بالانسر هوشمند (خودکار)",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isConnected ? const Color(0xFF22C55E) : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConnected
                        ? (activeProxy.urlTestDelay > 0 ? "⚡ ${activeProxy.urlTestDelay} ms" : "متصل شد")
                        : "برای تغییر سرور ضربه بزنید",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A3C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                size: 18,
                color: Color(0xFFFF7A3C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getRealOutboundTag(OutboundInfo group) {
  var tag = group.tagDisplay;
  if (group.groupSelectedTagDisplay != "" && group.groupSelectedTagDisplay != tag) {
    tag = "$tag → ${group.groupSelectedTagDisplay}";
  }
  return tag;
}

// class _StatsColumn extends HookConsumerWidget {
//   const _StatsColumn();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = ref.watch(translationsProvider).requireValue;
//     final stats = ref.watch(statsNotifierProvider).value;

//     return Directionality(
//       textDirection: TextDirection.values[(Directionality.of(context).index + 1) % TextDirection.values.length],
//       child: Flexible(
//         child: Column(
//           children: [
//             _InfoProp(
//               icon: FluentIcons.arrow_bidirectional_up_down_20_regular,
//               text: (stats?.downlinkTotal ?? 0).size(),
//               semanticLabel: t.stats.totalTransferred,
//             ),
//             const Gap(8),
//             _InfoProp(
//               icon: FluentIcons.arrow_download_20_regular,
//               text: (stats?.downlink ?? 0).speed(),
//               semanticLabel: t.stats.speed,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _InfoProp extends StatelessWidget {
//   const _InfoProp({
//     required this.icon,
//     required this.text,
//     this.semanticLabel,
//   });

//   final IconData icon;
//   final String text;
//   final String? semanticLabel;

//   @override
//   Widget build(BuildContext context) {
//     return Semantics(
//       label: semanticLabel,
//       child: Row(
//         children: [
//           Icon(icon),
//           const Gap(8),
//           Flexible(
//             child: Text(
//               text,
//               style: Theme.of(context).textTheme.labelMedium?.copyWith(fontFamily: FontFamily.emoji),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
