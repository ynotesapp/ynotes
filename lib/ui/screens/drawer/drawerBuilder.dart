import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ynotes/core/logic/appConfig/models.dart';
import 'package:ynotes/core/logic/shared/loginController.dart';
import 'package:ynotes/core/services/notifications.dart';
import 'package:ynotes/core/utils/themeUtils.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/ui/screens/agenda/agendaPage.dart';
import 'package:ynotes/ui/screens/cloud/cloudPage.dart';
import 'package:ynotes/ui/screens/downloads/downloadsExplorer.dart';
import 'package:ynotes/ui/screens/grades/gradesPage.dart';
import 'package:ynotes/ui/screens/homework/homeworkPage.dart';
import 'package:ynotes/ui/screens/mail/mailPage.dart';
import 'package:ynotes/ui/screens/polls/pollsPage.dart';
import 'package:ynotes/ui/screens/schoolLife/schoolLifePage.dart';
import 'package:ynotes/ui/screens/settings/sub_pages/accountPage.dart';
import 'package:ynotes/ui/screens/statspage/statspage.dart';
import 'package:ynotes/ui/screens/summary/summaryPage.dart';
import 'package:ynotes/usefulMethods.dart';
import 'drawerBuilderWidgets/drawer.dart';

bool isQuickMenuShown = false;

int _currentIndex = 0;

///Build a bottom tabbar and tabs
class DrawerBuilder extends StatefulWidget {
  DrawerBuilder({Key? key}) : super(key: key);

  State<StatefulWidget> createState() {
    return _DrawerBuilderState();
  }
}

class _DrawerBuilderState extends State<DrawerBuilder> with TickerProviderStateMixin {
  PageController? drawerPageViewController;
  ValueNotifier<int> _notifier = ValueNotifier<int>(0);

  bool isChanging = false;
  bool firstStart = true;
  //Boolean
  late AnimationController quickMenuAnimationController;
  Animation<double>? quickMenuButtonAnimation;

  StreamSubscription? tabBarconnexion;

  GlobalKey<AgendaPageState> agendaPage = new GlobalKey();
  GlobalKey<SummaryPageState> summaryPage = new GlobalKey();
  GlobalKey<HomeworkPageState> homeworkPage = new GlobalKey();
  bool isOffline = false;
  late Animation<double> showLoginControllerStatus;
  late AnimationController showLoginControllerStatusController;
  final Duration drawerAnimationDuration = Duration(milliseconds: 150);
  AnimationController? bodyController;
  Animation<double>? bodyScaleAnimation;
  Animation<Offset>? bodyOffsetAnimation;
  Animation<Offset>? buttonOffsetAnimation;
  Animation<double>? buttonScaleAnimation;
  Animation<double>? fadeAnimation;
  bool isDrawerCollapsed = true;
  int? _previousPage;
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  bool wiredashShown = false;
  @override
  Widget build(BuildContext context) {
    //status bar info
    SystemChrome.setSystemUIOverlayStyle(
        ThemeUtils.isThemeDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    MediaQueryData screenSize;
    screenSize = MediaQuery.of(context);

    double extrasize = 0;
    return WillPopScope(
      onWillPop: () async {
        Future.value(false);
        return false;
      },
      //PAppbar
      child: Scaffold(
          key: _drawerKey,
          resizeToAvoidBottomInset: false,
          drawer: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Theme.of(context).primaryColor, //This will change the drawer background to blue.
              //other styles
            ),
            child: ClipRRect(
              child: Container(
                  width: screenSize.size.width / 5 * 3.6,
                  child: Drawer(
                    child: ValueListenableBuilder(
                        valueListenable: _notifier,
                        builder: (context, dynamic value, child) {
                          return CustomDrawer(
                            entries(),
                            notifier: _notifier,
                            drawerPageViewController: drawerPageViewController,
                          );
                        }),
                  )),
            ),
          ),
          backgroundColor: ThemeUtils.darken(Theme.of(context).backgroundColor, forceAmount: 0.05),
          body: Stack(
            children: <Widget>[
              ClipRRect(
                child: Scaffold(
                  backgroundColor: Theme.of(context).backgroundColor,
                  appBar: PreferredSize(
                    preferredSize: Size.fromHeight(screenSize.size.height / 10 * 0.7),
                    child: ValueListenableBuilder(
                        valueListenable: _notifier,
                        builder: (context, dynamic value, child) {
                          return AppBar(
                              centerTitle: false,
                              systemOverlayStyle:
                                  ThemeUtils.isThemeDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
                              shadowColor: Colors.transparent,
                              backgroundColor: ThemeUtils.isThemeDark
                                  ? Theme.of(context).primaryColorLight
                                  : Theme.of(context).primaryColorDark,
                              title: Text(entries()[value]["menuName"], textAlign: TextAlign.start),
                              actions: [
                                if (entries()[value]["key"] != null)
                                  FlatButton(
                                    color: Colors.transparent,
                                    child: Icon(MdiIcons.wrench,
                                        color: ThemeUtils.isThemeDark ? Colors.white : Colors.black),
                                    onPressed: () {
                                      entries()[value]["key"].currentState.triggerSettings();
                                    },
                                  )
                              ],
                              leading: FlatButton(
                                color: Colors.transparent,
                                child: Icon(MdiIcons.menu, color: ThemeUtils.isThemeDark ? Colors.white : Colors.black),
                                onPressed: () async {
                                  _drawerKey.currentState!.openDrawer(); //
                                },
                              ));
                        }),
                  ),
                  body: PageView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    controller: drawerPageViewController,
                    itemBuilder: (context, index) {
                      return ChangeNotifierProvider<LoginController>.value(
                        value: appSys.loginController,
                        child: Consumer<LoginController>(builder: (context, model, child) {
                          if (model.actualState != loginStatus.loggedIn) {
                            showLoginControllerStatusController.forward();
                          } else {
                            showLoginControllerStatusController.reverse();
                          }
                          return buildPageWithHeader(model, child: entries()[index]["page"]);
                        }),
                      );
                    },
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget buildPageWithHeader(LoginController con, {required Widget child}) {
    MediaQueryData screenSize;
    screenSize = MediaQuery.of(context);
    return AnimatedBuilder(
        animation: showLoginControllerStatus,
        builder: (context, animation) {
          return Container(
            height: screenSize.size.height,
            width: screenSize.size.width,
            child: Column(
              children: [
                Opacity(
                  opacity: 0.8,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(router(AccountPage()));
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 400),
                      color: case2(con.actualState, {
                        loginStatus.loggedIn: Color(0xff4ADE80),
                        loginStatus.loggedOff: Color(0xffA8A29E),
                        loginStatus.error: Color(0xffF87171),
                        loginStatus.offline: Color(0xffFCD34D),
                      }),
                      height: screenSize.size.height / 10 * 0.4 * (1 - showLoginControllerStatus.value),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                            case2(
                              con.actualState,
                              {
                                loginStatus.loggedOff: SpinKitThreeBounce(
                                  size: screenSize.size.width / 5 * 0.3,
                                  color: Color(0xff57534E),
                                ),
                                loginStatus.offline: Icon(
                                  MdiIcons.networkStrengthOff,
                                  size: screenSize.size.width / 5 * 0.3,
                                  color: Color(0xff78716C),
                                ),
                                loginStatus.error: GestureDetector(
                                  onTap: () async {},
                                  child: Icon(
                                    MdiIcons.exclamation,
                                    size: screenSize.size.width / 5 * 0.3,
                                    color: Color(0xff57534E),
                                  ),
                                ),
                                loginStatus.loggedIn: Icon(
                                  MdiIcons.check,
                                  size: screenSize.size.width / 5 * 0.3,
                                  color: Color(0xff57534E),
                                )
                              },
                              SpinKitThreeBounce(
                                size: screenSize.size.width / 5 * 0.4,
                                color: Color(0xff57534E),
                              ),
                            ) as Widget,
                          ])),
                          Text(con.details, style: TextStyle(fontFamily: "Asap", color: Color(0xff57534E))),
                          Text(" Voir l'état du compte.",
                              style:
                                  TextStyle(fontFamily: "Asap", color: Color(0xff57534E), fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: child)
              ],
            ),
          );
        });
  }

  callbackOnShake(BuildContext context) async {}

  @override
  void dispose() {
    _notifier.dispose();
    drawerPageViewController!.dispose();
    super.dispose();
    appSys.offline.dispose();
  }

  ///Apps
  ///`relatedApi` should be set to null if both APIs can use it
  ///-1 is only shown in debug mode
  List<Map> entries() {
    return [
      {
        "menuName": "Résumé",
        "tabName": appTabs.SUMMARY,
        "icon": MdiIcons.home,
        "page": SummaryPage(
          switchPage: _switchPage,
          key: summaryPage,
        ),
        "key": summaryPage
      },
      {"menuName": "Notes", "tabName": appTabs.GRADES, "icon": MdiIcons.trophy, "page": GradesPage()},
      {
        "menuName": "Devoirs",
        "tabName": appTabs.HOMEWORK,
        "icon": MdiIcons.calendarCheck,
        "page": HomeworkPage(
          key: homeworkPage,
          hwController: appSys.homeworkController,
        ),
        "key": homeworkPage
      },
      {
        "menuName": "Agenda",
        "tabName": appTabs.AGENDA,
        "icon": MdiIcons.calendar,
        "page": AgendaPage(key: agendaPage),
        "key": agendaPage,
      },
      {
        "menuName": "Messagerie",
        "icon": MdiIcons.mail,
        "relatedApi": 0,
        "page": MailPage(),
        "tabName": appTabs.MESSAGING,
      },
      {
        "menuName": "Vie scolaire",
        "relatedApi": 0,
        "icon": MdiIcons.stamper,
        "page": SchoolLifePage(),
      },
      {"menuName": "Cloud", "icon": MdiIcons.cloud, "relatedApi": 0, "page": CloudPage(), "tabName": appTabs.CLOUD},
      {
        "menuName": "Sondages",
        "tabName": appTabs.POLLS,
        "icon": MdiIcons.poll,
        "relatedApi": 1,
        "page": PollsAndInfoPage()
      },
      {
        "menuName": "Fichiers",
        "tabName": appTabs.FILES,
        "icon": MdiIcons.file,
        "relatedApi": 0,
        "page": DownloadsExplorer(),
      },
      {
        "menuName": "Statistiques",
        "icon": MdiIcons.chartBar,
        "relatedApi": -1,
        "page": StatsPage(),
      },
    ];
  }

  initControllers() async {
    await appSys.gradesController.refresh();
    await appSys.homeworkController.refresh();

    //Lazy reloads
    await appSys.gradesController.refresh(force: true);
    await appSys.homeworkController.refresh(force: true);
  }

  initPageControllers() {
    // this creates the controller
    drawerPageViewController = PageController(
      initialPage: 0,
    )..addListener(_onPageViewUpdate);
    bodyController = AnimationController(vsync: this, duration: drawerAnimationDuration);

    showLoginControllerStatusController = AnimationController(vsync: this, duration: Duration(milliseconds: 450));
    showLoginControllerStatus = new Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(new CurvedAnimation(
        parent: showLoginControllerStatusController, curve: Interval(0.1, 1.0, curve: Curves.fastOutSlowIn)));
  }

  @override
  void initState() {
    super.initState();
    //Init hw controller
    if (firstStart == true) {
      firstStart = false;
    }

    AppNotification.initNotifications(context, _scrollTo);
    //Mvc init

    initPageControllers();
    //Page sys
    _previousPage = drawerPageViewController?.initialPage;
  }

  _onPageViewUpdate() {
    if (drawerPageViewController != null && drawerPageViewController!.page != null) {
      _notifier.value = drawerPageViewController!.page!.round();
    }
  }

  _scrollTo(int index) {
    // scroll the calculated ammount
    drawerPageViewController!.jumpToPage(index);
  }

  _switchPage(int index) {
    _scrollTo(index);
  }
}
