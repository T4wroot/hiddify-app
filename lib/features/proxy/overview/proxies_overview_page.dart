import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:roozaneh/core/localization/translations.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/model/failures.dart';
import 'package:roozaneh/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:roozaneh/features/proxy/widget/proxy_tile.dart';
import 'package:roozaneh/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final proxies = ref.watch(proxiesOverviewNotifierProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);

    // final selectActiveProxyMutation = useMutation(
    //   initialOnFailure: (error) => CustomToast.error(t.presentShortError(error)).show(context),
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.proxies.title),
        actions: [
          PopupMenuButton<ProxiesSort>(
            initialValue: sortBy,
            onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
            icon: const Icon(FluentIcons.arrow_sort_24_regular),
            tooltip: t.pages.proxies.sort,
            itemBuilder: (context) {
              return [...ProxiesSort.values.map((e) => PopupMenuItem(value: e, child: Text(e.present(t))))];
            },
          ),
          const Gap(8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await ref.read(proxiesOverviewNotifierProvider.notifier).urlTest("select"),
        tooltip: t.pages.proxies.testDelay,
        child: const Icon(FluentIcons.flash_24_filled),
      ),
      body: proxies.when(
        data: (group) {
          if (group == null) return Center(child: Text(t.pages.proxies.empty));
          final validItems = group.items.where((proxy) {
            if (proxy.tagDisplay.contains("ERROR") || proxy.tagDisplay.contains("Unknown parse")) return false;
            if (proxy.urlTestDelay != 0 && !ConnectionConst.isValidDelay(proxy.urlTestDelay)) return false;
            return true;
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: validItems.length,
                itemBuilder: (context, index) {
                  final proxy = validItems[index];
                  return ProxyTile(
                    proxy,
                    selected: group.selected == proxy.tag,
                    onTap: () async {
                      await ref.read(proxiesOverviewNotifierProvider.notifier).changeProxy(group.tag, proxy.tag);
                    },
                  );
                },
              ),
            ),
          );
        },
        error: (error, stackTrace) => Center(child: Text(t.presentShortError(error))),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
