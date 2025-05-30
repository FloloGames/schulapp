import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:schulapp/code_behind/go_file_io_manager.dart';
import 'package:schulapp/code_behind/save_manager.dart';
import 'package:schulapp/code_behind/timetable.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';
import 'package:schulapp/screens/timetable/create_timetable_screen.dart';
import 'package:schulapp/widgets/online_code_bottom_sheet.dart';

class ImportTimetablePage extends StatefulWidget {
  final void Function() goToHomePage;

  const ImportTimetablePage({
    super.key,
    required this.goToHomePage,
  });

  @override
  State<ImportTimetablePage> createState() => _ImportTimetablePageState();
}

class _ImportTimetablePageState extends State<ImportTimetablePage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Spacer(),
        Column(
          spacing: 12,
          children: [
            ElevatedButton(
              onPressed: _selectViaCode,
              child: Text(
                AppLocalizationsManager.localizations.strImportViaCode,
              ),
            ),
            ElevatedButton(
              onPressed: _selectTimetable,
              child: Text(
                AppLocalizationsManager.localizations.strSelectTimetableFile(
                  SaveManager.timetableExportExtension,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            widget.goToHomePage();
          },
          child: Text(
            AppLocalizationsManager.localizations.strBack,
          ),
        ),
        const SizedBox(
          height: 16,
        ),
      ],
    );
  }

  void _selectTimetable() async {
    FilePickerResult? result;
    try {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        throw Exception("");
      }
      result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: [
          SaveManager.timetableExportExtension.replaceAll(".", "")
        ],
      );
    } on Exception {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
    }

    if (result == null) {
      if (mounted) {
        Utils.showInfo(
          context,
          msg: AppLocalizationsManager.localizations.strNoFileSelected,
          type: InfoType.error,
        );
      }
      return;
    }

    File selectedFile = File(result.files.single.path!);
    if (!selectedFile.existsSync()) {
      if (mounted) {
        Utils.showInfo(
          context,
          msg:
              AppLocalizationsManager.localizations.strSelectedFileDoesNotExist,
          type: InfoType.error,
        );
      }
      return;
    }

    if (mounted) {
      Utils.showInfo(
        context,
        msg: AppLocalizationsManager.localizations.strImportingTimetable,
      );
    }
    Timetable? timetable;
    try {
      timetable = SaveManager().importTimetable(selectedFile);
    } catch (e) {
      debugPrint(e.toString());
    }

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
    if (timetable == null) return;

    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTimetableScreen(timetable: timetable!),
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  void _selectViaCode() async {
    final allowed =
        await GoFileIoManager().showTermsOfServicesEnabledDialog(context);

    if (!allowed || !mounted) return;

    String? code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return const OnlineCodeBottomSheet();
      },
    );

    if (code == null) return;

    if (code.isEmpty || !mounted) return;

    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dContext) {
        dialogContext = dContext;
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                TextButton(
                  child: Text(AppLocalizationsManager.localizations.strCancel),
                  onPressed: () {
                    Navigator.of(dContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    String? downloadedPath;

    try {
      downloadedPath = (await GoFileIoManager().downloadFiles(
        code,
        isSaveCode: true,
      ))
          .first;
    } catch (e) {
      if (mounted) {
        Utils.showInfo(
          context,
          msg: e.toString(),
          type: InfoType.error,
        );
      }
    }

    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.of(dialogContext!).pop();
    }

    if (downloadedPath == null) return;

    Timetable? timetable;

    try {
      timetable = SaveManager().importTimetable(
        File(downloadedPath),
      );
    } catch (e) {
      debugPrint(e.toString());
    }

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

    if (timetable == null) return;

    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTimetableScreen(timetable: timetable!),
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pop();

    SaveManager().deleteTempDir();
  }
}
