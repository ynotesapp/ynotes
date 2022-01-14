import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ynotes/core_new/utilities.dart';
import 'package:ynotes/core_new/utilities.dart';
import 'package:ynotes/core_new/services.dart';
import 'package:ynotes_packages/components.dart';
import 'package:ynotes_packages/settings.dart';

class SettingsSupportPage extends StatefulWidget {
  const SettingsSupportPage({Key? key}) : super(key: key);

  @override
  _SettingsSupportPageState createState() => _SettingsSupportPageState();
}

class _SettingsSupportPageState extends State<SettingsSupportPage> {
  @override
  Widget build(BuildContext context) {
    return YPage(
        appBar: const YAppBar(title: "Assistance"),
        body: ChangeNotifierConsumer<Settings>(
            controller: SettingsService.settings,
            builder: (context, settings, _) => Column(
                  children: [
                    YSettingsSections(sections: [
                      YSettingsSection(tiles: [
                        YSettingsTile.switchTile(
                            title: "Secouer pour signaler",
                            switchValue: settings.global.shakeToReport,
                            onSwitchValueChanged: (bool value) async {
                              settings.global.shakeToReport = value;
                              await SettingsService.update();
                              BugReport.updateShakeFeatureStatus();
                            }),
                        YSettingsTile(
                            title: "Logs",
                            leading: MdiIcons.file,
                            onTap: () => Navigator.pushNamed(context, "/settings/logs")),
                      ]),
                    ])
                  ],
                )));
  }
}
