import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/material.dart';
import 'package:schulapp/code_behind/school_notes_manager.dart';
import 'package:schulapp/code_behind/todo_event.dart';
import 'package:schulapp/code_behind/timetable_manager.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';
import 'package:schulapp/widgets/navigation_bar_drawer.dart';
import 'package:schulapp/code_behind/timetable_util_functions.dart';
import 'package:schulapp/widgets/notes/school_note_list_item.dart';
import 'package:schulapp/widgets/task/todo_event_list_item_widget.dart';
import 'package:schulapp/code_behind/todo_event_util_functions.dart';
import 'package:schulapp/widgets/task/todo_event_to_finished_task_overlay.dart';
import 'package:tuple/tuple.dart';

// ignore: must_be_immutable
class TasksScreen extends StatefulWidget {
  static const route = "/tasks";

  TodoEvent? todoEvent;
  final bool showFinishedTasks;

  TasksScreen({
    super.key,
    this.todoEvent,
    this.showFinishedTasks = false,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final GlobalKey _showFinishedTasksActionKey = GlobalKey();
  final GlobalKey _backButtonKey = GlobalKey();

  List<TodoEvent> selectedTodoEvents = [];
  bool isMultiselectionActive = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(
      Duration.zero,
      () async {
        if (widget.todoEvent != null && mounted) {
          await Utils.showCustomPopUp(
            context: context,
            heroObject: widget.todoEvent!,
            body: TodoEventInfoPopUp(
              event: widget.todoEvent!,
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
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.showFinishedTasks
          ? null
          : NavigationBarDrawer(selectedRoute: TasksScreen.route),
      appBar: AppBar(
        title: widget.showFinishedTasks
            ? Text(
                AppLocalizationsManager.localizations.strFinishedTasks,
              )
            : Text(
                AppLocalizationsManager.localizations.strTasks,
              ),
        leading: widget.showFinishedTasks
            ? IconButton(
                key: _backButtonKey,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: !isMultiselectionActive
            ? [
                Visibility(
                  visible: !widget.showFinishedTasks,
                  child: IconButton(
                    key: _showFinishedTasksActionKey,
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TasksScreen(
                            showFinishedTasks: true,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                    tooltip: AppLocalizationsManager
                        .localizations.strShowFinishedTasks,
                    icon: const Icon(
                      Icons.done_all,
                    ),
                  ),
                ),
              ]
            : [
                IconButton(
                  onPressed: _unselectAllItems,
                  tooltip: AppLocalizationsManager.localizations.strCancel,
                  icon: const Icon(
                    Icons.cancel,
                  ),
                ),
                IconButton(
                  onPressed: _finishOrUnfinishSelectedEvents,
                  tooltip:
                      AppLocalizationsManager.localizations.strMarkAsUNfinished,
                  icon: const Icon(
                    Icons.check,
                    color: Colors.green,
                  ),
                ),
                IconButton(
                  onPressed: _deleteSelectedEvents,
                  tooltip: AppLocalizationsManager
                      .localizations.strDeleteSelectedItems,
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ],
      ),
      floatingActionButton:
          widget.showFinishedTasks ? null : _floatingActionButton(),
      body: _body(),
    );
  }

  Widget _body() {
    final List<TodoEvent> events;

    if (widget.showFinishedTasks) {
      events = TimetableManager().sortedFinishedTodoEvents;
    } else {
      events = TimetableManager().sortedUnfinishedTodoEvents;
    }

    if (events.isEmpty) {
      if (widget.showFinishedTasks) {
        return Center(
          child: Text(
            AppLocalizationsManager.localizations.strNoTasksFinishedYet,
          ),
        );
      }
      return Center(
        child: ElevatedButton(
          onPressed: () async {
            //selectedSubjectName, isCustomName
            (String, bool)? selectedSubjectTuple =
                await showSelectSubjectNameSheet(
              context,
              title: AppLocalizationsManager
                  .localizations.strSelectSubjectToAddTaskTo,
              allowCustomNames: true,
            );

            if (!mounted) return;
            if (selectedSubjectTuple == null) return;

            String? selectedSubjectName = selectedSubjectTuple.$1;
            bool? isCustomTask = selectedSubjectTuple.$2;

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
          child: Text(
            AppLocalizationsManager.localizations.strCreateATask,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ImplicitlyAnimatedList<TodoEvent>(
            items: events,
            itemBuilder: (context, animation, event, index) {
              final bool isSelected = isMultiselectionActive
                  ? _selectedTodoEventsContains(event)
                  : false;
              return Builder(
                builder: (itemContext) {
                  return SizeFadeTransition(
                    sizeFraction: 0.7,
                    animation: animation,
                    key: Key(event.key.toString()),
                    child: TodoEventListItemWidget(
                      event: event,
                      isSelected: isSelected,
                      onLongPressed: () {
                        addOrActivateMultiselection(event);
                      },
                      onInfoPressed: () async {
                        await Utils.showCustomPopUp(
                          context: context,
                          heroObject: event,
                          alpha: 250,
                          body: TodoEventInfoPopUp(
                            event: event,
                            showEditTodoEventSheet: (event) async {
                              TodoEvent? newEvent =
                                  await createNewTodoEventSheet(
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
                      onPressed: () {
                        if (isMultiselectionActive) {
                          addOrActivateMultiselection(event);
                          return;
                        }
                        event.finished = !event.finished;
                        //damit es gespeichert wird
                        TimetableManager().addOrChangeTodoEvent(event);

                        setState(() {});

                        if (!widget.showFinishedTasks) {
                          _createAnimationToFinishedTasks(event, itemContext);
                        } else {
                          _createAnimationToUnfinishedTasks(event, itemContext);
                        }
                      },
                      onDeleteSwipe: () {
                        setState(() {
                          TimetableManager().removeTodoEvent(event);
                        });
                      },
                    ),
                  );
                },
              );
            },
            areItemsTheSame: (a, b) =>
                a.desciption == b.desciption &&
                a.endTime == b.endTime &&
                a.name == b.name &&
                a.type == b.type &&
                a.linkedSubjectName == b.linkedSubjectName,
          ),
        ),
        multiSelectionButton(),
      ],
    );
  }

  void addOrActivateMultiselection(TodoEvent event) {
    if (!isMultiselectionActive) {
      isMultiselectionActive = true;
      _finishSelectedEvents = !event.finished;
      _currentMultiSelectionButtonTextIndex = 0;
    }
    bool isSelected = _selectedTodoEventsContains(event);
    if (isSelected) {
      removeOrDisableMultiselection(event);
    } else {
      addToMultiselection(event);
    }
  }

  bool _selectedTodoEventsContains(TodoEvent event) {
    return selectedTodoEvents.contains(event);
    // return selectedTodoEvents.any(
    //   (element) {
    //     return element.name == event.name &&
    //         element.desciption == event.desciption &&
    //         element.linkedSubjectName == event.linkedSubjectName;
    //   },
    // );
  }

  void addToMultiselection(TodoEvent event) {
    selectedTodoEvents.add(event);
    setState(() {});
  }

  void removeOrDisableMultiselection(TodoEvent event) {
    if (!isMultiselectionActive) return;

    bool isSelected = _selectedTodoEventsContains(event);

    if (isSelected) {
      removeFromMultiselection(event);
    }
    isMultiselectionActive = selectedTodoEvents.isNotEmpty;
    setState(() {});
  }

  void removeFromMultiselection(TodoEvent event) {
    selectedTodoEvents.remove(event);
    setState(() {});
  }

  Widget? _floatingActionButton() {
    if (isMultiselectionActive) return null;

    return FloatingActionButton(
      child: const Icon(Icons.assignment_add),
      onPressed: () async {
        //selectedSubjectName, isCustomTask
        (String, bool)? selectedSubjectNameTuple =
            await showSelectSubjectNameSheet(
          context,
          title:
              AppLocalizationsManager.localizations.strSelectSubjectToAddTaskTo,
          allowCustomNames: true,
        );

        if (selectedSubjectNameTuple == null) return;
        if (!mounted) return;

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
    );
  }

  int _currentMultiSelectionButtonTextIndex = 0;
  Widget multiSelectionButton() {
    if (!isMultiselectionActive) return Container();

    var buttons = [
      Tuple2<String, List<TodoEvent> Function(List<TodoEvent>)>(
        AppLocalizationsManager.localizations.strSelectAllExpiredTasks,
        (todoEvents) {
          return todoEvents.where((element) => element.isExpired()).toList();
        },
      ),
      Tuple2<String, List<TodoEvent> Function(List<TodoEvent>)>(
        AppLocalizationsManager.localizations.strSelectAllTasks,
        (todoEvents) {
          return todoEvents.where((element) => true).toList();
        },
      ),
    ];
    if (widget.showFinishedTasks) {
      buttons = [
        Tuple2<String, List<TodoEvent> Function(List<TodoEvent>)>(
          AppLocalizationsManager.localizations.strSelectAllFinishedTasks,
          (todoEvents) {
            return todoEvents.where((element) => element.finished).toList();
          },
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: () {
          List<TodoEvent> Function(List<TodoEvent>) func =
              buttons[_currentMultiSelectionButtonTextIndex].item2;

          isMultiselectionActive = true;
          selectedTodoEvents = func(TimetableManager().sortedTodoEvents);
          _currentMultiSelectionButtonTextIndex++;
          if (_currentMultiSelectionButtonTextIndex >= buttons.length) {
            _currentMultiSelectionButtonTextIndex = 0;
          }
          setState(() {});
        },
        child: Text(buttons[_currentMultiSelectionButtonTextIndex].item1),
      ),
    );
  }

  void _unselectAllItems() {
    if (!isMultiselectionActive) return;
    isMultiselectionActive = false;
    selectedTodoEvents.clear();
    setState(() {});
  }

  bool _finishSelectedEvents = true;
  Future<void> _finishOrUnfinishSelectedEvents() async {
    if (!isMultiselectionActive) return;
    final List<String> finishOrUnfinisString = [
      AppLocalizationsManager.localizations.strFinish,
      AppLocalizationsManager.localizations.strUnfinish,
    ];
    String finishString = finishOrUnfinisString[_finishSelectedEvents ? 0 : 1];
    bool finishOrUnfinish = await Utils.showBoolInputDialog(
      context,
      question:
          AppLocalizationsManager.localizations.strDoYouWantToFinishXTasks(
        finishString,
        selectedTodoEvents.length,
      ),
    );
    if (!finishOrUnfinish) return;

    final copySelectedTodoEvents = List<TodoEvent>.from(
      selectedTodoEvents,
      growable: true,
    );

    for (TodoEvent event in copySelectedTodoEvents) {
      event.finished = _finishSelectedEvents;

      TimetableManager().addOrChangeTodoEvent(event);

      await Future.delayed(
        const Duration(milliseconds: 150),
      );
      setState(() {});
    }
    selectedTodoEvents.clear();
    isMultiselectionActive = false;
    setState(() {});

    _finishSelectedEvents = !_finishSelectedEvents;
  }

  Future<void> _deleteSelectedEvents() async {
    if (!isMultiselectionActive) return;

    bool delete = await Utils.showBoolInputDialog(
      context,
      question:
          AppLocalizationsManager.localizations.strDoYouWantToDeleteXTasks(
        selectedTodoEvents.length,
      ),
    );

    if (!delete) return;

    isMultiselectionActive = false;
    setState(() {});

    final copySelectedTodoEvents = List.from(
      selectedTodoEvents,
      growable: false,
    );

    bool deleteNote = false;
    bool showDeleteNote = false;

    for (var event in copySelectedTodoEvents) {
      if (event.linkedSchoolNote != null) {
        showDeleteNote = true;
      }
    }

    if (showDeleteNote && mounted) {
      final delete = await Utils.showBoolInputDialog(
        context,
        question: AppLocalizationsManager
            .localizations.strDoYouWantToDeleteAllLinkedNote,
      );
      deleteNote = delete;
    }

    for (TodoEvent event in copySelectedTodoEvents) {
      TimetableManager().removeTodoEvent(
        event,
        deleteLinkedSchoolNote: deleteNote,
      );
      await Future.delayed(
        const Duration(milliseconds: 150),
      );
      setState(() {});
    }
    selectedTodoEvents.clear();
  }

  void _createAnimationToFinishedTasks(
      TodoEvent event, BuildContext itemContext) {
    _animateTodoEvent(
      todoEvent: event,
      itemContext: itemContext,
      targetKey: _showFinishedTasksActionKey,
    );
  }

  void _createAnimationToUnfinishedTasks(
      TodoEvent event, BuildContext itemContext) {
    _animateTodoEvent(
      todoEvent: event,
      itemContext: itemContext,
      targetKey: _backButtonKey,
    );
  }

  void _animateTodoEvent({
    required TodoEvent todoEvent,
    required BuildContext itemContext,
    required GlobalKey targetKey,
  }) {
    final backButtonBox =
        targetKey.currentContext!.findRenderObject() as RenderBox;
    final itemEndTopLeft = backButtonBox.localToGlobal(Offset.zero);

    final itemEndCenter = Offset(
      itemEndTopLeft.dx + backButtonBox.size.width / 2,
      itemEndTopLeft.dy + backButtonBox.size.height / 2,
    );

    // Get the position of ListTile
    RenderBox listItemBox = itemContext.findRenderObject() as RenderBox;
    Offset itemStartTopLeft = listItemBox.localToGlobal(Offset.zero);

    final itemStartCenter = Offset(
      itemStartTopLeft.dx + listItemBox.size.width / 2,
      itemStartTopLeft.dy + listItemBox.size.height / 2,
    );

    OverlayState overlayState = Overlay.of(context);

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => TodoEventToFinishedTaskOverlay(
        todoEvent: todoEvent,
        itemStartCenter: itemStartCenter,
        itemEndCenter: itemEndCenter,
        itemSize: listItemBox.size,
        onComplete: () {
          overlayEntry?.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

// ignore: must_be_immutable
class TodoEventInfoPopUp extends StatelessWidget {
  Future<TodoEvent?> Function(TodoEvent event) showEditTodoEventSheet;
  TodoEvent event;

  TodoEventInfoPopUp({
    super.key,
    required this.event,
    required this.showEditTodoEventSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () async {
                bool deleteNote = false;

                if (event.linkedSchoolNote != null) {
                  final delete = await Utils.showBoolInputDialog(
                    context,
                    question: AppLocalizationsManager
                        .localizations.strDoYouWantToDeleteLinkedNote,
                  );
                  deleteNote = delete;
                }
                TimetableManager().removeTodoEvent(
                  event,
                  deleteLinkedSchoolNote: deleteNote,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 32,
              ),
            ),
            Icon(
              event.getIcon(),
              color: event.getColor(),
            ),
            IconButton(
              onPressed: () async {
                TodoEvent? newEvent = await showEditTodoEventSheet(event);

                if (newEvent == null) return;

                TimetableManager().addOrChangeTodoEvent(newEvent);

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.edit,
                size: 32,
              ),
            ),
          ],
        ),
        Text(
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          event.linkedSubjectName,
          textAlign: TextAlign.center,
        ),
        Text(
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          event.name,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 24,
        ),
        _getDescriptionOrSchoolNoteWidget(context),
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: event.endTime == null
              ? Text(
                  AppLocalizationsManager.localizations.strNoEndDate,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                )
              : Text(
                  "${Utils.dateToString(event.endTime!)} | ${event.endTime!.hour} : ${event.endTime!.minute}",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(
          height: 12,
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.check,
            size: 42,
          ),
        ),
      ],
    );
  }

  Widget _getDescriptionOrSchoolNoteWidget(BuildContext context) {
    final linkedNote = event.linkedSchoolNote;
    if (linkedNote != null) {
      final schoolNote = SchoolNotesManager().getSchoolNoteBySaveName(
        linkedNote,
      );

      if (schoolNote != null) {
        return Flexible(
          fit: FlexFit.tight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                child: SchoolNoteListItem(
                  schoolNote: schoolNote,
                  showDeleteBtn: false,
                ),
              ),
            ],
          ),
        );
      }
    }
    return Visibility(
      visible: event.desciption.isNotEmpty,
      replacement: const Spacer(),
      child: Flexible(
        fit: FlexFit.tight,
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Text(
              event.desciption,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ),
    );
  }
}
