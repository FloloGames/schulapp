import 'dart:io';

import 'package:flutter/material.dart';
import 'package:schulapp/code_behind/school_note.dart';
import 'package:schulapp/screens/notes/image_preview_screen.dart';
import 'package:schulapp/widgets/notes/resizeble_widget.dart';

class InteractiveImageNoteWidget extends StatefulWidget {
  final SchoolNoteUI note;
  final SchoolNotePartImage partImage;

  const InteractiveImageNoteWidget({
    super.key,
    required this.partImage,
    required this.note,
  });

  @override
  State<InteractiveImageNoteWidget> createState() =>
      _InteractiveImageNoteWidgetState();
}

class _InteractiveImageNoteWidgetState
    extends State<InteractiveImageNoteWidget> {
  final resizebleController = ResizebleWidgetController();

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.partImage.inEditMode) {
      child = _editModeWidget();
    } else {
      child = _normalWidget();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: child,
    );
  }

  Widget _normalWidget() {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              pathToImg: widget.partImage.value,
              heroObj: widget.partImage,
            ),
          ),
        );
      },
      onLongPress: () {
        widget.partImage.inEditMode = true;
        setState(() {});
      },
      child: Hero(
        tag: widget.partImage,
        child: Image.file(
          File(widget.partImage.value),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _editModeWidget() {
    return Column(
      children: [
        // ResizebleWidget(
        // controller: resizebleController,
        // child:
        InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(widget.partImage.value),
            fit: BoxFit.contain,
          ),
        ),
        // ),
        _editBar(),
      ],
    );
  }

  Widget _editBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(1, 8, 1, 1),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              widget.partImage.inEditMode = false;
              setState(() {});
            },
            icon: const Icon(Icons.done),
          ),
          IconButton(
            onPressed: () {
              widget.note.moveNotePartUp(widget.partImage);
            },
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            onPressed: () {
              widget.note.moveNotePartDown(widget.partImage);
            },
            icon: const Icon(Icons.arrow_downward),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ImagePreviewScreen(
                    pathToImg: widget.partImage.value,
                    heroObj: widget.partImage,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              widget.note.removeNotePart(widget.partImage);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
