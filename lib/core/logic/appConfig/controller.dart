import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ynotes/core/apis/model.dart';
import 'package:ynotes/core/apis/utils.dart';
import 'package:ynotes/core/logic/agenda/controller.dart';
import 'package:ynotes/core/logic/grades/controller.dart';
import 'package:ynotes/core/logic/homework/controller.dart';
import 'package:ynotes/core/logic/shared/loginController.dart';
import 'package:ynotes/core/offline/offline.dart';
import 'package:ynotes/core/services/background.dart';
import 'package:ynotes/core/utils/settingsUtils.dart';
import 'package:ynotes/core/utils/themeUtils.dart';
import 'package:ynotes/ui/themes/themesList.dart';

///Top level application sytem class
class ApplicationSystem extends ChangeNotifier {
  Map? settings;

  AppAccount? account;
  SchoolAccount? currentSchoolAccount;

  ///A boolean representing the use of the application
  bool? isFirstUse;

  ///The color theme used in the application
  ThemeData? theme;

  String? themeName;

  ///The chosen API
  API? api;

  ///The chosen API
  late Offline offline;

  ///App logger
  late Logger logger;

  ///All the app controllers

  late LoginController loginController;
  late GradesController gradesController;
  late HomeworkController homeworkController;
  late AgendaController agendaController;
  exitApp() async {
    try {
      await this.offline.clearAll();
      //Delete sharedPref
      SharedPreferences preferences = await (SharedPreferences.getInstance() as Future<SharedPreferences>);
      await preferences.clear();
      //delte local setings and init them
      this.settings!.clear();
      this._initSettings();
      //Import secureStorage
      final storage = new FlutterSecureStorage();
      //Delete all
      await storage.deleteAll();
      this.updateTheme("clair");
    } catch (e) {
      print(e);
    }
  }

  ///The most important function
  ///It will intialize Offline, APIs and background fetch
  initApp() async {
    logger = Logger();
    //set settings
    await _initSettings();
    //Set theme to default
    updateTheme(settings!["user"]["global"]["theme"]);
    //Set offline
    await _initOffline();
    //Set api
    this.api = APIManager(this.offline);
    if (api != null) {
      account = await api!.account();
    }
    //Set background fetch
    await _initBackgroundFetch();
    //Set controllers
    loginController = LoginController();
    gradesController = GradesController(this.api);
    homeworkController = HomeworkController(this.api);
    agendaController = AgendaController(this.api);
  }

  initControllers() async {
    await this.gradesController.refresh(force: true);
    await this.homeworkController.refresh(force: true);
  }

  updateSetting(Map path, String key, var value) {
    path[key] = value;
    SettingsUtils.setSetting(settings);
    notifyListeners();
  }

//Leave app
  updateTheme(String themeName) {
    print("Updating theme to " + themeName);
    theme = appThemes[themeName];
    this.themeName = themeName;
    updateSetting(this.settings!["user"]["global"], "theme", themeName);
    SystemChrome.setSystemUIOverlayStyle(
        ThemeUtils.isThemeDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    notifyListeners();
  }

  _initBackgroundFetch() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await BackgroundFetch.configure(
          BackgroundFetchConfig(
              minimumFetchInterval: 15,
              stopOnTerminate: false,
              startOnBoot: true,
              enableHeadless: true,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresStorageNotLow: false,
              requiresDeviceIdle: false,
              requiredNetworkType: NetworkType.ANY), (taskId) async {
        await BackgroundService.backgroundFetchHeadlessTask(taskId);
        BackgroundFetch.finish(taskId);
      });
    }
  }

  _initOffline() async {
    //Initiate an unlocked offline controller
    offline = Offline(false);
    await offline.init();
  }

  _initSettings() async {
    settings = await SettingsUtils.getSettings();
    //Set theme to default
    updateTheme(settings!["user"]["global"]["theme"]);
    notifyListeners();
  }
}

class Test {
  Map? settings;
  Test() {
    settings = SettingsUtils.getAppSettings();
  }
}
