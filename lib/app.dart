import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:schulapp/code_behind/notification_manager.dart';
import 'package:schulapp/code_behind/settings.dart';
import 'package:schulapp/code_behind/timetable_manager.dart';
import 'package:schulapp/code_behind/todo_event.dart';
import 'package:schulapp/code_behind/utils.dart';
import 'package:schulapp/code_behind/version_manager.dart';
import 'package:schulapp/home_widget/home_widget_manager.dart';
import 'package:schulapp/l10n/app_localizations_manager.dart';
import 'package:schulapp/l10n/generated/app_localizations.dart';
import 'package:schulapp/screens/abi_calculation_screen.dart';
import 'package:schulapp/screens/timetables_screen.dart';
import 'package:schulapp/screens/grades_screen.dart';
import 'package:schulapp/screens/hello_screen.dart';
import 'package:schulapp/screens/holidays_screen.dart';
import 'package:schulapp/screens/notes_screen.dart';
import 'package:schulapp/screens/todo_events_screen.dart';
import 'package:schulapp/screens/settings_screen.dart';
import 'package:schulapp/screens/home_screen.dart';
import 'package:schulapp/theme/theme_manager.dart';
import 'package:schulapp/theme/themes.dart';
import 'package:schulapp/widgets/click_me_widget.dart';
import 'package:schulapp/widgets/custom_bottom_navigation_bar.dart';

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          AppLocalizationsManager.setLocalizations(localizations);
        }

        final showBottomNavBar = Utils.isMobileRatio(context) &&
            !VersionManager().isFirstTimeOpening();

        return ValueListenableBuilder<bool>(
          valueListenable: MainApp.showBottomnavBar,
          builder: (context, value, _) {
            return Material(
              child: Scaffold(
                backgroundColor: Theme.of(context).canvasColor,
                body: ClickMeWidget.enabled
                    ? ClickMeWidget(
                        child: child,
                      )
                    : Center(
                        child: child,
                      ),
                bottomNavigationBar: showBottomNavBar && value
                    ? CustomBottomNavigationBar(
                        currRoute: state.fullPath ?? "",
                      )
                    : null,
              ),
            );
          },
        );
      },
      routes: [
        GoRoute(
          path: HomeScreen.route,
          builder: (context, state) => HomeScreen(
            title: AppLocalizationsManager.localizations.strStartScreen,
            timetable: Utils.getHomescreenTimetable(),
            isHomeScreen: true,
          ),
        ),
        GoRoute(
          path: TimetablesScreen.route,
          builder: (context, state) => const TimetablesScreen(),
        ),
        GoRoute(
          path: GradesScreen.route,
          builder: (context, state) => const GradesScreen(),
        ),
        GoRoute(
          path: TodoEventsScreen.route,
          builder: (context, state) => TodoEventsScreen(
            todoEvent: state.extra as TodoEvent?,
          ),
        ),
        GoRoute(
          path: HolidaysScreen.route,
          builder: (context, state) => const HolidaysScreen(),
        ),
        GoRoute(
          path: SettingsScreen.route,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: HelloScreen.route,
          builder: (context, state) => const HelloScreen(),
        ),
        GoRoute(
          path: NotesScreen.route,
          builder: (context, state) => const NotesScreen(),
        ),
        GoRoute(
          path: AbiCalculationScreen.route,
          builder: (context, state) => const AbiCalculationScreen(),
        ),
      ],
    ),
  ],
);

class MainApp extends StatefulWidget {
  static ValueNotifier<bool> showBottomnavBar = ValueNotifier<bool>(true);
  static GoRouter get router => _router;

  ///secure just means that only the current screen can update the visibility
  static void changeNavBarVisibilitySecure(
    BuildContext context, {
    required bool value,
  }) {
    if (Utils.isScreenOnTop(context)) {
      changeNavBarVisibility(value);
    }
  }

  static void changeNavBarVisibility(bool value) {
    Future.delayed(Duration.zero, () {
      showBottomnavBar.value = value;
    });
  }

  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();

  static void setLocale(BuildContext context, Locale? newLocale) {
    _MainAppState? state = context.findAncestorStateOfType<_MainAppState>();
    state?.setLocale(newLocale);
  }
}

class _MainAppState extends State<MainApp> {
  Locale? _locale;

  void setLocale(Locale? newLocale) {
    _locale = newLocale;
    TimetableManager().settings.setVar(
          Settings.languageCodeKey,
          _locale?.languageCode,
        );

    setState(() {});
  }

  void themeListener() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    ThemeManager().addListener(themeListener);

    if (TimetableManager().settings.getVar(Settings.languageCodeKey) != null) {
      setLocale(
        Locale(TimetableManager().settings.getVar(Settings.languageCodeKey)!),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback(postFrameCallback);

    _registerLessonNotification();

    super.initState();
  }

  @override
  void dispose() {
    ThemeManager().removeListener(themeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      debugShowCheckedModeBanner: true,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeManager().themeMode,
      routerConfig: _router,
    );
  }

  Future<void> postFrameCallback(Duration timeStamp) async {
    if (NotificationManager().pendingNotification) {
      NotificationManager().handlePendingNotification();
    }

    await HomeWidgetManager.initialize();

    if (!mounted) return;
    await HomeWidgetManager.updateWithDefaultTimetable(context: context);
  }

  Future<void> _registerLessonNotification() async {
    final registerNotification = TimetableManager().settings.getVar<bool>(
          Settings.lessonReminderNotificationEnabledKey,
        );

    if (!registerNotification) {
      return;
    }

    final timetable = Utils.getHomescreenTimetable();

    if (timetable == null) {
      return;
    }

    final timeBeforeLessonNotification =
        TimetableManager().settings.getVar<Duration>(
              Settings.preLessonReminderNotificationDurationKey,
            );

    NotificationManager().scheduleNotificationForTimetable(
      timetable: timetable,
      timeBeforeLessonNotification: timeBeforeLessonNotification,
    );
  }
}
