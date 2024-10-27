import 'package:flutter/material.dart';
import 'package:schulapp/app.dart';
import 'package:schulapp/code_behind/school_note.dart';
import 'package:schulapp/code_behind/school_notes_manager.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';
import 'package:schulapp/screens/notes/edit_note_screen.dart';

class SchoolNoteListItem extends StatefulWidget {
  final SchoolNote schoolNote;
  final VoidCallback? onDelete;
  final bool showDeleteBtn;

  const SchoolNoteListItem({
    super.key,
    required this.schoolNote,
    this.onDelete,
    this.showDeleteBtn = true,
  });

  @override
  State<SchoolNoteListItem> createState() => _SchoolNoteListItemState();

  static Future<T?> openNote<T>(BuildContext context, SchoolNote note) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(
          schoolNote: note,
        ),
      ),
    );
  }
}

class _SchoolNoteListItemState extends State<SchoolNoteListItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: ListTile(
        onTap: () async {
          await SchoolNoteListItem.openNote(
            context,
            widget.schoolNote,
          );
          MainApp.changeNavBarVisibility(true);

          setState(() {});
        },
        title: Text(getTitle(widget.schoolNote)),
        trailing: !widget.showDeleteBtn
            ? const Icon(
                Icons.description,
              )
            : Wrap(
                spacing: 12, // space between two icons
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  IconButton(
                    onPressed: () async {
                      bool delete = await Utils.showBoolInputDialog(
                        context,
                        question: AppLocalizationsManager.localizations
                            .strDoYouWantToDeleteX(
                          getTitle(widget.schoolNote),
                        ),
                      );

                      if (!delete) return;

                      bool removed = SchoolNotesManager()
                          .removeSchoolNote(widget.schoolNote);

                      setState(() {});
                      widget.onDelete?.call();

                      if (!context.mounted) return;

                      if (removed) {
                        Utils.showInfo(
                          context,
                          type: InfoType.success,
                          msg: AppLocalizationsManager.localizations
                              .strSuccessfullyRemoved(
                            getTitle(widget.schoolNote),
                          ),
                        );
                      } else {
                        Utils.showInfo(
                          context,
                          type: InfoType.error,
                          msg: AppLocalizationsManager.localizations
                              .strCouldNotBeRemoved(
                            getTitle(widget.schoolNote),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  )
                ],
              ),
      ),
    );
  }

  String getTitle(SchoolNote note) {
    if (note.title.isNotEmpty) {
      return note.title;
    }

    return "${Utils.dateToString(note.creationDate)}, ${TimeOfDay.fromDateTime(note.creationDate).format(context)}";
  }
}
