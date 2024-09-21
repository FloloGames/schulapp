import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:schulapp/app.dart';
import 'package:schulapp/code_behind/grading_system_manager.dart';
import 'package:schulapp/code_behind/holidays.dart';
import 'package:schulapp/code_behind/holidays_manager.dart';
import 'package:schulapp/code_behind/save_manager.dart';
import 'package:schulapp/code_behind/school_semester.dart';
import 'package:schulapp/code_behind/settings.dart';
import 'package:schulapp/code_behind/timetable.dart';
import 'package:schulapp/code_behind/timetable_manager.dart';
import 'package:schulapp/code_behind/todo_event.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/code_behind/version_manager.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';
import 'package:schulapp/screens/all_timetables_screen.dart';
import 'package:schulapp/screens/grades_screen.dart';
import 'package:schulapp/screens/hello_screen.dart';
import 'package:schulapp/screens/holidays_screen.dart';
import 'package:schulapp/screens/versions_screen.dart';
import 'package:schulapp/screens/tasks_screen.dart';
import 'package:schulapp/screens/timetable/create_timetable_screen.dart';
import 'package:schulapp/screens/timetable/import_export_timetable_screen.dart';
import 'package:schulapp/screens/vertretungsplan_paul_dessau_screen.dart';
import 'package:schulapp/widgets/timetable/timetable_widget.dart';
import 'package:schulapp/code_behind/timetable_util_functions.dart';
import 'package:schulapp/widgets/navigation_bar_drawer.dart';
import 'package:schulapp/widgets/timetable/timetable_one_day_widget.dart';
import 'package:schulapp/widgets/task/todo_event_list_item_widget.dart';
import 'package:schulapp/code_behind/todo_event_util_functions.dart';

// ignore: must_be_immutable
class TimetableScreen extends StatefulWidget {
  static const String route = "/";

  String title;
  Timetable? timetable;
  bool isHomeScreen;

  TimetableScreen({
    super.key,
    required this.title,
    required this.timetable,
    this.isHomeScreen = false,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  StreamSubscription? _intentSubscription;

  final _verticalPageViewController = PageController();

  Holidays? currentOrNextHolidays;

  int _currPageIndex = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      _postFrameCallback,
    );
    _fetchHolidays();

    _initReceiveSharingIntent();

    super.initState();
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MainApp.changeNavBarVisibilitySecure(
      context,
      value: true,
    );

    bool showSubstitutionplanAction =
        TimetableManager().settings.getVar(Settings.username) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Visibility(
            visible: showSubstitutionplanAction,
            child: IconButton(
              tooltip:
                  AppLocalizationsManager.localizations.strSubstitutionPlan,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const VertretungsplanPaulDessauScreen(),
                  ),
                );

                setState(() {});
              },
              icon: const Icon(Icons.cloud_download),
            ),
          ),
        ],
      ),
      drawer: widget.isHomeScreen
          ? NavigationBarDrawer(selectedRoute: TimetableScreen.route)
          : null,
      floatingActionButton: _floatingActionButton(context),
      body: _body(),
    );
  }

  Widget? _floatingActionButton(BuildContext context) {
    if (_currPageIndex != 0) return null;

    return SpeedDial(
      icon: Icons.more_horiz_outlined,
      activeIcon: Icons.close,
      spacing: 3,
      useRotationAnimation: true,
      tooltip: '',
      animationCurve: Curves.elasticInOut,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.assignment_add),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          label: AppLocalizationsManager.localizations.strCreateATask,
          onTap: () async {
            //selectedSubjectName, isCustomTask
            (String, bool)? selectedSubjectNameTuple =
                await showSelectSubjectNameSheet(
              context,
              title: AppLocalizationsManager
                  .localizations.strSelectSubjectToAddTaskTo,
              allowCustomNames: true,
            );

            if (selectedSubjectNameTuple == null) return;
            if (!context.mounted) return;

            String selectedSubjectName = selectedSubjectNameTuple.$1;
            bool isCustomTask = selectedSubjectNameTuple.$2;

            TodoEvent? event = await createNewTodoEventSheet(
              context,
              linkedSubjectName: selectedSubjectName,
              isCustomEvent: isCustomTask,
            );

            if (event == null) return;

            TimetableManager().addOrChangeTodoEvent(event);

            if (!mounted) return;

            setState(() {});
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.add),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          label: AppLocalizationsManager.localizations.strCreateTimetable,
          onTap: () async {
            await createNewTimetable(context);

            if (!mounted) return;
            //not sure
            setState(() {});
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.edit),
          visible: widget.timetable != null,
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          label: AppLocalizationsManager.localizations.strEdit,
          onTap: () async {
            if (widget.timetable == null) return;

            final ttCopy = widget.timetable!.copy();

            bool? newTtCreated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => CreateTimetableScreen(
                  timetable: widget.timetable!,
                ),
              ),
            );

            newTtCreated ??= false;

            if (!newTtCreated) {
              //reset timetable
              widget.timetable!.setValuesFrom(ttCopy);
            }

            setState(() {});
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.import_export),
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.white,
          label: AppLocalizationsManager.localizations.strImportExport,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ImportExportTimetableScreen(),
              ),
            );
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _body() {
    if (widget.timetable == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () async {
            await createNewTimetable(context);
            if (!mounted) return;
            context.go(TimetableScreen.route);
          },
          child: Text(
            AppLocalizationsManager.localizations.strCreateTimetable,
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    double height =
        MediaQuery.of(context).size.height - AppBar().preferredSize.height;

    if (Utils.isMobileRatio(context)) {
      height -= kBottomNavigationBarHeight;
      height -= 2; //without you could scroll a little bit

      return _timetableBuilder(
        width: width,
        height: height,
        child: TimetableOneDayWidget(
          timetable: widget.timetable!,
          showTodoEvents: widget.isHomeScreen,
        ),
      );
    }

    return _timetableBuilder(
      child: TimetableWidget(
        timetable: widget.timetable!,
        showTodoEvents: widget.isHomeScreen,
      ),
      width: width,
      height: height,
    );
  }

  Widget _timetableBuilder({
    required Widget child,
    required double width,
    required double height,
  }) {
    return PageView(
      scrollDirection: Axis.vertical,
      controller: _verticalPageViewController,
      onPageChanged: (value) {
        _currPageIndex = value;
        setState(() {});
      },
      children: [
        SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.1,
                  widthFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 1],
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context).cardColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                primary: false,
                child: Center(
                  child: child,
                ),
              ),
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: Container(
              //     color: Colors.transparent,
              //     width: width,
              //     height: height / 3,
              //   ),
              // ),
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: InkWell(
              //     onTap: () {
              //       _verticalPageViewController.animateToPage(
              //         1,
              //         duration: const Duration(
              //           milliseconds: 500,
              //         ),
              //         curve: Curves.easeInOutCirc,
              //       );
              //     },
              //     child: Container(
              //       width: width,
              //       height: 30,
              //       decoration: BoxDecoration(
              //         color: Theme.of(context).cardColor,
              //         borderRadius: const BorderRadius.only(
              //           topLeft: Radius.circular(64),
              //           topRight: Radius.circular(64),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        _statsPage(
          width: width,
          height: height,
        ),
      ],
    );
  }

  Widget _statsPage({
    required double width,
    required double height,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      width: width,
      height: height,
      color: Theme.of(context).cardColor,
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            primary: false,
            child: Column(
              children: [
                Text(
                  AppLocalizationsManager.localizations.strStatistics,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                _gradesChartWidget(),
                const SizedBox(
                  height: 8,
                ),
                _nextTaskWidget(),
                _holidaysWidget(),
                // Container(
                //   height: height,
                //   color: Colors.amber,
                // ),
              ],
            ),
          ),
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Container(
          //     color: Colors.transparent,
          //     width: width,
          //     height: height / 3,
          //   ),
          // ),
        ],
      ),
    );
  }

  int _pieChartTouchedIndex = -1;

  Widget _gradesChartWidget() {
    SchoolSemester? semester = Utils.getMainSemester();

    if (semester == null) return Container();

    final sections = _generatePieChartSecions(semester);
    if (sections == null) return Container();

    final width = MediaQuery.of(context).size.width * 0.8;

    return Container(
      width: width,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  //if (!event.isInterestedForInteractions ||
                  if (pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _pieChartTouchedIndex = -1;
                    return;
                  }
                  _pieChartTouchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;

                  setState(() {});
                },
              ),
              borderData: FlBorderData(
                show: false,
              ),
              sectionsSpace: 0,
              sections: sections,
              centerSpaceRadius: 30,
              centerSpaceColor: semester.getColor(),
            ),
          ),
          Center(
            child: InkWell(
              onTap: () {
                context.go(GradesScreen.route);
              },
              child: Text(
                semester.getGradePointsAverageString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData>? _generatePieChartSecions(SchoolSemester semester) {
    const defaultRadius = 40.0;
    const selectedRadius = 60.0;
    List<PieChartSectionData> list = [];
    int numberOfGrades = 0;

    //grade, count
    Map<int, int> grades = {};
    for (final subject in semester.subjects) {
      for (final gradeGroup in subject.gradeGroups) {
        for (final grade in gradeGroup.grades) {
          if (grades[grade.grade] == null) {
            grades[grade.grade] = 1;
          } else {
            grades[grade.grade] = grades[grade.grade]! + 1;
          }
          numberOfGrades++;
        }
      }
    }

    grades = Map.fromEntries(
      grades.entries.toList()
        ..sort(
          (e1, e2) => e1.key.compareTo(e2.key),
        ),
    );

    if (numberOfGrades == 0) return null;

    int index = 0;
    for (int key in grades.keys) {
      String title = GradingSystemManager.convertGradeToSelectedSystem(key);
      bool selected = index == _pieChartTouchedIndex;

      if (selected && grades[key] != null) {
        title = "x ${grades[key]?.toString() ?? key.toString()}";
      }

      list.add(
        PieChartSectionData(
          borderSide: BorderSide(
            width: 0,
            color: Theme.of(context).canvasColor,
          ),
          color: Utils.getGradeColor(key),
          title: title,
          radius: selected ? selectedRadius : defaultRadius,
          value: grades[key]! / numberOfGrades,
        ),
      );
      index++;
    }

    return list;
  }

  Widget _nextTaskWidget() {
    TodoEvent? nextTodoEvent = TimetableManager().sortedTodoEvents.firstOrNull;

    if (nextTodoEvent == null) return Container();

    return TodoEventListItemWidget(
      event: nextTodoEvent,
      onPressed: () {
        nextTodoEvent.finished = !nextTodoEvent.finished;
        //damit es gespeichert wird
        TimetableManager().addOrChangeTodoEvent(nextTodoEvent);
        setState(() {});
      },
      onInfoPressed: () async {
        await Utils.showCustomPopUp(
          context: context,
          heroObject: nextTodoEvent,
          body: TodoEventInfoPopUp(
            event: nextTodoEvent,
            showEditTodoEventSheet: (event) async {
              TodoEvent? newEvent = await createNewTodoEventSheet(
                context,
                linkedSubjectName: event.linkedSubjectName,
                event: event,
              );

              return newEvent;
            },
          ),
          flightShuttleBuilder: (p0, p1, p2, p3, p4) {
            return Container(
              color: Theme.of(context).cardColor,
            );
          },
        );

        //warten damit animation funktioniert
        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        setState(() {});
      },
      onLongPressed: () {},
      onDeleteSwipe: () {},
    );
  }

  Widget _holidaysWidget() {
    if (currentOrNextHolidays == null) {
      return ElevatedButton(
        onPressed: () => HolidaysScreen.selectFederalStateButtonPressed(
          context,
          fetchHolidays: _fetchHolidays,
          setState: () {
            if (mounted) {
              setState(() {});
            }
          },
        ),
        child: Text(
          AppLocalizationsManager.localizations.strSelectFederalState,
        ),
      );
    }
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(
          width: width,
          child: InkWell(
            onTap: () {
              context.go(HolidaysScreen.route);
            },
            child: HolidaysListItemWidget(
              holidays: currentOrNextHolidays!,
              showBackground: false,
              showDateInfo: false,
            ),
          ),
        ),
        const SizedBox(
          height: 32,
        ),
      ],
    );
  }

  Future<void> _fetchHolidays() async {
    String? stateApiCode = TimetableManager().settings.getVar(
          Settings.selectedFederalStateCodeKey,
        );
    stateApiCode ??= "";

    currentOrNextHolidays = await HolidaysManager.getCurrOrNextHolidayForState(
      stateApiCode: stateApiCode,
    );

    setState(() {});
  }

  void _postFrameCallback(Duration _) async {
    final currVersion = await VersionManager().getVersionString();

    if (!mounted) return;

    //only for developers
    if (kDebugMode && !VersionHolder.isVersionSaved(currVersion)) {
      Utils.showInfo(
        context,
        msg:
            "Current version: $currVersion is not safed in version_manager.dart/VersionHolder.versions\npls add it!",
        type: InfoType.error,
        duration: const Duration(seconds: 8),
      );
    }

    final fistTimeOpening = VersionManager().isFirstTimeOpening();

    if (!mounted) return;

    if (fistTimeOpening) {
      context.go(HelloScreen.route);
      return;
    }

    final isNewVersionInstalled =
        await VersionManager().isNewVersionInstalled();

    if (!mounted) return;

    if (isNewVersionInstalled) {
      String? lastUsedVersion = TimetableManager().settings.getVar(
            Settings.lastUsedVersionKey,
          );

      if (lastUsedVersion == null) return;

      Utils.showInfo(
        context,
        msg: AppLocalizationsManager
            .localizations.strYouUpdatedYourAppWantToSeeNewFeatures,
        type: InfoType.info,
        duration: const Duration(seconds: 8),
        actionWidget: SnackBarAction(
          label: AppLocalizationsManager.localizations.strShowNewFeatures,
          onPressed: () async {
            Utils.hideCurrInfo(context);

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VersionsScreen(
                  lastUsedVersion: lastUsedVersion,
                ),
              ),
            );

            VersionManager().updateLastUsedVersion();
          },
        ),
      );
      VersionManager().updateLastUsedVersion();
    }
  }

  void _initReceiveSharingIntent() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    try {
      ReceiveSharingIntent.instance.getInitialMedia().then(_handleFiles);
      _intentSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(
            _handleFiles,
            onError: (error) => debugPrint("getIntentDataStream error: $error"),
          );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _handleFiles(List<SharedMediaFile> files) async {
    //only go to all timetablesscreen when user saves timetable
    bool goToAllTimetables = false;

    for (SharedMediaFile mediaFile in files) {
      final file = File(mediaFile.path);

      if (!file.existsSync()) {
        continue;
      }

      if (mounted) {
        Utils.showInfo(
          context,
          duration: const Duration(seconds: 1),
          msg: AppLocalizationsManager.localizations.strImportingTimetable,
        );
      }

      Timetable? timetable;

      try {
        timetable = SaveManager().importTimetable(file);
      } catch (e) {
        debugPrint(e.toString());
      }

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (mounted) {
        if (timetable == null) {
          Utils.showInfo(
            context,
            msg: AppLocalizationsManager.localizations.strImportingFailed,
            type: InfoType.error,
          );
        } else {
          Utils.showInfo(
            context,
            msg: AppLocalizationsManager.localizations.strImportSuccessful,
            type: InfoType.success,
          );
        }
      }
      if (timetable == null) continue;

      await Future.delayed(
        const Duration(milliseconds: 250),
      );

      if (!mounted) return;

      bool timetableSaved = await Navigator.of(context).push<bool?>(
            MaterialPageRoute(
              builder: (context) =>
                  CreateTimetableScreen(timetable: timetable!),
            ),
          ) ??
          false;

      if (timetableSaved) goToAllTimetables = true;
    }

    if (!goToAllTimetables) return;

    if (mounted) {
      context.go(AllTimetablesScreen.route);
    }
  }
}
