import 'package:flutter/material.dart';
import 'package:schulapp/screens/time_table/export_timetable_page.dart';
import 'package:schulapp/screens/time_table/import_timetable_page.dart';
// import 'package:share_plus/share_plus.dart';

class ImportExportTimetableScreen extends StatefulWidget {
  const ImportExportTimetableScreen({super.key});

  @override
  State<ImportExportTimetableScreen> createState() =>
      _ImportExportTimetableScreenState();
}

class _ImportExportTimetableScreenState
    extends State<ImportExportTimetableScreen> {
  static const animDuration = Duration(milliseconds: 350);
  static const animCurve = Curves.easeOut;

  static const importExportString = "Import / Export Timetable";
  static const importString = "Import Timetable";
  static const exportString = "Export Timetable";
  static const homePageIndex = 1;

  final PageController _pageController = PageController(
    initialPage: homePageIndex,
  );

  String _titleString = importExportString;

  int _currPageIndex = homePageIndex;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currPageIndex == homePageIndex,
      onPopInvoked: (didPop) async {
        if (_currPageIndex == homePageIndex) {
          return;
        }

        await _goToPage(homePageIndex);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleString),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    return PageView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _pageController,
      onPageChanged: (currPage) {
        _currPageIndex = currPage;
        setState(() {});
      },
      children: [
        ImportTimetablePage(
          goToHomePage: () {
            _titleString = importExportString;
            setState(() {});
            _goToPage(homePageIndex);
          },
        ),
        _importExportPage(),
        ExportTimetablePage(
          goToHomePage: () {
            _titleString = importExportString;
            setState(() {});
            _goToPage(homePageIndex);
          },
        ),
      ],
    );
  }

  Widget _importExportPage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            _titleString = importString;
            setState(() {});
            _goToPage(0);
          },
          child: const Text("Import"),
        ),
        ElevatedButton(
          onPressed: () {
            _titleString = exportString;
            setState(() {});
            _goToPage(2);
          },
          child: const Text("Export"),
        ),
      ],
    );
  }

  Future _goToPage(int index) {
    return _pageController.animateToPage(
      index,
      duration: animDuration,
      curve: animCurve,
    );
  }
}
