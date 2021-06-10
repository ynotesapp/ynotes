import 'dart:async';

import 'package:calendar_time/calendar_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ynotes/core/logic/agenda/addEvent.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/utils/fileUtils.dart';
import 'package:ynotes/core/utils/themeUtils.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/ui/screens/agenda/agendaPage.dart';
import 'package:ynotes/ui/screens/agenda/agendaPageWidgets/agendaGrid.dart';
import 'package:ynotes/ui/screens/agenda/agendaPageWidgets/buttons.dart';

bool extended = false;

Lesson? getCurrentLesson(List<Lesson>? lessons, {DateTime? now}) {
  List<Lesson> dailyLessons = [];
  Lesson? lesson;
  if (lessons != null) {
    dailyLessons = lessons
        .where((lesson) =>
            DateTime.parse(DateFormat("yyyy-MM-dd").format(lesson.start!)) ==
            DateTime.parse(DateFormat("yyyy-MM-dd").format(now ?? DateTime.now())))
        .toList();
    if (dailyLessons.length != 0) {
      //Get current lesson
      try {
        lesson = dailyLessons.firstWhere((lesson) =>
            (now ?? DateTime.now()).isBefore(lesson.end!) && (now ?? DateTime.now()).isAfter(lesson.start!));
      } catch (e) {
        print(lessons);
      }

      return lesson;
    } else {
      return null;
    }
  } else {
    return null;
  }
}

getNextLesson(List<Lesson>? lessons) {
  List<Lesson> dailyLessons = [];
  Lesson? lesson;
  if (lessons != null) {
    dailyLessons = lessons
        .where((lesson) =>
            DateTime.parse(DateFormat("yyyy-MM-dd").format(lesson.start!)) ==
            DateTime.parse(DateFormat("yyyy-MM-dd").format(DateTime.now())))
        .toList();
    if (dailyLessons.length != 0) {
      //Get current lesson
      try {
        dailyLessons.sort((a, b) => a.start!.compareTo(b.start!));
        lesson = dailyLessons.firstWhere((lesson) => DateTime.now().isBefore(lesson.start!));
      } catch (e) {
        print(e.toString());
      }

      return lesson;
    } else {
      return null;
    }
  } else {
    return null;
  }
}

class Agenda extends StatefulWidget {
  @override
  _AgendaState createState() => _AgendaState();
}

class _AgendaState extends State<Agenda> {
  List<FileInfo>? listFiles;
  List<String> items = ["1", "2", "3", "4", "5", "6", "7", "8"];

  //Force get date
  @override
  Widget build(BuildContext context) {
    MediaQueryData screenSize = MediaQuery.of(context);
    return Container(
        height: screenSize.size.height / 10 * 7.5,
        margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.15),
          color: Theme.of(context).primaryColor,
        ),
        width: screenSize.size.width,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.15),
              child: Container(
                width: screenSize.size.width,
                height: screenSize.size.height,
                child: Container(
                  width: screenSize.size.width,
                  height: screenSize.size.height,
                  padding: EdgeInsets.all(screenSize.size.width / 5 * 0.05),
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Column(
                      children: <Widget>[
                        _buildAgendaButtons(context),
                        Container(
                          height: screenSize.size.height / 10 * 8,
                          child: Stack(
                            children: [
                              FutureBuilder<List<AgendaEvent>?>(
                                  future: agendaFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null &&
                                        (snapshot.data ?? []).length != 0) {
                                      return RefreshIndicator(
                                          onRefresh: refreshAgendaFutures,
                                          child: AgendaGrid(
                                            snapshot.data,
                                            initState,
                                          ));
                                    }
                                    if (snapshot.data != null && snapshot.data!.length == 0) {
                                      return Center(
                                        child: FittedBox(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Container(
                                                margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.5),
                                                height: screenSize.size.height / 10 * 1.9,
                                                child: Image(
                                                    fit: BoxFit.fitWidth, image: AssetImage('assets/images/relax.png')),
                                              ),
                                              Text(
                                                "Journée détente ?",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontFamily: "Asap",
                                                    color: ThemeUtils.textColor(),
                                                    fontSize: (screenSize.size.height / 10 * 8.8) / 10 * 0.2),
                                              ),
                                              OutlinedButton(
                                                style: TextButton.styleFrom(
                                                  primary: Colors.black87,
                                                  minimumSize: Size(88, 36),
                                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                                  shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(2.0)),
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  //Reload list
                                                  await refreshAgendaFutures(force: true);
                                                },
                                                child: snapshot.connectionState != ConnectionState.waiting
                                                    ? Text("Recharger",
                                                        style: TextStyle(
                                                            fontFamily: "Asap",
                                                            color: ThemeUtils.textColor(),
                                                            fontSize: (screenSize.size.height / 10 * 8.8) / 10 * 0.2))
                                                    : FittedBox(
                                                        child: SpinKitThreeBounce(
                                                            color: Theme.of(context).primaryColorDark,
                                                            size: screenSize.size.width / 5 * 0.4)),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    } else {
                                      return SpinKitFadingFour(
                                        color: Theme.of(context).primaryColorDark,
                                        size: screenSize.size.width / 5 * 1,
                                      );
                                    }
                                  }),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin:
                    EdgeInsets.only(right: screenSize.size.width / 5 * 0.1, bottom: screenSize.size.height / 10 * 0.7),
                child: _buildFloatingButton(context),
              ),
            ),
          ],
        ));
  }

  getLessons(DateTime? date) async {
    await refreshAgendaFutures(force: false);
  }

  @override
  void initState() {
    super.initState();
    if (agendaDate == null) {
      setState(() {
        agendaDate = CalendarTime().startOfToday;
      });
    }

    getLessons(agendaDate);
  }

  Future<void> refreshAgendaFuture() async {
    if (mounted) {
      setState(() {
        spaceAgendaFuture = appSys.api!.getEvents(agendaDate!, true);
        agendaFuture = appSys.api!.getEvents(agendaDate!, false);
      });
    }
    await spaceAgendaFuture;
    await agendaFuture;
  }

  Future<void> refreshAgendaFutures({bool force = true}) async {
    if (mounted) {
      setState(() {
        spaceAgendaFuture = appSys.api!.getEvents(agendaDate!, true, forceReload: force);
        agendaFuture = appSys.api!.getEvents(agendaDate!, false, forceReload: false);
      });
    }
    await agendaFuture;
    await spaceAgendaFuture;
  }

  _buildAgendaButtons(BuildContext context) {
    return AgendaButtons(
      getLessons: getLessons,
    );
  }

  _buildFloatingButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: "btn1",
      backgroundColor: Colors.transparent,
      child: Container(
        width: 90,
        height: 90,
        child: FittedBox(
          child: Center(
            child: Icon(
              Icons.add,
              size: 80,
            ),
          ),
        ),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xff100A30)),
      ),
      onPressed: () async {
        await addEvent(context);
        await refreshAgendaFutures(force: false);
        setState(() {});
      },
    );
  }
}
