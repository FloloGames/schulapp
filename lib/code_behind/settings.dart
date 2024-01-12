import 'package:schulapp/code_behind/save_manager.dart';
import 'package:schulapp/code_behind/school_semester.dart';

class Settings {
  static const mainTimetableNameKey = "mainTimetable";
  static const defaultGradeGroupsKey = "defaultGradeGroups";
  static const showLessonNumbersKey = "showLessonNumbers";
  static const timetableLessonWidthKey = "timetableLessonWidth";

  ///if [null] firstTimetable shown
  String? _mainTimetableName;
  double? _timetableLessonWidth;
  bool? _showLessonNumbers;

  bool get showLessonNumbers {
    return _showLessonNumbers ?? false;
  }

  set showLessonNumbers(bool? value) {
    _showLessonNumbers = value;
    SaveManager().saveSettings(this);
  }

  double get timetableLessonWidth {
    const double defaultValue = 100;

    _timetableLessonWidth ??= defaultValue;

    return _timetableLessonWidth!;
  }

  set timetableLessonWidth(double? width) {
    _timetableLessonWidth = width;
    SaveManager().saveSettings(this);
  }

  String? get mainTimetableName {
    return _mainTimetableName;
  }

  set mainTimetableName(String? value) {
    _mainTimetableName = value;
    SaveManager().saveSettings(this);
  }

  List<GradeGroup> get defaultGradeGroups {
    return [
      GradeGroup(
        name: "Written & Verbal grades",
        percent: 67,
        grades: [],
      ),
      GradeGroup(
        name: "Exam grades",
        percent: 33,
        grades: [],
      ),
    ];
  }

  Settings({
    String? mainTimetableName,
    double? timetableLessonWidth,
    bool? showLessonNumbers,
  })  : _mainTimetableName = mainTimetableName,
        _timetableLessonWidth = timetableLessonWidth,
        _showLessonNumbers = showLessonNumbers;

  Map<String, dynamic> toJson() {
    return {
      mainTimetableNameKey: _mainTimetableName,
      showLessonNumbersKey: _showLessonNumbers,
      timetableLessonWidthKey: _timetableLessonWidth,
      // defaultGradeGroupsKey: _defaultGradeGroups != null
      //     ? List.generate(
      //         _defaultGradeGroups!.length,
      //         (index) => _defaultGradeGroups![index].toJson(),
      //       )
      //     : null,
    };
  }

  static Settings fromJson(Map<String, dynamic> json) {
    String? mainTimetableName = json[mainTimetableNameKey];
    double? timetableLessonWidth = json[timetableLessonWidthKey];
    bool? showLessonNumbers = json[showLessonNumbersKey];
    // List<Map<String, dynamic>>? defaultGradeGroupsJson =
    //     json[defaultGradeGroupsKey];

    // List<GradeGroup>? gradeGroups = defaultGradeGroupsJson == null
    //     ? null
    //     : List.generate(
    //         defaultGradeGroupsJson.length,
    //         (index) => GradeGroup.fromJson(
    //           defaultGradeGroupsJson[index],
    //         ),
    //       );

    return Settings(
      mainTimetableName: mainTimetableName,
      timetableLessonWidth: timetableLessonWidth,
      showLessonNumbers: showLessonNumbers,
      // defaultGradeGroups: gradeGroups,
    );
  }
}
