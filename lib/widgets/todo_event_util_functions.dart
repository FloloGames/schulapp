import 'package:flutter/material.dart';
import 'package:schulapp/code_behind/time_table.dart';
import 'package:schulapp/code_behind/time_table_manager.dart';
import 'package:schulapp/code_behind/todo_event.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/widgets/date_selection_button.dart';
import 'package:schulapp/widgets/time_selection_button.dart';

Future<TodoEvent?> createNewTodoEventSheet(
  BuildContext context, {
  required String linkedSubjectName,
  TodoEvent? event,
}) async {
  const maxNameLength = TodoEvent.maxNameLength;
  const maxDescriptionLength = TodoEvent.maxDescriptionLength;

  TextEditingController nameController = TextEditingController();
  nameController.text = event?.name ?? "";
  TextEditingController descriptionController = TextEditingController();
  descriptionController.text = event?.desciption ?? "";

  DateSelectionButtonController endDateController =
      DateSelectionButtonController(
    date:
        Utils.getHomescreenTimetable()?.getNextLessonDate(linkedSubjectName) ??
            DateTime.now(),
  );

  bool onDateChangedCBsAlreadyCalled = false;

  endDateController.onDateChangedCBs.add((newDate) {
    if (onDateChangedCBsAlreadyCalled) {
      return; //so there is not infinity loop / Stackoverflow
    }

    final Timetable? homescreenTT = Utils.getHomescreenTimetable();
    if (homescreenTT == null) return;

    //because monday = 1 | we need to subtract 1
    final dayIndex = newDate.weekday - 1;
    if (dayIndex < 0 || dayIndex >= homescreenTT.schoolDays.length) {
      return;
    }

    final day = homescreenTT.schoolDays[dayIndex];
    for (int i = 0; i < day.lessons.length; i++) {
      var lesson = day.lessons[i];
      if (lesson.name == linkedSubjectName) {
        onDateChangedCBsAlreadyCalled = true;
        var time = homescreenTT.schoolTimes[i];
        endDateController.date = newDate.copyWith(
          hour: time.start.hour,
          minute: time.start.minute,
        );
        onDateChangedCBsAlreadyCalled = false;
        break;
      }
    }
  });

  if (event != null) {
    endDateController.date = event.endTime;
  }

  TodoType? type;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    scrollControlDisabledMaxHeightRatio: 0.5,
    builder: (context) {
      return SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create new Task / Note\n$linkedSubjectName',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: "Topic",
                ),
                maxLines: 1,
                maxLength: maxNameLength,
                textAlign: TextAlign.center,
                controller: nameController,
              ),
              const SizedBox(
                height: 12,
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: "Extra info",
                ),
                maxLength: maxDescriptionLength,
                maxLines: 5,
                minLines: 1,
                textAlign: TextAlign.center,
                controller: descriptionController,
              ),
              const SizedBox(
                height: 12,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "End date:",
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.left,
                        ),
                        // IconButton(
                        //   onPressed: () async {
                        //     final timetable = Utils.getHomescreenTimetable();

                        //     if (timetable == null) {
                        //       Utils.showInfo(
                        //         context,
                        //         msg: "No Homescreen timetable selected!",
                        //         type: InfoType.error,
                        //       );
                        //       return;
                        //     }

                        //     Utils.showCustomPopUp(
                        //       context: context,
                        //       heroObject: null,
                        //       body: const Center(
                        //         child: Text("test"),
                        //       ),
                        //     );
                        //   },
                        //   icon: const Icon(Icons.dataset_outlined),
                        // ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: DateSelectionButton(
                            controller: endDateController,
                          ),
                        ),
                        TimeSelectionButton(
                          controller: endDateController,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: customButton(
                        context,
                        text: "Exam",
                        icon: TodoEvent.examIcon,
                        onTap: () {
                          type = TodoType.exam;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: customButton(
                        context,
                        text: "Test",
                        icon: TodoEvent.testIcon,
                        onTap: () {
                          type = TodoType.test;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: customButton(
                        context,
                        text: "Presentation",
                        icon: TodoEvent.presentationIcon,
                        onTap: () {
                          type = TodoType.presentation;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: customButton(
                        context,
                        text: "Homework",
                        icon: TodoEvent.homeworkIcon,
                        onTap: () {
                          type = TodoType.homework;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (type == null) return null;

  String name = nameController.text.trim();
  String desciption = descriptionController.text.trim();

  // if (name.isEmpty) {
  //   if (mounted) {
  //     Utils.showInfo(
  //       context,
  //       msg: "Name can not be empty!",
  //       type: InfoType.error,
  //     );
  //   }
  //   return null;
  // }

  return TodoEvent(
    key: event?.key ?? TimetableManager().getNextSchoolEventKey(),
    name: name,
    desciption: desciption,
    linkedSubjectName: linkedSubjectName,
    endTime: endDateController.date,
    type: type!,
    finished: event?.finished ?? false,
  );
}

Widget customButton(
  BuildContext context, {
  required String text,
  IconData? icon,
  required void Function()? onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(16),
        // shape: BoxShape.circle,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            icon == null
                ? Container()
                : Icon(
                    icon,
                  ),
            const SizedBox(
              height: 8,
            ),
            Text(
              text,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ),
  );
}
