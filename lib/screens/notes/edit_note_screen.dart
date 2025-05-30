import 'dart:io';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schulapp/app.dart';
import 'package:schulapp/code_behind/save_manager.dart';
import 'package:schulapp/code_behind/school_note.dart';
import 'package:schulapp/code_behind/school_note_part.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';

class EditNoteScreen extends StatefulWidget {
  final SchoolNote schoolNote;
  //nur true wenn es eine nicht gespeicherte
  //Notiz ist, welche gerade importiert wird
  final bool isImportSchoolNote;

  const EditNoteScreen({
    super.key,
    required this.schoolNote,
    this.isImportSchoolNote = false,
  });

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final TextEditingController _headingTextController = TextEditingController();

  late final SchoolNoteUI _schoolNote;

  @override
  void initState() {
    MainApp.changeNavBarVisibility(false);
    _schoolNote = SchoolNoteUI(
      schoolNote: widget.schoolNote,
    );
    _schoolNote.addListener(onSchoolNoteChange);
    _headingTextController.text = _schoolNote.schoolNote.title;

    super.initState();
  }

  @override
  void dispose() {
    MainApp.changeNavBarVisibility(true);
    _schoolNote.removeListener(onSchoolNoteChange);
    _saveNote();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizationsManager.localizations.strEditNote),
        actions: [
          IconButton(
            onPressed: _onInfoPressed,
            icon: const Icon(Icons.info),
          ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _headingTextController,
            // onChanged: (value) {
            //   widget.schoolNote.title = value;
            // },
            onEditingComplete: () {
              _saveNote();
            },
            onSubmitted: (value) {
              _saveNote();
            },
            onTapOutside: (event) {
              _saveNote();
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: AppLocalizationsManager.localizations.strTitle,
            ),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        Expanded(
          child: ImplicitlyAnimatedList<SchoolNotePart>(
            items: widget.schoolNote.parts,
            itemBuilder: (context, animation, item, index) {
              return SizeFadeTransition(
                sizeFraction: 0.7,
                animation: animation,
                key: ValueKey(item.value),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(
                      seconds: 1,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.render(
                      _schoolNote,
                    ),
                  ),
                ),
              );
            },
            areItemsTheSame: (oldItem, newItem) =>
                oldItem.value == newItem.value,
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _onAddImagePressed,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                ),
              ),
              IconButton(
                onPressed: _onAddFilePressed,
                icon: const Icon(Icons.note_add),
              ),
              IconButton(
                onPressed: _onAddTextPressed,
                icon: const Icon(
                  Icons.add_box_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onAddImagePressed() async {
    final ImagePicker picker = ImagePicker();

    final XFile? imageFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (imageFile == null) return;

    if (!File(imageFile.path).existsSync()) {
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

    final filename = _schoolNote.addFile(
      File(imageFile.path),
    );

    if (filename == null) {
      if (mounted) {
        Utils.showInfo(
          context,
          msg: AppLocalizationsManager.localizations.strThereWasAnError,
          type: InfoType.error,
        );
      }
      return;
    }

    _schoolNote.addPart(
      SchoolNotePartImage(
        value: filename,
      ),
    );

    _saveNote();
  }

  Future<void> _onAddFilePressed() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
    } on Exception {
      if (mounted) {
        Utils.showInfo(
          context,
          msg: AppLocalizationsManager.localizations.strThereWasAnError,
          type: InfoType.error,
        );
      }
      return;
    }

    String? path = result?.files.single.path;
    if (path == null) {
      if (mounted) {
        Utils.showInfo(
          context,
          msg: AppLocalizationsManager.localizations.strNoFileSelected,
          type: InfoType.error,
        );
      }
      return;
    }

    if (!File(path).existsSync()) {
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

    if (!mounted) return;

    final copyFile = await Utils.showBoolInputDialog(
      context,
      question: AppLocalizationsManager
          .localizations.strDoYouWantToCreateACopyOfTheFile,
      description: AppLocalizationsManager
          .localizations.strDoYouWantToCreateACopyOfTheFileDescription,
      showYesAndNoInsteadOfOK: true,
    );

    if (copyFile) {
      final filename = _schoolNote.addFile(
        File(path),
        keepFileName: true,
      );
      if (filename == null) {
        if (mounted) {
          Utils.showInfo(
            context,
            msg: AppLocalizationsManager.localizations.strThereWasAnError,
            type: InfoType.error,
          );
        }
        return;
      }

      path = filename;
    }

    _schoolNote.addPart(
      SchoolNotePartFile(
        value: path,
        isLink: !copyFile,
      ),
    );

    _saveNote();
  }

  void _onAddTextPressed() {
    _schoolNote.addPart(
      SchoolNotePartText(),
    );

    _saveNote();
  }

  void onSchoolNoteChange() {
    if (!mounted) return;
    setState(() {});
    _saveNote();
  }

  void _saveNote() {
    if (widget.isImportSchoolNote) return;

    widget.schoolNote.title = _headingTextController.text.trim();

    SaveManager().saveSchoolNote(widget.schoolNote);
  }

  void _onInfoPressed() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            AppLocalizationsManager.localizations.strInformation,
          ),
          content: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizationsManager.localizations.strCreatedOn,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          _getCreatedDateString(),
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                        ),
                      ),
                      if (kDebugMode)
                        Expanded(
                          child: Text(
                            "Directory name",
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Divider(
                    color: Theme.of(context).dividerColor,
                    thickness: 1,
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizationsManager
                              .localizations.strLastModifiedOn,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          _getLastModifiedString(),
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                        ),
                      ),
                      if (kDebugMode)
                        Expanded(
                          child: SelectableText(
                            widget.schoolNote.saveFileName,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizationsManager.localizations.strOK,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCreatedDateString() => "${Utils.dateToString(
        widget.schoolNote.creationDate,
      )}, ${TimeOfDay.fromDateTime(widget.schoolNote.creationDate).format(context)}";

  String _getLastModifiedString() => "${Utils.dateToString(
        widget.schoolNote.lastModifiedDate,
      )}, ${TimeOfDay.fromDateTime(widget.schoolNote.lastModifiedDate).format(context)}";
}
