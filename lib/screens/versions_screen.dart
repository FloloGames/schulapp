import 'package:flutter/material.dart';
import 'package:schulapp/code_behind/version_manager.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';

// ignore: must_be_immutable
class VersionsScreen extends StatefulWidget {
  String lastUsedVersion;

  VersionsScreen({
    super.key,
    required this.lastUsedVersion,
  });

  @override
  State<VersionsScreen> createState() => _VersionsScreenState();
}

class _VersionsScreenState extends State<VersionsScreen> {
  List<(String, String)> versionsToShow = [];

  @override
  Widget build(BuildContext context) {
    _updateVersionsToShow();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizationsManager.localizations.strVersions),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return ListView.builder(
      itemCount: VersionHolder.versions.keys.length,
      itemBuilder: (context, index) {
        String version = VersionHolder.versions.keys.elementAt(index);
        String? description = VersionHolder.getVersionInfo(version);
        description ??= "";

        bool selected =
            VersionManager.compareVersions(widget.lastUsedVersion, version) ==
                -1;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            selected: selected,
            titleTextStyle: Theme.of(context).textTheme.titleLarge,
            title: Text(
              version,
            ),
            subtitle: Text(description),
          ),
        );
      },
    );
  }

  Future<void> _updateVersionsToShow() async {
    versionsToShow.clear();

    for (int i = 0; i < VersionHolder.versions.keys.length; i++) {
      String version = VersionHolder.versions.keys.elementAt(i);
      final compareedVersions =
          VersionManager.compareVersions(widget.lastUsedVersion, version);

      if (compareedVersions < 0) {
        String? description = VersionHolder.getVersionInfo(version);

        if (description == null) continue;

        versionsToShow.add((version, description));
      }
    }

    if (mounted) {
      setState(() {});
    }
  }
}
