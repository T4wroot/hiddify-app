import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:roozaneh/core/localization/translations.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/router/adaptive_layout/shell_route_action.dart';
import 'package:roozaneh/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:roozaneh/core/router/go_router/routing_config_notifier.dart';
import 'package:roozaneh/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
            : Row(
                children: [
                  FocusScope(
                    node: navScopeNode,
                    child: NavigationRail(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      indicatorColor: const Color(0xFFFF7A3C).withValues(alpha: 0.15),
                      selectedIconTheme: const IconThemeData(color: Color(0xFFFF7A3C)),
                      selectedLabelTextStyle: const TextStyle(color: Color(0xFFFF7A3C), fontWeight: FontWeight.bold),
                      unselectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      unselectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      extended: Breakpoint(context).isDesktop(),
                      destinations: _navRailDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                      selectedIndex: _getSelectedIndex(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex),
                      trailing: Breakpoint(context).isDesktop()
                          ? Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFF7A3C), size: 24),
                                          const SizedBox(width: 8),
                                          Text(
                                            "روزنه",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "v 4.1.2 dev",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(child: navigationShell),
                ],
              ),
        bottomNavigationBar: isMobileBreakpoint
            ? FocusScope(
                node: navScopeNode,
                child: NavigationBar(
                  selectedIndex: _getSelectedIndex(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex),
                  destinations: _navDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                  onDestinationSelected: (index) => _onTap(context, index, isMobileBreakpoint, showProfilesAction),
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
  void _onTap(BuildContext context, int actionIndex, bool isMobileBreakpoint, bool showProfilesAction) {
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
  List<NavigationRailDestination> _navRailDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationRailDestination(icon: Icon(e.icon), label: Text(e.title))).toList();
}
