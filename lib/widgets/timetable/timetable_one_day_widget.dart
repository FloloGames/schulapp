import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:schulapp/code_behind/holidays_manager.dart';
import 'package:schulapp/code_behind/school_lesson.dart';
import 'package:schulapp/code_behind/school_time.dart';
import 'package:schulapp/code_behind/settings.dart';
import 'package:schulapp/code_behind/special_lesson.dart';
import 'package:schulapp/code_behind/timetable.dart';
import 'package:schulapp/code_behind/timetable_controller.dart';
import 'package:schulapp/code_behind/timetable_manager.dart';
import 'package:schulapp/code_behind/todo_event.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/extensions.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';
import 'package:schulapp/widgets/strike_through_container.dart';
import 'package:schulapp/widgets/timetable/time_to_next_lesson_widget.dart';
import 'package:schulapp/widgets/timetable/timetable_lesson_widget.dart';

class TimetableOneDayWidget extends StatefulWidget {
  final TimetableController controller;
  final Timetable timetable;
  final bool showTodoEvents;
  final Size? logicalSize;

  const TimetableOneDayWidget({
    super.key,
    required this.timetable,
    required this.showTodoEvents,
    required this.controller,
    this.logicalSize,
  });

  @override
  State<TimetableOneDayWidget> createState() => _TimetableOneDayWidgetState();
}

class _TimetableOneDayWidgetState extends State<TimetableOneDayWidget> {
  static const double minLessonWidth = 100;
  static const double minLessonHeight = 30;
  static const int pagesCount = 1000;
  //monday of curr week
  static const int initialMondayPageIndex = pagesCount ~/ 2;

  late final PageController _pageController;
  late List<SchoolTime> ttSchoolTimes;

  double lessonHeight = minLessonHeight;
  double lessonWidth = minLessonWidth;

  late Color selectedColor;
  late Color unselectedColor;

  late int currWeekIndex;
  late int currYear;

  bool _alreadyShowedErrorBecauseOfReducedHours = false;

  int _showNextWeek = 0;

  double get _breakLightHeight => lessonHeight / 4;

  @override
  void initState() {
    // widget.controller.swipeToRight = () {
    //   _pageController.animateToPage(
    //     _pageController.page!.toInt() + 1,
    //     duration: const Duration(milliseconds: 500),
    //     curve: Curves.easeInOutCirc,
    //   );
    // };

    // widget.controller.swipeToLeft = () {
    //   _pageController.animateToPage(
    //     _pageController.page!.toInt() - 1,
    //     duration: const Duration(milliseconds: 500),
    //     curve: Curves.easeInOutCirc,
    //   );
    // };

    super.initState();

    final currWeekTimetable = widget.timetable.getCurrWeekTimetable();

    if (DateTime.now().weekday == DateTime.sunday) {
      _showNextWeek = currWeekTimetable.schoolDays.length;
    }

    _pageController = PageController(
      initialPage: initialMondayPageIndex +
          Utils.getCurrentWeekDayIndex() +
          _showNextWeek,
    );

    _updateTtSchoolTimes(currWeekTimetable);

    setState(() {});
  }

  void _updateTtSchoolTimes(Timetable timetable) {
    ttSchoolTimes = timetable.schoolTimes;

    final reducedClassHoursEnabled = TimetableManager().settings.getVar<bool>(
          Settings.reducedClassHoursEnabledKey,
        );

    if (!reducedClassHoursEnabled) {
      return;
    }

    final reducedClassHours =
        TimetableManager().settings.getVar<List<SchoolTime>?>(
              Settings.reducedClassHoursKey,
            );

    if (reducedClassHours == null) {
      Future.delayed(
        Duration.zero,
        () {
          if (!mounted || _alreadyShowedErrorBecauseOfReducedHours) return;
          _alreadyShowedErrorBecauseOfReducedHours = true;

          Utils.showInfo(
            context,
            msg: AppLocalizationsManager
                .localizations.strYouDontHaveAnyReducedTimesSetUpYet,
            type: InfoType.error,
          );
        },
      );

      return;
    }

    if (reducedClassHours.length < timetable.schoolTimes.length) {
      Future.delayed(
        Duration.zero,
        () {
          if (!mounted || _alreadyShowedErrorBecauseOfReducedHours) return;
          _alreadyShowedErrorBecauseOfReducedHours = true;

          Utils.showInfo(
            context,
            msg: AppLocalizationsManager
                .localizations.strReducedTimesCannotBeUsed,
            type: InfoType.error,
          );
        },
      );

      return;
    }

    while (reducedClassHours.length > timetable.schoolTimes.length) {
      reducedClassHours.removeLast();
    }

    ttSchoolTimes = reducedClassHours;
  }

  @override
  Widget build(BuildContext context) {
    final currTimetableWeek = widget.timetable;
    double mediaQueryWidth = -1;
    double mediaQueryHeight = -1;

    if (widget.logicalSize == null) {
      mediaQueryWidth = MediaQuery.of(context).size.width;
      mediaQueryHeight = MediaQuery.of(context).size.height;
    } else {
      mediaQueryWidth = widget.logicalSize!.width;
      mediaQueryHeight = widget.logicalSize!.height;
    }

    lessonWidth = mediaQueryWidth * 0.9 / 2;
    if (lessonWidth < minLessonWidth) {
      lessonWidth = minLessonWidth;
    }

    lessonHeight = (mediaQueryHeight - _breakLightHeight) /
        (currTimetableWeek.maxLessonCount + 1);

    if (lessonHeight < minLessonHeight) {
      lessonHeight = minLessonHeight;
    }

    selectedColor = Theme.of(context).colorScheme.secondary.withAlpha(30);

    unselectedColor = Colors.transparent;

    // if (widget.logicalSize != null) {
    //   DateTime currMonday = Utils.getWeekDay(
    //     DateTime.now().copyWith(
    //       hour: 0,
    //       minute: 0,
    //       second: 0,
    //       millisecond: 0,
    //       microsecond: 0,
    //     ),
    //     DateTime.monday,
    //   );

    //   currWeekIndex = Utils.getWeekIndex(currMonday);
    //   currYear = currMonday.year;

    //   //TODO: sollte nie passieren aber man weiß ja nie
    //   return _createDay(
    //     currDay: 0,
    //     currMonday: currMonday,
    //     dayIndex: Utils.getCurrentWeekDayIndex(),
    //     tt: widget.timetable.getWeekTimetableForDateTime(currMonday),
    //   );
    // }

    return SizedBox(
      width: lessonWidth * 2,
      height: lessonHeight * (currTimetableWeek.maxLessonCount + 1) +
          _breakLightHeight -
          0, //durch mögliche rundungsfehler
      child: PageView.builder(
        controller: _pageController,
        itemCount: pagesCount,
        itemBuilder: (context, index) {
          final correctedPageIndex = index - initialMondayPageIndex;
          Timetable tt = widget.timetable;

          int currDayIndex = correctedPageIndex % tt.schoolDays.length;
          int currWeekIndex;

          if (correctedPageIndex < 0) {
            currWeekIndex =
                (correctedPageIndex - currDayIndex) ~/ tt.schoolDays.length;
          } else {
            currWeekIndex = correctedPageIndex ~/ tt.schoolDays.length;
          }

          DateTime currMonday = Utils.getWeekDay(
            DateTime.now().copyWith(
              hour: 0,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            ),
            DateTime.monday,
          );

          currMonday = currMonday.add(
            Duration(days: 7 * currWeekIndex),
          );

          this.currWeekIndex = Utils.getWeekIndex(currMonday);
          currYear = currMonday.year;

          tt = widget.timetable.getWeekTimetableForDateTime(currMonday);

          return _createDay(
            currDay: index,
            dayIndex: currDayIndex,
            currMonday: currMonday,
            tt: tt,
          );
        },
      ),
    );
  }

  Widget _createTimes(bool isCurrDay) {
    List<Widget> timeWidgets = [];

    timeWidgets.add(
      SizedBox(
        key: isCurrDay ? widget.controller.timeLeftKey : null,
        width: lessonWidth,
        height: lessonHeight,
        child: Center(
          child: TimeToNextLessonWidget(
            ttSchoolTimes: ttSchoolTimes,
            onNewLessonCB: () {
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ),
      ),
    );

    for (int lessonIndex = 0;
        lessonIndex < ttSchoolTimes.length;
        lessonIndex++) {
      final schoolTime = ttSchoolTimes[lessonIndex];
      String startString = schoolTime.getStartString();
      String endString = schoolTime.getEndString();

      Color containerColor = unselectedColor;

      bool addBreakWidget = false;

      if (schoolTime.isCurrentlyRunning()) {
        containerColor = selectedColor;
      } else {
        if (lessonIndex + 1 < ttSchoolTimes.length) {
          final nextSchoolTime = ttSchoolTimes[lessonIndex + 1];
          int currTimeInSec = Utils.nowInSeconds();
          int currSchoolTimeEndInSec = schoolTime.end.toSeconds();
          int nextSchoolTimeStartInSec = nextSchoolTime.start.toSeconds();

          addBreakWidget = (currTimeInSec > currSchoolTimeEndInSec &&
              currTimeInSec < nextSchoolTimeStartInSec);
        }
      }

      Widget timeWidget = Container(
        color: containerColor,
        width: lessonWidth,
        height: lessonHeight,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              children: [
                Text(
                  startString,
                  textAlign: TextAlign.center,
                ),
                Text(
                  endString,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      timeWidgets.add(timeWidget);

      if (addBreakWidget) {
        timeWidgets.add(_createBreakHighlight());
      }
    }

    return Column(
      children: timeWidgets,
    );
  }

  Widget _createDay({
    required int currDay,
    required DateTime currMonday,
    required int dayIndex,
    required Timetable tt,
  }) {
    final isCurrDay = currDay ==
        initialMondayPageIndex + Utils.getCurrentWeekDayIndex() + _showNextWeek;
    _updateTtSchoolTimes(tt);
    final day = tt.schoolDays[dayIndex];

    List<Widget> lessonWidgets = [];

    DateTime currLessonDateTime = currMonday.add(Duration(days: dayIndex));

    final customTask = TimetableManager().getCustomTodoEventForDay(
      day: currLessonDateTime,
    );

    final showTaskOnHomescreen = TimetableManager().settings.getVar(
          Settings.showTasksOnHomeScreenKey,
        );

    final List<StrikeThroughContainerController> dayContainerControllers = [];

    lessonWidgets.add(
      InkWell(
        key: dayIndex == Utils.getCurrentWeekDayIndex() && isCurrDay
            ? widget.controller.dayNameKey
            : null,
        onTap: Utils.sameDay(currLessonDateTime, DateTime.now())
            ? null
            : () {
                int currDayIndex = Utils.getCurrentWeekDayIndex();
                int showNextWeek = 0;
                if (DateTime.now().weekday == DateTime.sunday) {
                  showNextWeek = tt.schoolDays.length;
                }
                _pageController.animateToPage(
                  initialMondayPageIndex + currDayIndex + showNextWeek,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCirc,
                );
              },
        onLongPress: () async {
          final value = tt.getSpecialLesson(
            year: currYear,
            weekIndex: currWeekIndex,
            schoolDayIndex: dayIndex,
            schoolTimeIndex: 0,
          ) is CancelledSpecialLesson;

          for (int timeIndex = 0;
              timeIndex < dayContainerControllers.length;
              timeIndex++) {
            final containerController = dayContainerControllers[timeIndex];
            if (SchoolLesson.isEmptyLesson(day.lessons[timeIndex])) {
              continue;
            }
            containerController.strikeThrough = value;

            if (value) {
              tt.setSpecialLesson(
                weekIndex: currWeekIndex,
                year: currYear,
                specialLesson: CancelledSpecialLesson(
                  dayIndex: dayIndex,
                  timeIndex: timeIndex,
                ),
              );
            } else {
              tt.removeSpecialLesson(
                year: currYear,
                weekIndex: currWeekIndex,
                dayIndex: dayIndex,
                timeIndex: timeIndex,
              );
            }
            await Future.delayed(
              const Duration(
                milliseconds: 100,
              ),
            );
          }
        },
        child: Container(
          color: Utils.sameDay(currLessonDateTime, DateTime.now())
              ? selectedColor
              : unselectedColor,
          width: lessonWidth,
          height: lessonHeight,
          child: Center(
            child: SizedBox(
              width: lessonWidth * 0.8,
              height: lessonHeight * 0.8,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                      children: [
                        FutureBuilder(
                          future: HolidaysManager.getRunningHolidays(
                            currLessonDateTime,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              snapshot.data!.getFormattedName(),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                        customTask == null || !showTaskOnHomescreen
                            ? const SizedBox.shrink()
                            : Text(
                                customTask.linkedSubjectName,
                                textAlign: TextAlign.center,
                              ),
                        Text(
                          day.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          Utils.dateToString(
                            currLessonDateTime,
                            showYear: false,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: customTask != null && showTaskOnHomescreen,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        customTask?.finished ?? false
                            ? Timetable.tickMark
                            : Timetable.exclamationMark,
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.dmSerifDisplay(
                          textStyle: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 4
                                  ..color = Theme.of(context).canvasColor,
                              ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: customTask != null && showTaskOnHomescreen,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        customTask?.finished ?? false
                            ? Timetable.tickMark
                            : Timetable.exclamationMark,
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.dmSerifDisplay(
                          textStyle: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: customTask?.getColor(),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    for (int lessonIndex = 0; lessonIndex < day.lessons.length; lessonIndex++) {
      final currSchoolTime = ttSchoolTimes[lessonIndex];
      final lesson = day.lessons[lessonIndex];
      final heroString = "$lessonIndex:$dayIndex";

      Color containerColor = unselectedColor;

      bool addBreakWidget = false;

      if (currSchoolTime.isCurrentlyRunning()) {
        containerColor = selectedColor;
      } else {
        if (lessonIndex + 1 < ttSchoolTimes.length) {
          final nextSchoolTime = ttSchoolTimes[lessonIndex + 1];
          int currTimeInSec = Utils.nowInSeconds();
          int currSchoolTimeEndInSec = currSchoolTime.end.toSeconds();
          int nextSchoolTimeStartInSec = nextSchoolTime.start.toSeconds();
          addBreakWidget = (currTimeInSec > currSchoolTimeEndInSec &&
              currTimeInSec < nextSchoolTimeStartInSec);
        }
      }

      TodoEvent? currEvent;

      if (widget.showTodoEvents) {
        final specialLesson = tt.getSpecialLesson(
          year: currYear,
          weekIndex: currWeekIndex,
          schoolDayIndex: dayIndex,
          schoolTimeIndex: lessonIndex,
        );

        SubstituteSpecialLesson? substituteSpecialLesson =
            (specialLesson is SubstituteSpecialLesson) ? specialLesson : null;

        currEvent = TimetableManager().getRunningTodoEvent(
          linkedSubjectName: substituteSpecialLesson?.name ?? lesson.name,
          lessonDayTime: currLessonDateTime,
        );
      }

      final StrikeThroughContainerController containerController =
          StrikeThroughContainerController();

      containerController.strikeThrough = tt.getSpecialLesson(
        schoolDayIndex: dayIndex,
        schoolTimeIndex: lessonIndex,
        weekIndex: currWeekIndex,
        year: currYear,
      ) is CancelledSpecialLesson;

      dayContainerControllers.add(containerController);

      final currDayIndex = Utils.getCurrentWeekDayIndex();

      // if (dayIndex == currDayIndex && lessonIndex == 0) {
      //   widget.controller.markSpecialLesson = () {
      //     containerController.strikeThrough = true;
      //     // tt.isSpecialLesson(
      //     //   schoolDayIndex: dayIndex,
      //     //   schoolTimeIndex: lessonIndex,
      //     //   weekIndex: currWeekIndex,
      //     //   year: currYear,
      //     // );
      //   };
      //   widget.controller.removeSpecialLessonMark = () {
      //     containerController.strikeThrough = false;
      //   };
      // }

      final key = isCurrDay && dayIndex == currDayIndex && lessonIndex == 0
          ? widget.controller.firstLessonKey
          : null;

      Widget lessonWidget = TimetableLessonWidget(
        key: key,
        containerController: containerController,
        heroString: heroString,
        containerColor: containerColor,
        currEvent: currEvent,
        currLessonDateTime: currLessonDateTime,
        currYear: currYear,
        currWeekIndex: currWeekIndex,
        dayIndex: dayIndex,
        lessonIndex: lessonIndex,
        lesson: lesson,
        lessonHeight: lessonHeight,
        lessonWidth: lessonWidth,
        showTaskOnHomescreen: showTaskOnHomescreen,
        tt: tt,
      );

      lessonWidgets.add(lessonWidget);

      if (addBreakWidget) {
        lessonWidgets.add(_createBreakHighlight());
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _createTimes(isCurrDay),
        Column(
          children: lessonWidgets,
        ),
      ],
    );
  }

  Widget _createBreakHighlight() {
    return Container(
      color: selectedColor,
      height: _breakLightHeight,
      width: lessonWidth,
    );
  }
}
