import 'package:flutter/material.dart';
import 'package:schulapp/code_behind/save_manager.dart';
import 'package:schulapp/code_behind/school_semester.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/widgets/date_selection_button.dart';
import 'package:schulapp/widgets/school_grade_subject_widget.dart';

// ignore: must_be_immutable
class SchoolGradeSubjectScreen extends StatefulWidget {
  SchoolGradeSubject subject;
  SchoolSemester semester;

  SchoolGradeSubjectScreen({
    super.key,
    required this.subject,
    required this.semester,
  });

  @override
  State<SchoolGradeSubjectScreen> createState() =>
      _SchoolGradeSubjectScreenState();
}

class _SchoolGradeSubjectScreenState extends State<SchoolGradeSubjectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Subject: "),
            Text(widget.subject.name),
          ],
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Hero(
            tag: widget.subject,
            flightShuttleBuilder: (flightContext, animation, flightDirection,
                fromHeroContext, toHeroContext) {
              return Center(
                child: Text(
                  widget.subject.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              );
            },
            child: Center(
              child: IgnorePointer(
                child: SchoolGradeSubjectWidget(
                  subject: widget.subject,
                  semester: widget.semester,
                ),
              ),
            ),
          ),
          ...List.generate(
            widget.subject.gradeGroups.length,
            _gradeGroupBuilder,
          ),
        ],
      ),
    );
  }

  Widget _gradeGroupBuilder(int index) {
    GradeGroup gg = widget.subject.gradeGroups[index];
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                gg.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                "${gg.percent} %",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          SizedBox(
            height: 50,
            child: SingleChildScrollView(
              primary: false,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  gg.grades.length,
                  (gradeNumberItemIndex) =>
                      _gradeNumberItem(gg, gradeNumberItemIndex),
                )..add(
                    IconButton(
                      onPressed: () async {
                        Grade? grade = await _showAddNewGradeSheet();
                        if (grade == null) return;
                        gg.grades.add(grade);
                        setState(() {});
                        SaveManager().saveSemester(widget.semester);
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeNumberItem(GradeGroup gg, int index) {
    Grade grade = gg.grades[index];
    return InkWell(
      onTap: () async {
        Grade? newGrade = await _showEditGradeSheet(grade);
        if (newGrade == null) {
          gg.grades.removeAt(index);
        } else {
          gg.grades[index] = newGrade;
        }
        setState(() {});
        SaveManager().saveSemester(widget.semester);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Utils.getGradeColor(grade.grade),
        ),
        child: Center(
          child: Text(grade.toString()),
        ),
      ),
    );
  }

  static const maxInfoLength = 50;
  Future<Grade?> _showEditGradeSheet(Grade grade) async {
    TextEditingController infoController = TextEditingController();
    infoController.text = grade.info;

    DateSelectionButtonController dateController =
        DateSelectionButtonController(date: grade.date.copyWith());

    bool deletePressed = false;

    int selectedGrade = -1;

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
                  'Edit Grade',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Extra info",
                  ),
                  maxLines: 1,
                  maxLength: maxInfoLength,
                  textAlign: TextAlign.center,
                  controller: infoController,
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Date:",
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: DateSelectionButton(
                        controller: dateController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap:
                      true, // Ensure GridView doesn't take more space than needed
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                  ),
                  itemCount: 16, // Including 0 to 15
                  itemBuilder: (context, index) {
                    int grade = 15 - index; // Numbers from 15 to 0
                    return InkWell(
                      onTap: () {
                        selectedGrade = grade;
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Utils.getGradeColor(grade),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$grade',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 12,
                ),
                ElevatedButton(
                  onPressed: () {
                    selectedGrade = grade.grade;
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
                const SizedBox(
                  height: 8,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                const SizedBox(
                  height: 8,
                ),
                IconButton(
                  onPressed: () {
                    deletePressed = true;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (deletePressed) return null;

    if (selectedGrade < 0 || selectedGrade > 15) return grade;

    return Grade(
      grade: selectedGrade,
      date: dateController.date,
      info: infoController.text.trim(),
    );
  }

  Future<Grade?> _showAddNewGradeSheet() async {
    TextEditingController infoController = TextEditingController();

    DateSelectionButtonController dateController =
        DateSelectionButtonController(date: DateTime.now());

    int selectedGrade = -1;

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
                  'Edit Grade',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Extra info",
                  ),
                  maxLines: 1,
                  maxLength: maxInfoLength,
                  textAlign: TextAlign.center,
                  controller: infoController,
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Date:",
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: DateSelectionButton(
                        controller: dateController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap:
                      true, // Ensure GridView doesn't take more space than needed
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                  ),
                  itemCount: 16, // Including 0 to 15
                  itemBuilder: (context, index) {
                    int grade = 15 - index; // Numbers from 15 to 0
                    return InkWell(
                      onTap: () {
                        selectedGrade = grade;
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Utils.getGradeColor(grade),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$grade',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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

    if (selectedGrade < 0 || selectedGrade > 15) return null;

    return Grade(
      grade: selectedGrade,
      date: dateController.date,
      info: infoController.text.trim(),
    );
  }
}
