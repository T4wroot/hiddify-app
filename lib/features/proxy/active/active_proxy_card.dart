import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/utils/country_helper.dart';
import 'package:roozaneh/features/connection/model/connection_status.dart';
import 'package:roozaneh/features/connection/notifier/connection_notifier.dart';
import 'package:roozaneh/features/proxy/active/active_proxy_notifier.dart';
import 'package:roozaneh/features/proxy/active/ip_widget.dart';
import 'package:roozaneh/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:roozaneh/utils/custom_loggers.dart';

class ActiveProxyFooter extends ConsumerWidget with InfraLogger {
  const ActiveProxyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(
      connectionNotifierProvider.select((value) => value.valueOrNull ?? const Disconnected()),
    );

    final activeProxy = ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isConnected = connectionState == const Connected() && activeProxy != null;

    final countryCode = detectCountryCode(activeProxy?.tagDisplay ?? "", activeProxy?.ipinfo.countryCode);
    final countryInfo = kCountryNames[countryCode];
    final String countryName;
    if (countryInfo != null) {
      countryName = countryInfo.$1;
    } else if (activeProxy != null && (activeProxy.tagDisplay.toLowerCase().contains("lowest") || activeProxy.tagDisplay.toLowerCase().contains("balance") || activeProxy.tagDisplay == "select")) {
      countryName = "اتصال هوشمند (بهترین سرور)";
    } else if (activeProxy != null && activeProxy.tagDisplay.isNotEmpty) {
      countryName = activeProxy.tagDisplay;
    } else {
      countryName = "اتصال هوشمند (سریع‌ترین سرور)";
    }

    final hasPing = activeProxy != null && activeProxy.urlTestDelay > 0 && ConnectionConst.isValidDelay(activeProxy.urlTestDelay);
    final delayText = hasPing ? "${activeProxy.urlTestDelay} ms" : "---";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Label + Country Selection Dropdown Pill
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 6),
              child: Text(
                "اتصال از طریق",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isConnected ? const Color(0xFFFF7A3C) : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.goNamed('proxies'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFED7AA),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IPCountryFlag(
                      countryCode: countryCode,
                      organization: activeProxy?.ipinfo.org ?? "",
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        countryName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Smart Route Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFFFF7A3C).withValues(alpha: 0.12)
                : const Color(0xFFFFF8F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF7A3C).withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A3C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: Color(0xFFFF7A3C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "مسیر هوشمند",
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: Color(0xFFFF7A3C),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "بهترین و سریع‌ترین مسیر برای شما",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Latency & Stability Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.signal_cellular_alt_rounded,
                    size: 16,
                    color: Color(0xFFFF7A3C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    delayText,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                height: 16,
                width: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Row(
                children: [
                  Text(
                    "پایدار",
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? const Color(0xFF22C55E) : const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
