import 'package:flutter/material.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/router/dialog/dialog_notifier.dart';
import 'package:roozaneh/features/proxy/active/ip_widget.dart';
import 'package:roozaneh/gen/fonts.gen.dart';
import 'package:roozaneh/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:roozaneh/utils/custom_loggers.dart';
import 'package:roozaneh/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(this.proxy, {super.key, required this.selected, required this.onTap});

  final OutboundInfo proxy;
  final bool selected;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Clean display name
    String displayName = proxy.tagDisplay;
    if (displayName.contains("balance") || displayName.contains("round-robin")) {
      displayName = "بالانسر هوشمند (خودکار)";
    } else if (displayName.contains("lowest")) {
      displayName = "کم‌ترین پینگ خودکار";
    }

    final hasValidPing = ConnectionConst.isValidDelay(proxy.urlTestDelay);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? const Color(0xFFF26522).withValues(alpha: 0.18) : const Color(0xFFFFF0E6))
            : (isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? const Color(0xFFF26522)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
          width: selected ? 1.5 : 1.0,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFFF26522).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: IPCountryFlag(
          countryCode: proxy.ipinfo.countryCode,
          organization: proxy.ipinfo.org,
          size: 36,
        ),
        title: Text(
          displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? const Color(0xFFF26522) : theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          proxy.type.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (proxy.urlTestDelay > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: delayColor(context, proxy.urlTestDelay).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: delayColor(context, proxy.urlTestDelay),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      hasValidPing ? "${proxy.urlTestDelay} ms" : "خطا",
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: delayColor(context, proxy.urlTestDelay),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? const Color(0xFFF26522) : theme.colorScheme.outline.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
        selected: selected,
        onTap: onTap,
        onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
      ),
    );
  }

  Color delayColor(BuildContext context, int delay) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (delay) {
        < 800 => Colors.lightGreen,
        < 1500 => Colors.orange,
        _ => Colors.redAccent,
      };
    }
    return switch (delay) {
      < 800 => Colors.green,
      < 1500 => Colors.deepOrangeAccent,
      _ => Colors.red,
    };
  }
}
