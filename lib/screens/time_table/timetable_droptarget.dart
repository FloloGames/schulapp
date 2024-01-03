import 'package:flutter/material.dart';
import 'package:schulapp/code_behind/school_day.dart';
import 'package:schulapp/code_behind/school_lesson.dart';
import 'package:schulapp/code_behind/school_lesson_prefab.dart';
import 'package:schulapp/code_behind/school_time.dart';
import 'package:schulapp/code_behind/time_table.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/widgets/custom_pop_up.dart';

// ignore: must_be_immutable
class TimetableDroptarget extends StatefulWidget {
  Timetable timetable;
  TimetableDroptarget({super.key, required this.timetable});

  @override
  State<TimetableDroptarget> createState() => _TimetableDroptargetState();
}

class _TimetableDroptargetState extends State<TimetableDroptarget> {
  @override
  Widget build(BuildContext context) {
    Timetable tt = widget.timetable;
    List<DataColumn> dataColumn = List.generate(
      tt.schoolDays.length,
      (index) => DataColumn(
        label: Expanded(
          child: Center(
            child: Text(
              tt.schoolDays[index].name,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    //füge Zeiten hinzu
    dataColumn.insert(
      0,
      const DataColumn(
        label: Expanded(
          child: Center(
            child: Text(
              "Times",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    List<DataRow> dataRow = List.generate(
      tt.maxLessonCount,
      (rowIndex) {
        return DataRow(
          // selected: rowIndex == 2,
          cells: List.generate(
            dataColumn.length,
            (cellIndex) {
              if (cellIndex == 0) {
                final startString = tt.schoolTimes[rowIndex].getStartString();
                final endString = tt.schoolTimes[rowIndex].getEndString();
                return DataCell(
                  Center(
                    child: Text(
                      "$startString\n$endString",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              //dadurch das wir jz eine Zeile mehr haben durch die Zeit müssen wir einen Index abziehen..
              int correctCellIndex = cellIndex - 1;
              final heroString = "$rowIndex:$correctCellIndex";
              final schoolDay = tt.schoolDays[correctCellIndex];
              final lesson = schoolDay.lessons[rowIndex];

              return DataCell(
                onTap: () {
                  _showPopUp(
                    context,
                    lesson,
                    schoolDay,
                    widget.timetable.schoolTimes[rowIndex],
                    heroString,
                  );
                },
                DragTarget(
                  onWillAccept: (SchoolLessonPrefab? schoolLessonPrefab) {
                    return schoolLessonPrefab != null;
                  },
                  onAccept: (SchoolLessonPrefab schoolLessonPrefab) {
                    lesson.setFromPrefab(schoolLessonPrefab);
                  },
                  builder: (context, accepted, rejected) {
                    const targetAlpha = 220;
                    ColorTween colorAnimation = ColorTween(
                      begin: lesson.color,
                      end: Theme.of(context).cardColor.withAlpha(targetAlpha),
                    );
                    return Center(
                      child: Hero(
                        tag: heroString,
                        flightShuttleBuilder:
                            (context, animation, __, ___, ____) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              return Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: colorAnimation.lerp(animation.value),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              );
                            },
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          width: 100,
                          // margin: const EdgeInsets.symmetric(vertical: 12),
                          // padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: lesson.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              lesson.name,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: dataColumn,
        rows: dataRow,
        columnSpacing: 25,
        horizontalMargin: 25,
      ),
    );
  }

  void _showPopUp(
    BuildContext context,
    SchoolLesson lesson,
    SchoolDay day,
    SchoolTime schoolTime,
    String heroString,
  ) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) =>
            CustomPopUpCreateTimetable(
          heroString: heroString,
          schoolDay: day,
          schoolLesson: lesson,
          schoolTime: schoolTime,
        ),
        barrierDismissible: true,
        fullscreenDialog: true,
      ),
    );
    setState(() {});
  }
}

// ignore: must_be_immutable
class CustomPopUpCreateTimetable extends StatefulWidget {
  SchoolTime schoolTime;
  SchoolLesson schoolLesson;
  SchoolDay schoolDay;
  String heroString;

  CustomPopUpCreateTimetable({
    super.key,
    required this.heroString,
    required this.schoolDay,
    required this.schoolLesson,
    required this.schoolTime,
  });

  @override
  State<CustomPopUpCreateTimetable> createState() =>
      _CustomPopUpCreateTimetableState();
}

class _CustomPopUpCreateTimetableState
    extends State<CustomPopUpCreateTimetable> {
  String _name = "";
  String _room = "";
  String _teacher = "";
  Color _color = Colors.black;

  TimeOfDay _start = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 0, minute: 0);

  @override
  void initState() {
    _name = widget.schoolLesson.name;
    _room = widget.schoolLesson.room;
    _teacher = widget.schoolLesson.teacher;
    _color = Color.fromARGB(
      widget.schoolLesson.color.alpha,
      widget.schoolLesson.color.red,
      widget.schoolLesson.color.green,
      widget.schoolLesson.color.blue,
    );

    _start = TimeOfDay(
      hour: widget.schoolTime.start.hour,
      minute: widget.schoolTime.start.minute,
    );
    _end = TimeOfDay(
      hour: widget.schoolTime.end.hour,
      minute: widget.schoolTime.end.minute,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopUp(
      heroString: widget.heroString,
      color: Theme.of(context).cardColor,
      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: () {
              SchoolLesson defaultSchoolLesson =
                  SchoolLesson.defaultSchoolLesson;
              widget.schoolLesson.name = defaultSchoolLesson.name;
              widget.schoolLesson.room = defaultSchoolLesson.room;
              widget.schoolLesson.teacher = defaultSchoolLesson.teacher;
              widget.schoolLesson.color = defaultSchoolLesson.color;

              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
              size: 32,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            String? input = await Utils.showStringInputDialog(
              context,
              hintText: "Enter Subject name",
              autofocus: true,
            );

            if (input == null) return;

            input = input.trim(); //mach so leerzeichen weg und so
            _name = input;
            setState(() {});
          },
          child: Text(
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.titleLarge?.color ?? Colors.white,
              // decoration: TextDecoration.underline,
              fontSize: 42.0,
              fontWeight: FontWeight.bold,
            ),
            _name,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        GestureDetector(
          onTap: () async {
            Color? input = await Utils.showColorInputDialog(context,
                hintText: "Select a color");

            if (input == null) return;

            _color = input;
            setState(() {});
          },
          child: Container(
            width: 150,
            height: 35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _color,
            ),
          ),
        ),
        // const SizedBox(
        //   height: 12,
        // ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.fitWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  TimeOfDay? input = await showTimePicker(
                      context: context, initialTime: widget.schoolTime.start);

                  if (input == null) return;

                  _start = input;
                  setState(() {});
                },
                child: Text(
                  _start.format(context),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white,
                    fontSize: 64.0,
                    // decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                " - ",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white,
                  fontSize: 64.0,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  TimeOfDay? input = await showTimePicker(
                      context: context, initialTime: widget.schoolTime.end);

                  if (input == null) return;

                  _end = input;
                  setState(() {});
                },
                child: Text(
                  _end.format(context),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white,
                    fontSize: 64.0,
                    // decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        FittedBox(
          fit: BoxFit.fitWidth,
          child: GestureDetector(
            onTap: () async {
              String? input = await Utils.showStringInputDialog(
                context,
                hintText: "Enter a Room number",
                autofocus: true,
              );

              if (input == null) return;

              input = input.trim(); //mach so leerzeichen weg und so
              _room = input;
              setState(() {});
            },
            child: Text(
              "Room: $_room",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
                fontSize: 42.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            String? input = await Utils.showStringInputDialog(
              context,
              hintText: "Enter a Teacher",
              autofocus: true,
            );

            if (input == null) return;

            input = input.trim(); //mach so leerzeichen weg und so
            _teacher = input;
            setState(() {});
          },
          child: Text(
            _teacher,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontSize: 42.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(
          flex: 2,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.close,
                size: 42,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _save();
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.check,
                size: 42,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _save() {
    widget.schoolLesson.name = _name;
    widget.schoolLesson.room = _room;
    widget.schoolLesson.teacher = _teacher;
    widget.schoolLesson.color = _color;
    widget.schoolTime.start = _start;
    widget.schoolTime.end = _end;
  }
}
