import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:schulapp/code_behind/school_lesson.dart';
import 'package:schulapp/code_behind/settings.dart';
import 'package:schulapp/code_behind/special_lesson.dart';
import 'package:schulapp/code_behind/timetable.dart';
import 'package:schulapp/code_behind/timetable_manager.dart';
import 'package:schulapp/code_behind/timetable_util_functions.dart';
import 'package:schulapp/code_behind/todo_event.dart';
import 'package:schulapp/code_behind/todo_event_util_functions.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';
import 'package:schulapp/widgets/high_contrast_text.dart';
import 'package:schulapp/widgets/strike_through_container.dart';

class TimetableLessonWidget extends StatefulWidget {
  final StrikeThroughContainerController containerController;
  final Timetable tt;
  final DateTime currLessonDateTime;
  final SchoolLesson lesson;
  final TodoEvent? currEvent;

  final String heroString;

  final double lessonWidth;
  final double lessonHeight;

  final Color containerColor;

  final bool showTaskOnHomescreen;

  final int currYear;
  final int currWeekIndex;
  final int dayIndex;
  final int lessonIndex;

  const TimetableLessonWidget({
    super.key,
    required this.tt,
    required this.lesson,
    required this.containerController,
    required this.currEvent,
    required this.currLessonDateTime,
    required this.dayIndex,
    required this.heroString,
    required this.lessonIndex,
    required this.currWeekIndex,
    required this.currYear,
    required this.containerColor,
    required this.lessonHeight,
    required this.lessonWidth,
    required this.showTaskOnHomescreen,
  });

  @override
  State<TimetableLessonWidget> createState() => _TimetableLessonWidgetState();
}

class _TimetableLessonWidgetState extends State<TimetableLessonWidget> {
  bool highContrastEnabled = TimetableManager().settings.getVar<bool>(
        Settings.highContrastTextOnHomescreenKey,
      );

  // highContrastEnabled = true;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: SchoolLesson.isEmptyLesson(widget.lesson)
          ? null
          : () => _onLessonWidgetTap(
                dayIndex: widget.dayIndex,
                lessonIndex: widget.lessonIndex,
                heroString: widget.heroString,
                currEvent: widget.currEvent,
                eventEndTime: widget.currLessonDateTime,
              ),
      onLongPress: SchoolLesson.isEmptyLesson(widget.lesson)
          ? null
          : () {
              widget.containerController.changeStrikeThrough();
              if (widget.containerController.strikeThrough) {
                widget.tt.setSpecialLesson(
                  weekIndex: widget.currWeekIndex,
                  year: widget.currYear,
                  specialLesson: CancelledSpecialLesson(
                    dayIndex: widget.dayIndex,
                    timeIndex: widget.lessonIndex,
                  ),
                );
              } else {
                widget.tt.removeSpecialLesson(
                  year: widget.currYear,
                  weekIndex: widget.currWeekIndex,
                  dayIndex: widget.dayIndex,
                  timeIndex: widget.lessonIndex,
                );
              }
            },
      child: Container(
        color: widget.containerColor,
        width: widget.lessonWidth,
        height: widget.lessonHeight,
        child: Center(
          child: Hero(
            tag: widget.heroString,
            flightShuttleBuilder: (context, animation, __, ___, ____) {
              const targetAlpha = 220;

              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return Container(
                    width: widget.lessonWidth * 0.8,
                    height: widget.lessonHeight * 0.8,
                    decoration: BoxDecoration(
                      color: ColorTween(
                        begin: widget.lesson.color,
                        end: Theme.of(context).cardColor.withAlpha(targetAlpha),
                      ).lerp(animation.value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              );
            },
            child: StrikeThroughContainer(
              key: UniqueKey(),
              controller: widget.containerController,
              child: Container(
                width: widget.lessonWidth * 0.8,
                height: widget.lessonHeight * 0.8,
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.lesson.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          HighContrastText(
                            text: widget.lesson.name,
                            highContrastEnabled: highContrastEnabled,
                            textStyle: Theme.of(context).textTheme.bodyLarge,
                            fontWeight: null,
                            outlineWidth: 2,
                          ),
                          widget.lesson.room.isEmpty
                              ? const SizedBox.shrink()
                              : HighContrastText(
                                  text: widget.lesson.room,
                                  highContrastEnabled: highContrastEnabled,
                                  textStyle:
                                      Theme.of(context).textTheme.bodyLarge,
                                  fontWeight: null,
                                  outlineWidth: 2,
                                ),
                        ],
                      ),
                    ),
                    if (widget.currEvent != null)
                      Visibility(
                        visible: widget.showTaskOnHomescreen,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: HighContrastText(
                            text: widget.currEvent?.finished ?? false
                                ? Timetable.tickMark
                                : Timetable.exclamationMark,
                            fillColor: widget.currEvent?.getColor(),
                            textStyle: GoogleFonts.dmSerifDisplay(
                              textStyle:
                                  Theme.of(context).textTheme.headlineMedium,
                            ),
                            outlineWidth: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLessonWidgetTap({
    required int lessonIndex,
    required int dayIndex,
    required String heroString,
    required DateTime eventEndTime,
    TodoEvent? currEvent,
  }) async {
    final day = widget.tt.schoolDays[dayIndex];
    final lesson = day.lessons[lessonIndex];
    final schoolTime = widget.tt.schoolTimes[lessonIndex];

    bool? showNewTodoEvent = await showSchoolLessonHomePopUp(
      context,
      lesson,
      day,
      schoolTime,
      currEvent,
      heroString,
    );

    if (!mounted) return;
    setState(() {});

    if (showNewTodoEvent == null) return;
    if (!showNewTodoEvent) return;

    eventEndTime = eventEndTime.copyWith(
      hour: schoolTime.start.hour,
      minute: schoolTime.start.minute,
    );

    TodoEvent? event = TodoEvent(
      name: "",
      linkedSchoolNote: null,
      linkedSubjectName: lesson.name,
      endTime: eventEndTime,
      type: TodoType.test,
      desciption: "",
      isCustomEvent: false,
      finished: false,
    );

    event = await createNewTodoEventSheet(
      context,
      linkedSubjectName: lesson.name,
      event: event,
    );

    if (event == null) return;
    TimetableManager().addOrChangeTodoEvent(event);

    if (!mounted) return;
    Utils.showInfo(
      context,
      type: InfoType.success,
      msg: AppLocalizationsManager.localizations.strTaskSuccessfullyCreated,
    );

    setState(() {});
  }
}
