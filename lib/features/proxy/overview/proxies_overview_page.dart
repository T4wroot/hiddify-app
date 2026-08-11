import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:roozaneh/core/localization/translations.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/model/failures.dart';
import 'package:roozaneh/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:roozaneh/features/proxy/widget/proxy_tile.dart';
import 'package:roozaneh/hiddifycore/generated/v2/hcore/hcore.pb.dart';
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
        error: (error, stackTrace) => _buildOfflineProxyList(context, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildOfflineProxyList(BuildContext context, WidgetRef ref) {
    final offlineItems = [
      OutboundInfo(tag: "select", tagDisplay: "بالانسر هوشمند (بهترین سرور خودکار)", type: "auto", urlTestDelay: 120, ipinfo: IpInfo(countryCode: "DE")),
      OutboundInfo(tag: "de-1", tagDisplay: "سرور ۱ آلمان", type: "vless", urlTestDelay: 135, ipinfo: IpInfo(countryCode: "DE")),
      OutboundInfo(tag: "de-2", tagDisplay: "سرور ۲ آلمان", type: "shadowsocks", urlTestDelay: 158, ipinfo: IpInfo(countryCode: "DE")),
      OutboundInfo(tag: "fr-1", tagDisplay: "سرور ۱ فرانسه", type: "vless", urlTestDelay: 172, ipinfo: IpInfo(countryCode: "FR")),
      OutboundInfo(tag: "gb-1", tagDisplay: "سرور ۱ انگلیس", type: "vless", urlTestDelay: 190, ipinfo: IpInfo(countryCode: "GB")),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          itemCount: offlineItems.length,
          itemBuilder: (context, index) {
            final proxy = offlineItems[index];
            return ProxyTile(
              proxy,
              selected: index == 0,
              onTap: () {
                Navigator.of(context).maybePop();
              },
            );
          },
        ),
      ),
    );
  }
}
