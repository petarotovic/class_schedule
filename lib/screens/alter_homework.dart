import 'package:classschedule_app/Blocs/ScheduleBloc/schedule_bloc.dart';
import 'package:classschedule_app/Blocs/SettingsBloc/settings_bloc.dart';
import 'package:classschedule_app/models/homework.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Widgets/input_dialog.dart';
import '../constants/words.dart';

class AlterHomework extends StatefulWidget {
  final Homework homework;
  final String subjectID;
  const AlterHomework(
      {required this.homework, required this.subjectID, Key? key})
      : super(key: key);

  @override
  State<AlterHomework> createState() =>
      _AlterHomeworkState(homework, subjectID);
}

class _AlterHomeworkState extends State<AlterHomework> {
  Homework homework;
  String subjectID;
  late DateTime date;

  _AlterHomeworkState(this.homework, this.subjectID) {
    date = homework.dueDate;
    _setValues();
  }

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  void _setValues() {
    nameController.text = homework.name;
    descriptionController.text = homework.description;
  }

  @override
  Widget build(BuildContext context) {
    SettingsBloc settingsBloc = BlocProvider.of<SettingsBloc>(context);
    ScheduleBloc scheduleBloc = BlocProvider.of<ScheduleBloc>(context);

    return BlocBuilder(
      bloc: settingsBloc,
      builder: (BuildContext context, SettingsState state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(widget.homework.name),
          ),
          body: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                children: [
                  InputDialog(
                    placeholderText: homeworkName[state.settings.langID]!,
                    controller: nameController,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  InputDialog(
                    maxLines: 10,
                    placeholderText: homeworkDesc[state.settings.langID]!,
                    controller: descriptionController,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: double.infinity,
                    height: 50,
                    color: Colors.white12,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "${dueDate[state.settings.langID]!}:",
                          style: TextStyle(
                            color: Theme.of(context).backgroundColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2022),
                              lastDate: DateTime(2030),
                            );

                            setState(() {
                              date = picked!;
                            });
                          },
                          child: Container(
                            width:
                                MediaQuery.of(context).size.shortestSide * 0.6,
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              "${date.day} - ${date.month} - ${date.year}",
                              style: TextStyle(
                                color: Theme.of(context).backgroundColor,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    MediaQuery.of(context).textScaleFactor * 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        scheduleBloc.add(
                          ChangeHomework(
                            Homework(
                                uniqueID: homework.uniqueID,
                                id: homework.id,
                                name: nameController.text,
                                description: descriptionController.text,
                                dueDate: date,
                                completed: homework.completed),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(changeData[state.settings.langID]!),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                      ),
                      onPressed: () {
                        scheduleBloc.add(
                            MarkHomeworkComplete(homework.uniqueID as int));
                        Navigator.of(context).pop();
                      },
                      child: Text(markAsDone[state.settings.langID]!),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red,
                      ),
                      onPressed: () {
                        scheduleBloc.add(
                          DeleteHomework(homework.uniqueID as int),
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(remove[state.settings.langID]!),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}