import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConfigFragment extends StatefulWidget {
  const ConfigFragment({super.key});

  @override
  State<ConfigFragment> createState() => _ConfigFragmentState();
}

class _ConfigFragmentState extends State<ConfigFragment> {
  _modifyMixedPort(num mixedPort) async {
    final port = await globalState.showCommonDialog(
      child: MixedPortFormDialog(
        mixedPort: mixedPort,
      ),
    );
    if (port != null && port != mixedPort && mounted) {
      try {
        final mixedPort = int.parse(port);
        if (mixedPort < 1024 || mixedPort > 49151) throw "Invalid port";
        globalState.appController.clashConfig.mixedPort = mixedPort;
      } catch (e) {
        globalState.showMessage(
          title: appLocalizations.proxyPort,
          message: TextSpan(
            text: e.toString(),
          ),
        );
      }
    }
  }

  _showLogLevelDialog(LogLevel value) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(appLocalizations.logLevel),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 16,
        ),
        content: SizedBox(
          width: 250,
          child: Wrap(
            children: [
              for (final logLevel in LogLevel.values)
                ListItem.radio(
                  delegate: RadioDelegate<LogLevel>(
                    value: logLevel,
                    groupValue: value,
                    onChanged: (LogLevel? value) {
                      if (value == null) {
                        return;
                      }
                      final appController = globalState.appController;
                      appController.clashConfig.logLevel = value;
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(logLevel.name),
                )
            ],
          ),
        ),
      ),
    );
  }

  _showUaDialog(String? value) {
    const uas = [
      null,
      "clash-verge/v1.6.6",
      "ClashforWindows/0.19.23",
    ];
    globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text("UA"),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 16,
        ),
        content: SizedBox(
          width: 250,
          child: Wrap(
            children: [
              for (final ua in uas)
                ListItem.radio(
                  delegate: RadioDelegate<String?>(
                    value: ua,
                    groupValue: value,
                    onChanged: (String? value) {
                      final appController = globalState.appController;
                      appController.clashConfig.globalRealUa = value;
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(ua ?? appLocalizations.defaultText),
                )
            ],
          ),
        ),
      ),
    );
  }

  _modifyTestUrl(String testUrl) async {
    final newTestUrl = await globalState.showCommonDialog<String>(
      child: TestUrlFormDialog(
        testUrl: testUrl,
      ),
    );
    if (newTestUrl != null && newTestUrl != testUrl && mounted) {
      try {
        if (!newTestUrl.isUrl) {
          throw "Invalid url";
        }
        globalState.appController.config.testUrl = newTestUrl;
      } catch (e) {
        globalState.showMessage(
          title: appLocalizations.testUrl,
          message: TextSpan(
            text: e.toString(),
          ),
        );
      }
    }
  }

  _updateKeepAliveInterval(int keepAliveInterval) async {
    final newKeepAliveIntervalString =
        await globalState.showCommonDialog<String>(
      child: KeepAliveIntervalFormDialog(
        keepAliveInterval: keepAliveInterval,
      ),
    );
    if (newKeepAliveIntervalString != null &&
        newKeepAliveIntervalString != "$keepAliveInterval" &&
        mounted) {
      try {
        final newKeepAliveInterval = int.parse(newKeepAliveIntervalString);
        if (newKeepAliveInterval <= 0) {
          throw "Invalid keepAliveInterval";
        }
        globalState.appController.clashConfig.keepAliveInterval =
            newKeepAliveInterval;
        globalState.appController.updateClashConfigDebounce();
      } catch (e) {
        globalState.showMessage(
          title: appLocalizations.testUrl,
          message: TextSpan(
            text: e.toString(),
          ),
        );
      }
    }
  }

  List<Widget> _buildAppSection() {
    return generateSection(
      title: appLocalizations.app,
      items: [
        if (Platform.isAndroid) ...[
          Selector<Config, bool>(
            selector: (_, config) => config.vpnProps.allowBypass,
            builder: (_, allowBypass, __) {
              return ListItem.switchItem(
                leading: const Icon(Icons.arrow_forward_outlined),
                title: Text(appLocalizations.allowBypass),
                subtitle: Text(appLocalizations.allowBypassDesc),
                delegate: SwitchDelegate(
                  value: allowBypass,
                  onChanged: (bool value) async {
                    final config = globalState.appController.config;
                    final vpnProps = config.vpnProps;
                    config.vpnProps = vpnProps.copyWith(
                      allowBypass: value,
                    );
                  },
                ),
              );
            },
          ),
          Selector<Config, bool>(
            selector: (_, config) => config.vpnProps.systemProxy,
            builder: (_, systemProxy, __) {
              return ListItem.switchItem(
                leading: const Icon(Icons.settings_ethernet),
                title: Text(appLocalizations.systemProxy),
                subtitle: Text(appLocalizations.systemProxyDesc),
                delegate: SwitchDelegate(
                  value: systemProxy,
                  onChanged: (bool value) async {
                    final config = globalState.appController.config;
                    final vpnProps = config.vpnProps;
                    config.vpnProps = vpnProps.copyWith(
                      systemProxy: value,
                    );
                  },
                ),
              );
            },
          ),
        ],
        Selector<Config, bool>(
          selector: (_, config) => config.isCloseConnections,
          builder: (_, isCloseConnections, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.auto_delete_outlined),
              title: Text(appLocalizations.autoCloseConnections),
              subtitle: Text(appLocalizations.autoCloseConnectionsDesc),
              delegate: SwitchDelegate(
                value: isCloseConnections,
                onChanged: (bool value) async {
                  final appController = globalState.appController;
                  appController.config.isCloseConnections = value;
                },
              ),
            );
          },
        ),
        Selector<Config, bool>(
          selector: (_, config) => config.onlyProxy,
          builder: (_, onlyProxy, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.data_usage_outlined),
              title: Text(appLocalizations.onlyStatisticsProxy),
              subtitle: Text(appLocalizations.onlyStatisticsProxyDesc),
              delegate: SwitchDelegate(
                value: onlyProxy,
                onChanged: (bool value) async {
                  final appController = globalState.appController;
                  appController.config.onlyProxy = value;
                },
              ),
            );
          },
        ),
        // Selector<Config, bool>(
        //   selector: (_, config) => config.isCompatible,
        //   builder: (_, isCompatible, __) {
        //     return ListItem.switchItem(
        //       leading: const Icon(Icons.expand_outlined),
        //       title: Text(appLocalizations.compatible),
        //       subtitle: Text(appLocalizations.compatibleDesc),
        //       delegate: SwitchDelegate(
        //         value: isCompatible,
        //         onChanged: (bool value) async {
        //           final appController = globalState.appController;
        //           appController.config.isCompatible = value;
        //           await appController.applyProfile();
        //         },
        //       ),
        //     );
        //   },
        // ),
      ],
    );
  }

  List<Widget> _buildGeneralSection() {
    return generateSection(
      title: appLocalizations.general,
      items: [
        Selector<ClashConfig, LogLevel>(
          selector: (_, clashConfig) => clashConfig.logLevel,
          builder: (_, value, __) {
            return ListItem(
              leading: const Icon(Icons.info_outline),
              title: Text(appLocalizations.logLevel),
              subtitle: Text(value.name),
              onTap: () {
                _showLogLevelDialog(value);
              },
            );
          },
        ),
        Selector<ClashConfig, String?>(
          selector: (_, clashConfig) => clashConfig.globalRealUa,
          builder: (_, value, __) {
            return ListItem(
              leading: const Icon(Icons.computer_outlined),
              title: const Text("UA"),
              subtitle: Text(value ?? appLocalizations.defaultText),
              onTap: () {
                _showUaDialog(value);
              },
            );
          },
        ),
        Selector<ClashConfig, int>(
          selector: (_, config) => config.keepAliveInterval,
          builder: (_, value, __) {
            return ListItem(
              leading: const Icon(Icons.timer_outlined),
              title: Text(appLocalizations.keepAliveIntervalDesc),
              subtitle: Text("$value ${appLocalizations.seconds}"),
              onTap: () {
                _updateKeepAliveInterval(value);
              },
            );
          },
        ),
        Selector<Config, String>(
          selector: (_, config) => config.testUrl,
          builder: (_, value, __) {
            return ListItem(
              leading: const Icon(Icons.timeline),
              title: Text(appLocalizations.testUrl),
              subtitle: Text(value),
              onTap: () {
                _modifyTestUrl(value);
              },
            );
          },
        ),
        Selector<ClashConfig, int>(
          selector: (_, clashConfig) => clashConfig.mixedPort,
          builder: (_, mixedPort, __) {
            return ListItem(
              onTap: () {
                _modifyMixedPort(mixedPort);
              },
              leading: const Icon(Icons.adjust_outlined),
              title: Text(appLocalizations.proxyPort),
              subtitle: Text(appLocalizations.proxyPortDesc),
              trailing: FilledButton.tonal(
                onPressed: () {
                  _modifyMixedPort(mixedPort);
                },
                child: Text(
                  "$mixedPort",
                ),
              ),
            );
          },
        ),
        Selector<ClashConfig, bool>(
          selector: (_, clashConfig) => clashConfig.ipv6,
          builder: (_, ipv6, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.water_outlined),
              title: const Text("IPv6"),
              subtitle: Text(appLocalizations.ipv6Desc),
              delegate: SwitchDelegate(
                value: ipv6,
                onChanged: (bool value) async {
                  final appController = globalState.appController;
                  appController.clashConfig.ipv6 = value;
                },
              ),
            );
          },
        ),
        Selector<ClashConfig, bool>(
          selector: (_, clashConfig) => clashConfig.allowLan,
          builder: (_, allowLan, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.device_hub),
              title: Text(appLocalizations.allowLan),
              subtitle: Text(appLocalizations.allowLanDesc),
              delegate: SwitchDelegate(
                value: allowLan,
                onChanged: (bool value) async {
                  final clashConfig = context.read<ClashConfig>();
                  clashConfig.allowLan = value;
                },
              ),
            );
          },
        ),
        Selector<ClashConfig, bool>(
          selector: (_, clashConfig) => clashConfig.unifiedDelay,
          builder: (_, unifiedDelay, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.compress_outlined),
              title: Text(appLocalizations.unifiedDelay),
              subtitle: Text(appLocalizations.unifiedDelayDesc),
              delegate: SwitchDelegate(
                value: unifiedDelay,
                onChanged: (bool value) async {
                  final appController = globalState.appController;
                  appController.clashConfig.unifiedDelay = value;
                },
              ),
            );
          },
        ),
        Selector<ClashConfig, bool>(
          selector: (_, clashConfig) =>
              clashConfig.findProcessMode == FindProcessMode.always,
          builder: (_, findProcess, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.polymer_outlined),
              title: Text(appLocalizations.findProcessMode),
              subtitle: Text(appLocalizations.findProcessModeDesc),
              delegate: SwitchDelegate(
                value: findProcess,
                onChanged: (bool value) async {
                  final appController = globalState.appController;
                  appController.clashConfig.findProcessMode =
                      value ? FindProcessMode.always : FindProcessMode.off;
                },
              ),
            );
          },
        ),
        Selector<ClashConfig, bool>(
          selector: (_, clashConfig) => clashConfig.tcpConcurrent,
          builder: (_, tcpConcurrent, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.double_arrow_outlined),
              title: Text(appLocalizations.tcpConcurrent),
              subtitle: Text(appLocalizations.tcpConcurrentDesc),
              delegate: SwitchDelegate(
                value: tcpConcurrent,
                onChanged: (bool value) async {
                  final appController = globalState.appController;
                  appController.clashConfig.tcpConcurrent = value;
                },
              ),
            );
          },
        ),
        Selector<ClashConfig, bool>(
          selector: (_, clashConfig) =>
              clashConfig.geodataLoader == geodataLoaderMemconservative,
          builder: (_, memconservative, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.memory),
              title: Text(appLocalizations.geodataLoader),
              subtitle: Text(appLocalizations.geodataLoaderDesc),
              delegate: SwitchDelegate(
                value: memconservative,
                onChanged: (bool value) async {
                  final appController = globalState.appController;
                  appController.clashConfig.geodataLoader = value
                      ? geodataLoaderMemconservative
                      : geodataLoaderStandard;
                },
              ),
            );
          },
        ),
        Selector<ClashConfig, bool>(
          selector: (_, clashConfig) =>
              clashConfig.externalController.isNotEmpty,
          builder: (_, hasExternalController, __) {
            return ListItem.switchItem(
              leading: const Icon(Icons.api_outlined),
              title: Text(appLocalizations.externalController),
              subtitle: Text(appLocalizations.externalControllerDesc),
              delegate: SwitchDelegate(
                value: hasExternalController,
                onChanged: (bool value) async {
                  final appController = globalState.appController;
                  appController.clashConfig.externalController =
                      value ? defaultExternalController : '';
                },
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildMoreSection() {
    return generateSection(
      title: appLocalizations.more,
      items: [
        if (system.isDesktop)
          Selector<ClashConfig, bool>(
            selector: (_, clashConfig) => clashConfig.tun.enable,
            builder: (_, tunEnable, __) {
              return ListItem.switchItem(
                leading: const Icon(Icons.important_devices_outlined),
                title: Text(appLocalizations.tun),
                subtitle: Text(appLocalizations.tunDesc),
                delegate: SwitchDelegate(
                  value: tunEnable,
                  onChanged: (bool value) async {
                    final clashConfig = context.read<ClashConfig>();
                    clashConfig.tun = Tun(enable: value);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [
      ..._buildAppSection(),
      ..._buildGeneralSection(),
      ..._buildMoreSection(),
    ];
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemBuilder: (_, index) {
        return Container(
          alignment: Alignment.center,
          child: items[index],
        );
      },
      itemCount: items.length,
    );
  }
}

class MixedPortFormDialog extends StatefulWidget {
  final num mixedPort;

  const MixedPortFormDialog({super.key, required this.mixedPort});

  @override
  State<MixedPortFormDialog> createState() => _MixedPortFormDialogState();
}

class _MixedPortFormDialogState extends State<MixedPortFormDialog> {
  late TextEditingController portController;

  @override
  void initState() {
    super.initState();
    portController = TextEditingController(text: "${widget.mixedPort}");
  }

  _handleUpdate() async {
    final port = portController.value.text;
    if (port.isEmpty) return;
    Navigator.of(context).pop<String>(port);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(appLocalizations.proxyPort),
      content: SizedBox(
        width: 300,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextField(
              controller: portController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _handleUpdate,
          child: Text(appLocalizations.submit),
        )
      ],
    );
  }
}

class TestUrlFormDialog extends StatefulWidget {
  final String testUrl;

  const TestUrlFormDialog({
    super.key,
    required this.testUrl,
  });

  @override
  State<TestUrlFormDialog> createState() => _TestUrlFormDialogState();
}

class _TestUrlFormDialogState extends State<TestUrlFormDialog> {
  late TextEditingController testUrlController;

  @override
  void initState() {
    super.initState();
    testUrlController = TextEditingController(text: widget.testUrl);
  }

  _handleUpdate() async {
    final testUrl = testUrlController.value.text;
    if (testUrl.isEmpty) return;
    Navigator.of(context).pop<String>(testUrl);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(appLocalizations.testUrl),
      content: SizedBox(
        width: 300,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextField(
              maxLines: 5,
              minLines: 1,
              controller: testUrlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _handleUpdate,
          child: Text(appLocalizations.submit),
        )
      ],
    );
  }
}

class KeepAliveIntervalFormDialog extends StatefulWidget {
  final int keepAliveInterval;

  const KeepAliveIntervalFormDialog({
    super.key,
    required this.keepAliveInterval,
  });

  @override
  State<KeepAliveIntervalFormDialog> createState() =>
      _KeepAliveIntervalFormDialogState();
}

class _KeepAliveIntervalFormDialogState
    extends State<KeepAliveIntervalFormDialog> {
  late TextEditingController keepAliveIntervalController;

  @override
  void initState() {
    super.initState();
    keepAliveIntervalController = TextEditingController(
      text: "${widget.keepAliveInterval}",
    );
  }

  _handleUpdate() async {
    final keepAliveInterval = keepAliveIntervalController.value.text;
    if (keepAliveInterval.isEmpty) return;
    Navigator.of(context).pop<String>(keepAliveInterval);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(appLocalizations.keepAliveIntervalDesc),
      content: SizedBox(
        width: 300,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextField(
              maxLines: 1,
              minLines: 1,
              controller: keepAliveIntervalController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixText: appLocalizations.seconds,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _handleUpdate,
          child: Text(appLocalizations.submit),
        )
      ],
    );
  }
}
