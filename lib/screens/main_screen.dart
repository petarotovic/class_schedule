import 'dart:async';

import 'package:classschedule_app/screens/notifications.dart';
import 'package:classschedule_app/services/utility.dart';
import 'package:classschedule_app/blocs/schedule_bloc/schedule_bloc.dart';
import 'package:classschedule_app/screens/choose_language.dart';
import 'package:classschedule_app/screens/settings.dart';
import 'package:classschedule_app/widgets/day_selector_banner.dart';
import 'package:classschedule_app/widgets/week_selector.dart';
import 'package:classschedule_app/constants/words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../blocs/settings_bloc/settings_bloc.dart';
import '../screens/add_subject.dart';
import '../services/date_service.dart';
import '../widgets/subject_bubble.dart';
import '../models/subject_model.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  Future<void> _checkIsFirstLoad(
      SettingsBloc bloc, BuildContext context) async {
    if (bloc.state.status == loadStatus.firstLoad) {
      await Future.delayed(Duration(seconds: 2));
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ChooseLanguage()));
    }
  }

  List<Widget> _generateWidgets(
    List<Subject> list,
    int week,
    DateTime date,
  ) {
    List<Widget> widgets = [];

    List<List<dynamic>> orderList = [];

    for (var subject in list) {
      if (subject.week == week && subject.day == date.weekday) {
        orderList.add(
          [
            UtilityService.addTimeOfDay(
                    subject.startTime, const TimeOfDay(hour: 0, minute: 0)) *
                -1,
            SubjectBubble(subject: subject)
          ],
        );
      }
    }

    orderList.sort((a, b) => a[0].compareTo(b[0]));

    for (var element in orderList) {
      widgets.add(element[1]);
    }

    return widgets;
  }

  Widget _getWidgets(List<Subject> list, int week, DateTime date,
      BuildContext context, String langID) {
    List<Widget> newList = _generateWidgets(list, week, date);

    if (newList.isEmpty) {
      return Center(
        child: Text(
          noClass[langID]!,
          style: TextStyle(
              color: Theme.of(context).backgroundColor,
              fontWeight: FontWeight.bold),
        ),
      );
    }

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: newList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsBloc = BlocProvider.of<SettingsBloc>(context);
    final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);

    _checkIsFirstLoad(settingsBloc, context);

    return BlocBuilder(
      bloc: scheduleBloc,
      buildWhen: (ScheduleState previous, ScheduleState current) {
        if (previous.currentDate.weekday != current.currentDate.weekday) {
          return true;
        }
        if (previous.subjects.length != current.subjects.length) {
          return true;
        }
        if (previous.selectedWeek != current.selectedWeek) {
          return true;
        }
        if (previous.numberOfWeeks != current.numberOfWeeks) {
          return true;
        }
        for (int i = 0; i < previous.subjects.length; i++) {
          if (previous.subjects[i] != current.subjects[i]) {
            return true;
          }
        }

        return false;
      },
      builder: (BuildContext context, ScheduleState schState) {
        return BlocBuilder(
          bloc: settingsBloc,
          buildWhen: (SettingsState previous, SettingsState current) {
            if (previous.settings.langID != current.settings.langID) {
              return true;
            }
            if (previous.settings.theme != current.settings.theme) {
              return true;
            }
            if (previous.settings.numOfWeeks != current.settings.numOfWeeks) {
              return true;
            }
            return false;
          },
          builder: (BuildContext context, SettingsState state) {
            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                actions: schState.numberOfWeeks != 1
                    ? [
                        WeekSelector(
                            schState.numberOfWeeks, state.settings.langID)
                      ]
                    : [],
                title: Text(
                  DateService.getWeekDayFromNum(
                          schState.currentDate.weekday, state.settings.langID)
                      .toString(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              bottomNavigationBar: BottomAppBar(
                color: Theme.of(context).primaryColor,
                height: MediaQuery.of(context).size.shortestSide * 0.15,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CircularIcon(
                      icon: Icons.add_box_outlined,
                      onTapFunc: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AddSubject()));
                      },
                    ),
                    CircularIcon(
                      icon: Icons.notifications_outlined,
                      onTapFunc: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    CircularIcon(
                      icon: Icons.settings_outlined,
                      onTapFunc: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SettingsScreen()));
                      },
                    ),
                  ],
                ),
              ),
              backgroundColor: Theme.of(context).canvasColor,
              body: Column(
                children: [
                  DaySelectorBanner(),
                  Expanded(
                    child: _getWidgets(schState.subjects, schState.selectedWeek,
                        schState.currentDate, context, state.settings.langID),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class CircularIcon extends StatelessWidget {
  final IconData icon;
  final Function onTapFunc;
  const CircularIcon({required this.icon, required this.onTapFunc, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTapFunc();
      },
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.blue,
      child: Container(
        height: MediaQuery.of(context).size.shortestSide * 0.10,
        width: MediaQuery.of(context).size.shortestSide * 0.10,
        child: Center(
          child: Icon(
            icon,
            color: Theme.of(context).backgroundColor,
          ),
        ),
      ),
    );
  }
}
