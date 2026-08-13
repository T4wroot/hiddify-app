import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:roozaneh/core/localization/locale_extensions.dart';
import 'package:roozaneh/core/localization/locale_preferences.dart';
import 'package:roozaneh/core/localization/translations.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/router/adaptive_layout/shell_route_action.dart';
import 'package:roozaneh/core/router/dialog/dialog_notifier.dart';
import 'package:roozaneh/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:roozaneh/core/router/go_router/routing_config_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
    required this.showProfilesAction,
  });
  // managed by go router(Shell Route)
  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // focus switch management
    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();
    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = isMobileBreakpoint ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
        } else {
          // focus node does not change => true.
          if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
            if (branchesScope.values.any((node) => node.hasFocus)) {
              navScopeNode.requestFocus();
            } else if (navScopeNode.hasFocus) {
              branchesScope[getNameOfBranch(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex)]
                  ?.requestFocus();
            }
          }
        }
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      return () {
        HardwareKeyboard.instance.removeHandler(handler);
      };
    }, [isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex]);
    return Material(
      child: Scaffold(
        body: isMobileBreakpoint
            ? navigationShell
            : Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    FocusScope(
                      node: navScopeNode,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Container(
                          width: 250,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Column(
                            children: [
                              // Header: Logo on top-right (RTL)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24, top: 12, right: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF7A3C),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF7A3C).withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "روزنه",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Menu Items List
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _actions(t, showProfilesAction, isMobileBreakpoint).length,
                                  itemBuilder: (context, index) {
                                    final action = _actions(t, showProfilesAction, isMobileBreakpoint)[index];
                                    final selectedIndex = _getSelectedIndex(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex);
                                    final isSelected = index == selectedIndex;
                                    final isDark = Theme.of(context).brightness == Brightness.dark;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _onTap(context, ref, index, isMobileBreakpoint, showProfilesAction),
                                          borderRadius: BorderRadius.circular(16),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? (isDark ? const Color(0xFF3D271D) : const Color(0xFFFFF0E6))
                                                  : (isDark
                                                      ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                                      : Colors.white),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFFFFC2A6)
                                                    : (isDark
                                                        ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)
                                                        : const Color(0xFFF0E5DE)),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isSelected
                                                      ? const Color(0xFFFF7A3C).withValues(alpha: 0.15)
                                                      : Colors.black.withValues(alpha: 0.03),
                                                  blurRadius: isSelected ? 12 : 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    action.title,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                      color: isSelected
                                                          ? const Color(0xFFFF7A3C)
                                                          : Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : (isDark
                                                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                                                            : const Color(0xFFF3F4F6)),
                                                  ),
                                                  child: Icon(
                                                    action.icon,
                                                    size: 20,
                                                    color: isSelected
                                                        ? const Color(0xFFFF7A3C)
                                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: navigationShell),
                  ],
                ),
              ),
        bottomNavigationBar: isMobileBreakpoint
            ? FocusScope(
                node: navScopeNode,
                child: NavigationBar(
                  selectedIndex: _getSelectedIndex(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex),
                  destinations: _navDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                  onDestinationSelected: (index) => _onTap(context, ref, index, isMobileBreakpoint, showProfilesAction),
                ),
              )
            : null,
      ),
    );
  }

  int _getSelectedIndex(bool isMobileBreakpoint, bool showProfilesAction, int currentBranchIndex) {
    final currentBranchName = getNameOfBranch(isMobileBreakpoint, showProfilesAction, currentBranchIndex);
    return switch (currentBranchName) {
      'home' => 0,
      'settings' => 1,
      'about' => 3,
      'logs' => 4,
      _ => 0,
    };
  }

  // shell route action onTap
  void _onTap(BuildContext context, WidgetRef ref, int actionIndex, bool isMobileBreakpoint, bool showProfilesAction) async {
    if (actionIndex == 2) {
      // Feedback: Open support link
      final Uri uri = Uri.parse("https://t.me/roozaneh_support");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (actionIndex == 5) {
      // Language: Trigger Hiddify's native language picker modal
      final t = ref.read(translationsProvider).requireValue;
      final locale = ref.read(localePreferencesProvider);
      final selectedLocale = await ref
          .read(dialogNotifierProvider.notifier)
          .showSettingPicker<AppLocale>(
            title: t.pages.settings.general.locale,
            selected: locale,
            onReset: () => ref.read(localePreferencesProvider.notifier).changeLocale(AppLocale.en),
            options: AppLocale.values,
            getTitle: (e) => e.localeName,
          );
      if (selectedLocale != null) {
        await ref.read(localePreferencesProvider.notifier).changeLocale(selectedLocale);
      }
      return;
    }

    final targetBranchName = switch (actionIndex) {
      0 => 'home',
      1 => 'settings',
      3 => 'about',
      4 => 'logs',
      _ => 'home',
    };
    final realBranchIndex = getIndexOfBranch(isMobileBreakpoint, showProfilesAction, targetBranchName);
    if (realBranchIndex >= 0) {
      navigationShell.goBranch(realBranchIndex, initialLocation: realBranchIndex == navigationShell.currentIndex);
    }
  }

  List<ShellRouteAction> _actions(Translations t, bool showProfilesAction, bool isMobileBreakpoint) => [
    ShellRouteAction(Icons.home_rounded, t.pages.home.title),
    ShellRouteAction(Icons.settings_rounded, t.pages.settings.title),
    ShellRouteAction(Icons.chat_bubble_outline_rounded, "بازخورد"),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.info_outline_rounded, t.pages.about.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.bar_chart_rounded, t.pages.logs.title),
    ShellRouteAction(Icons.language_rounded, "زبان"),
  ];

  List<NavigationDestination> _navDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationDestination(icon: Icon(e.icon), label: e.title)).toList();
}
