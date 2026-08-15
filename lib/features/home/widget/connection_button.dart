import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:roozaneh/core/router/dialog/dialog_notifier.dart';
import 'package:roozaneh/features/connection/model/connection_status.dart';
import 'package:roozaneh/features/connection/notifier/connection_notifier.dart';
import 'package:roozaneh/features/profile/notifier/active_profile_notifier.dart';
import 'package:roozaneh/features/profile/notifier/profile_notifier.dart';
import 'package:roozaneh/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:roozaneh/gen/assets.gen.dart';

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;

    final isConnecting = connectionStatus.isLoading || connectionStatus.valueOrNull is Connecting;
    final isDisconnecting = connectionStatus.valueOrNull is Disconnecting;
    final isConnected = connectionStatus.valueOrNull == const Connected();

    return _ConnectionButton(
      isConnecting: isConnecting,
      isDisconnecting: isDisconnecting,
      isConnected: isConnected,
      enabled: !isConnecting && !isDisconnecting,
      onTap: () async {
        if (isConnecting || isDisconnecting) return;

        if (isConnected) {
          if (requiresReconnect == true &&
              await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            final activeProfile = await ref.read(activeProfileProvider.future);
            return await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
          }
          return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        } else {
          if (ref.read(activeProfileProvider).valueOrNull == null) {
            await ref.read(addProfileNotifierProvider.notifier).addClipboard("https://xui.irn.one:2096/sub/34xjqji5cyqxe7jf?name=روزنه");
          }
          if (await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
          }
        }
      },
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.isConnecting,
    required this.isDisconnecting,
    required this.isConnected,
  });

  final VoidCallback onTap;
  final bool enabled;
  final bool isConnecting;
  final bool isDisconnecting;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Central Status Circle (Pulsing/Spinner during connecting, Checkmark when connected, Sun when disconnected)
        Semantics(
          button: true,
          enabled: enabled,
          label: isConnecting
              ? "در حال اتصال"
              : isConnected
                  ? "متصل است"
                  : "متصل نیست",
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Container(
                width: 125,
                height: 125,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 28,
                      spreadRadius: isConnecting ? 6 : 3,
                      color: isConnected
                          ? const Color(0xFF22C55E).withValues(alpha: 0.32)
                          : const Color(0xFFFF7A3C).withValues(alpha: isConnecting ? 0.45 : 0.28),
                    ),
                  ],
                ),
              ),

              // Connecting Progress Ring
              if (isConnecting || isDisconnecting)
                const SizedBox(
                  width: 125,
                  height: 125,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A3C)),
                  ),
                ),

              // Core Circle Material Button
              Container(
                width: 112,
                height: 112,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
                ),
                child: Material(
                  key: const ValueKey("home_connection_button"),
                  shape: const CircleBorder(),
                  color: Colors.transparent,
                  child: InkWell(
                    focusColor: Colors.grey.withValues(alpha: 0.2),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: isConnected
                          ? const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF22C55E),
                              size: 60,
                            )
                          : Assets.images.sunIcon.svg(
                              colorFilter: ColorFilter.mode(
                                isConnecting ? const Color(0xFFFF9E66) : const Color(0xFFFF7A3C),
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Gap(14),

        // 2. Status Title & Subtitle
        if (isConnecting) ...[
          Text(
            "روزنه در حال اتصال...",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color(0xFFFF7A3C),
            ),
          ),
          const Gap(4),
          Text(
            "در حال برقراری ارتباط امن و انتخاب سرور...",
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ] else if (isDisconnecting) ...[
          Text(
            "در حال قطع اتصال...",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Gap(4),
          Text(
            "لطفاً چند لحظه صبر کنید",
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ] else if (isConnected) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "روزنه ",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const TextSpan(
                  text: "متصل است",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
          const Gap(4),
          Text(
            "اتصال شما امن و پایدار است",
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ] else ...[
          Text(
            "روزنه متصل نیست",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Gap(4),
          Text(
            "برای اتصال ضربه بزنید",
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],

        const Gap(16),

        // 3. Primary CTA Action Button
        ElevatedButton(
          onPressed: (isConnecting || isDisconnecting) ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isConnected
                ? const Color(0xFFDC2626)
                : const Color(0xFFFF7A3C),
            disabledBackgroundColor: const Color(0xFFFF7A3C).withValues(alpha: 0.7),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            minimumSize: const Size(260, 52),
            elevation: (isConnecting || isDisconnecting) ? 0 : 4,
            shadowColor: const Color(0xFFFF7A3C).withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: (isConnecting || isDisconnecting)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const Gap(10),
                    Text(
                      isConnecting ? "در حال اتصال..." : "در حال قطع...",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                )
              : Text(
                  isConnected ? "قطع اتصال" : "اتصال",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      ],
    );
  }
}
