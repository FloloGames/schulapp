import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';
import 'package:schulapp/screens/grades_screen.dart';
import 'package:schulapp/screens/notes_screen.dart';
import 'package:schulapp/screens/todo_events_screen.dart';
import 'package:schulapp/screens/home_screen.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final String currRoute;
  const CustomBottomNavigationBar({super.key, required this.currRoute});

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  final List<String> pageRoutes = [
    GradesScreen.route,
    HomeScreen.route,
    TodoEventsScreen.route,
  ];

  int _getCurrentIndex() {
    for (int i = 0; i < pageRoutes.length; i++) {
      if (pageRoutes[i] == widget.currRoute) {
        return i;
      }
    }

    const defaultIndex = 1;

    return defaultIndex;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        context.go(NotesScreen.route);
      },
      child: BottomNavigationBar(
        currentIndex: _getCurrentIndex(),
        onTap: (value) {
          context.go(pageRoutes[value]);
          setState(() {});
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.school_outlined),
            activeIcon: const Icon(Icons.school),
            label: AppLocalizationsManager.localizations.strGrades,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalizationsManager.localizations.strStartScreen,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_outlined),
            activeIcon: const Icon(Icons.assignment),
            label: AppLocalizationsManager.localizations.strTasks,
          ),
        ],
      ),
    );
  }
}


// ? NavigationBar(
              //     destinations: const [
              //       NavigationDestination(
              //         icon: Icon(Icons.home),
              //         label: "Home",
              //       ),
              //       NavigationDestination(
              //         icon: Icon(Icons.home),
              //         label: "Grades",
              //       ),
              //       NavigationDestination(
              //         icon: Icon(Icons.check),
              //         label: "Tasks",
              //       ),
              //     ],
              //   )