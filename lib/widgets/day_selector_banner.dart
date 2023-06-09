import 'package:classschedule_app/blocs/schedule_bloc/schedule_bloc.dart';
import 'package:classschedule_app/Widgets/week_day_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/settings_bloc/settings_bloc.dart';

class DaySelectorBanner extends StatelessWidget {
  DaySelectorBanner({Key? key}) : super(key: key);

  List<WeekDayBox> _generateBoxes(String lang) {
    bool first = true;
    List<WeekDayBox>? boxes = [];
    DateTime date = DateTime.now();

    for (int i = 0; i < 7; i++) {
      if (first) {
        boxes.add(WeekDayBox(date));
        first = false;
      } else {
        date = date.add(Duration(days: 1));
        boxes.add(WeekDayBox(date));
      }
    }

    return boxes;
  }

  @override
  Widget build(BuildContext context) {
    final settingsBloc = BlocProvider.of<SettingsBloc>(context);
    final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);

    return BlocBuilder<ScheduleBloc, ScheduleState>(
        bloc: scheduleBloc,
        buildWhen: (previous, current) => false,
        builder: (BuildContext context, ScheduleState schState) {
          return BlocBuilder(
            buildWhen: (current, previous) => false,
            bloc: settingsBloc,
            builder: (BuildContext context, SettingsState state) {
              return Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _generateBoxes(state.settings.langID),
                    )
                  ],
                ),
              );
            },
          );
        });
  }
}
