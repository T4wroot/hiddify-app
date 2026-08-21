import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/utils/country_helper.dart';
import 'package:roozaneh/features/connection/model/connection_status.dart';
import 'package:roozaneh/features/connection/notifier/connection_notifier.dart';
import 'package:roozaneh/features/proxy/active/active_proxy_notifier.dart';
import 'package:roozaneh/features/proxy/active/ip_widget.dart';
import 'package:roozaneh/features/stats/notifier/stats_notifier.dart';
import 'package:roozaneh/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:roozaneh/utils/custom_loggers.dart';
import 'package:roozaneh/utils/number_formatters.dart';

class ActiveProxyFooter extends ConsumerWidget with InfraLogger {
  const ActiveProxyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(
      connectionNotifierProvider.select((value) => value.valueOrNull ?? const Disconnected()),
    );

    final activeProxy = ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull));
    final stats = ref.watch(statsNotifierProvider).asData?.value ?? SystemInfo.create();
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 6),
          child: Text(
            "موقعیت سرور",
            style: theme.textTheme.labelMedium?.copyWith(
              color: isConnected ? const Color(0xFFFF7A3C) : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? theme.colorScheme.outline.withValues(alpha: 0.15)
                  : const Color(0xFFFED7AA).withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Server Selector Tile
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(20),
                    bottom: Radius.circular(isConnected ? 0 : 20),
                  ),
                  onTap: () => context.goNamed('proxies'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        IPCountryFlag(
                          countryCode: countryCode,
                          organization: activeProxy?.ipinfo.org ?? "",
                          size: 34,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                countryName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                isConnected && activeProxy.ipinfo.ip.isNotEmpty
                                    ? activeProxy.ipinfo.ip
                                    : "تغییر و انتخاب سرور",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Integrated Live Stats Strip (Ping, Upload, Download) when connected
              if (isConnected) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? theme.colorScheme.outline.withValues(alpha: 0.12)
                      : theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Ping
                      Expanded(
                        child: _StatMetric(
                          label: "پینگ",
                          value: delayText,
                          valueColor: hasPing ? const Color(0xFF22C55E) : null,
                          icon: Icons.speed_rounded,
                          iconColor: const Color(0xFF3B82F6),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                      // Upload
                      Expanded(
                        child: _StatMetric(
                          label: "آپلود",
                          value: stats.uplink.toInt().speed(),
                          valueColor: const Color(0xFFFF7A3C),
                          icon: Icons.arrow_upward_rounded,
                          iconColor: const Color(0xFFFF7A3C),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                      // Download
                      Expanded(
                        child: _StatMetric(
                          label: "دانلود",
                          value: stats.downlink.toInt().speed(),
                          valueColor: const Color(0xFF22C55E),
                          icon: Icons.arrow_downward_rounded,
                          iconColor: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatMetric extends StatelessWidget {
  const _StatMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const Gap(4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const Gap(2),
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
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
