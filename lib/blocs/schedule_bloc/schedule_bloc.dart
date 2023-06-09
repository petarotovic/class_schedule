import 'package:classschedule_app/Services/date_service.dart';
import 'package:classschedule_app/Services/utility.dart';
import 'package:classschedule_app/constants/words.dart';
import 'package:classschedule_app/models/subject_model.dart';
import 'package:classschedule_app/services/notifications_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../Services/database_service.dart';
import '../../models/homework_model.dart';

part 'schedule_events.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc()
      : super(
          ScheduleState.init(
            currentDate: DateTime.now(),
            selectedWeek: 1,
            numberOfWeeks: 1,
            subjects: [],
          ),
        ) {
    on<ChangeDate>((event, emit) => _setNewDate(event, emit));
    on<InitSchedule>((event, emit) => _initSettings(event, emit));
    on<AddNewSubject>((event, emit) => _addSubject(event, emit));
    on<AddNewHomework>((event, emit) => _addNewHomework(event, emit));
    on<ChangeWeekNumber>((event, emit) => _changeNumberOfWeeks(event, emit));
    on<ChangeSelectedWeek>((event, emit) => _changeSelectedWeek(event, emit));
    on<DeleteHomework>((event, emit) => _deleteHomework(event, emit));
    on<ChangeHomework>((event, emit) => _changeHomework(event, emit));
    on<ChangeSubject>((event, emit) => _changeSubject(event, emit));
    on<MarkHomeworkComplete>(
        (event, emit) => _markHomeWorkComplete(event, emit));
    on<RemoveSubject>((event, emit) => _removeSubject(event, emit));
    add(InitSchedule());
  }

  Future<void> _changeSubject(
      ChangeSubject event, Emitter<ScheduleState> emit) async {
    try {
      String path = await DatabaseService.getStoragePath();

      List<dynamic> subjectDb = await DatabaseService.initDatabase(
        path,
        "class_schedule",
      );

      await DatabaseService.executeQuery(
        subjectDb[1],
        "UPDATE class_schedule SET subjectID = '${event.subject.subjectID}', subjectName = '${event.subject.nameOfSubject}', professor = '${event.subject.professorName}', classroom = '${event.subject.classroom}', color = '${UtilityService.encodeColor(event.subject.color)}', week = ${event.subject.week}, day = ${event.subject.day}, startTime = '${UtilityService.encodeTime(event.subject.startTime)}', endTime = '${UtilityService.encodeTime(event.subject.endTime)}' WHERE id = ${event.subject.uniqueID}",
      );

      await DatabaseService.executeQuery(
        subjectDb[1],
        "UPDATE class_schedule SET subjectID = '${event.subject.subjectID}', subjectName = '${event.subject.nameOfSubject}', color = '${UtilityService.encodeColor(event.subject.color)}' WHERE subjectID = '${event.oldID}'",
      );

      add(InitSchedule());
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> _removeSubject(
      RemoveSubject event, Emitter<ScheduleState> emit) async {
    String path = await DatabaseService.getStoragePath();

    List<dynamic> homeworkDb = await DatabaseService.initDatabase(
      path,
      "class_schedule",
    );

    await DatabaseService.executeQuery(
        homeworkDb[1], "DELETE FROM class_schedule WHERE id = ${event.id}");

    add(InitSchedule());
  }

  Future<void> _markHomeWorkComplete(
      MarkHomeworkComplete event, Emitter<ScheduleState> emit) async {
    String path = await DatabaseService.getStoragePath();

    List<dynamic> homeworkDb = await DatabaseService.initDatabase(
      path,
      "homeworks",
    );

    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService().init();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.cancel(event.homeworkID);

    await DatabaseService.executeQuery(homeworkDb[1],
        "UPDATE homeworks SET completed = '${UtilityService.encodeBool(true)}' WHERE id = ${event.homeworkID}");

    add(InitSchedule());
  }

  Future<void> _changeHomework(
      ChangeHomework event, Emitter<ScheduleState> emit) async {
    String path = await DatabaseService.getStoragePath();

    List<dynamic> homeworkDb = await DatabaseService.initDatabase(
      path,
      "homeworks",
    );

    await DatabaseService.executeQuery(
      homeworkDb[1],
      "UPDATE homeworks SET subjectID = '${event.homework.id}', name = '${event.homework.name}', description = '${event.homework.description}', duedate = '${DateService.encodeDate(event.homework.dueDate)}', completed = '${UtilityService.encodeBool(event.homework.completed)}' WHERE id = ${event.homework.uniqueID}",
    );
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService().init();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      "noti_channel_title",
      "noti_channel_desc",
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .cancel(event.homework.uniqueID as int);

    print(event.homework.dueDate.subtract(Duration(hours: 8)));

    await flutterLocalNotificationsPlugin.schedule(
        event.homework.uniqueID as int,
        "${event.subject.nameOfSubject}",
        "${homeworkTomorow[event.langID]}",
        event.homework.dueDate.subtract(Duration(hours: 8)),
        const NotificationDetails(
            android: AndroidNotificationDetails("a", "a")),
        androidAllowWhileIdle: true);

    add(InitSchedule());
  }

  Future<void> _deleteHomework(
      DeleteHomework event, Emitter<ScheduleState> emit) async {
    try {
      print(event.homeworkID);
      String path = await DatabaseService.getStoragePath();

      List<dynamic> homeworkDb =
          await DatabaseService.initDatabase(path, "homeworks");

      await DatabaseService.executeQuery(homeworkDb[1],
          "DELETE FROM homeworks WHERE id = ${event.homeworkID}");

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin.cancel(event.homeworkID);

      add(InitSchedule());
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> _setNewDate(
      ChangeDate event, Emitter<ScheduleState> emit) async {
    emit(ScheduleState.init(
        currentDate: event.newDate,
        subjects: state.subjects,
        numberOfWeeks: state.numberOfWeeks,
        selectedWeek: state.selectedWeek));
  }

  Future<void> _addNewHomework(
      AddNewHomework event, Emitter<ScheduleState> emit) async {
    Homework homework = event.homework;
    String path = await DatabaseService.getStoragePath();

    List<dynamic> homeworkDb =
        await DatabaseService.initDatabase(path, "homeworks");

    await DatabaseService.runInsertQuery(
      homeworkDb[1],
      "INSERT INTO homeworks (subjectID, name, description, dueDate, completed) VALUES ('${homework.id}', '${homework.name}', '${homework.description}', '${DateService.encodeDate(homework.dueDate)})', '${UtilityService.encodeBool(homework.completed)}')",
    );

    List<Map<dynamic, dynamic>> homeworkID = await DatabaseService.executeQuery(
        homeworkDb[1], "SELECT * FROM homeworks");

    homework = Homework(
      uniqueID: homeworkID.last['id'],
      id: homework.id,
      name: homework.name,
      description: homework.description,
      dueDate: homework.dueDate,
      completed: homework.completed,
    );

    List<Subject> newList = [];
    late Subject? chosen;

    for (var element in state.subjects) {
      List<Homework> copy = [];

      for (var homework in element.homeworks) {
        copy.add(homework);
      }

      newList.add(
        Subject(
          uniqueID: element.uniqueID,
          subjectID: element.subjectID,
          nameOfSubject: element.nameOfSubject,
          professorName: element.professorName,
          classroom: element.classroom,
          color: element.color,
          day: element.day,
          week: element.week,
          startTime: element.startTime,
          endTime: element.endTime,
          homeworks: copy,
        ),
      );

      if (newList.last.subjectID == event.homework.id) {
        newList.last.homeworks.add(homework);
        chosen = newList.last;
      }
    }

    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService().init();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      "noti_channel_title",
      "noti_channel_desc",
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // await flutterLocalNotificationsPlugin.show(
    //     12, "p", "p", platformChannelSpecifics);
    // tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.schedule(
        homework.uniqueID as int,
        "${chosen != null ? chosen.nameOfSubject : "Homework"}",
        "${homeworkTomorow[event.lang]}",
        homework.dueDate.subtract(Duration(hours: 8)),
        const NotificationDetails(
            android: AndroidNotificationDetails("a", "a")),
        androidAllowWhileIdle: true);

    emit(
      ScheduleState.init(
        currentDate: state.currentDate,
        selectedWeek: state.selectedWeek,
        numberOfWeeks: state.numberOfWeeks,
        subjects: newList,
      ),
    );
  }

  Future<void> _addSubject(
      AddNewSubject event, Emitter<ScheduleState> emit) async {
    Subject subject = event.subject;
    String path = await DatabaseService.getStoragePath();
    List<dynamic> dbStatus =
        await DatabaseService.initDatabase(path, "class_schedule");

    await DatabaseService.runInsertQuery(
      dbStatus[1],
      "INSERT INTO class_schedule (subjectID, subjectName, professor, classroom, color, week, day, startTime, endTime) VALUES ('${subject.subjectID}', '${subject.nameOfSubject}', '${subject.professorName}', '${subject.classroom}', '${UtilityService.encodeColor(subject.color)}', ${subject.week}, ${subject.day}, '${UtilityService.encodeTime(subject.startTime)}', '${UtilityService.encodeTime(subject.endTime)}')",
    );

    List<Map<dynamic, dynamic>> newID = await DatabaseService.executeQuery(
        dbStatus[1],
        "SELECT * FROM class_schedule WHERE subjectID = '${subject.subjectID}'");

    List<dynamic> homeworkStatus =
        await DatabaseService.initDatabase(path, "homeworks");

    List<Map<dynamic, dynamic>> result = await DatabaseService.executeQuery(
        homeworkStatus[1],
        "SELECT * FROM homeworks WHERE subjectID = '${subject.subjectID}'");

    List<Subject> newList = [];

    for (var element in state.subjects) {
      newList.add(element);
    }

    for (var homework in result) {
      subject.homeworks.add(
        Homework(
          uniqueID: homework['id'],
          id: homework['subjectID'],
          name: homework['name'],
          description: homework['description'],
          dueDate: DateService.decodeDate(homework['duedate']),
          completed: UtilityService.decodeBool(homework['completed']),
        ),
      );
    }

    newList.add(
      Subject(
          uniqueID: newID.last['id'],
          subjectID: subject.subjectID,
          nameOfSubject: subject.nameOfSubject,
          professorName: subject.professorName,
          classroom: subject.classroom,
          color: subject.color,
          day: subject.day,
          week: subject.week,
          startTime: subject.startTime,
          endTime: subject.endTime,
          homeworks: subject.homeworks),
    );

    emit(
      ScheduleState.init(
        currentDate: state.currentDate,
        selectedWeek: state.selectedWeek,
        numberOfWeeks: state.numberOfWeeks,
        subjects: newList,
      ),
    );
  }

  Future<void> _changeNumberOfWeeks(
      ChangeWeekNumber event, Emitter<ScheduleState> emit) async {
    String path = await DatabaseService.getStoragePath();

    List<dynamic> weekDb = await DatabaseService.initDatabase(path, "week");

    await DatabaseService.executeQuery(
        weekDb[1], "UPDATE week SET week = ${event.newWeek} WHERE id = 2");

    if (event.newWeek == 1) {
      print(event.newWeek);
      List<dynamic> homeworkDb = await DatabaseService.initDatabase(
        path,
        "class_schedule",
      );

      await DatabaseService.executeQuery(
          homeworkDb[1], "DELETE FROM class_schedule WHERE week > 1");

      await DatabaseService.executeQuery(
          weekDb[1], "UPDATE week SET week = ${event.newWeek} WHERE id = 1");
    }

    add(InitSchedule());
  }

  Future<void> _changeSelectedWeek(
      ChangeSelectedWeek event, Emitter<ScheduleState> emit) async {
    String path = await DatabaseService.getStoragePath();

    List<dynamic> weekDb = await DatabaseService.initDatabase(path, "week");

    List<Map<dynamic, dynamic>> weekFetch = await DatabaseService.executeQuery(
        weekDb[1], "UPDATE week SET week = ${event.newWeek} WHERE id = 1");

    emit(
      ScheduleState.init(
        currentDate: state.currentDate,
        selectedWeek: event.newWeek,
        numberOfWeeks: state.numberOfWeeks,
        subjects: state.subjects,
      ),
    );
  }

  Future<void> _initSettings(
      InitSchedule event, Emitter<ScheduleState> emit) async {
    try {
      String path = await DatabaseService.getStoragePath();
      List<dynamic> scheduleDb =
          await DatabaseService.initDatabase(path, "class_schedule");

      List<dynamic> homeworkDb =
          await DatabaseService.initDatabase(path, "homeworks");

      List<dynamic> weekDb = await DatabaseService.initDatabase(path, "week");

      List<Map<dynamic, dynamic>> list = await DatabaseService.executeQuery(
          scheduleDb[1], "SELECT * FROM class_schedule");

      List<Map<dynamic, dynamic>> homeworkFetch =
          await DatabaseService.executeQuery(
              homeworkDb[1], "SELECT * FROM homeworks");

      List<Map<dynamic, dynamic>> weekFetch =
          await DatabaseService.executeQuery(weekDb[1], "SELECT * FROM week");

      if (weekFetch.isEmpty) {
        await DatabaseService.executeQuery(
            weekDb[1], "INSERT INTO week (week) VALUES (1)");
        await DatabaseService.executeQuery(
            weekDb[1], "INSERT INTO week (week) VALUES (1)");
        weekFetch.add({"week": 1});
        weekFetch.add({"week": 1});
      }

      List<Subject> newList = [];

      list.forEach(
        (element) async {
          List<Homework> homeworksList = [];

          homeworkFetch.forEach(
            (homeworkItem) {
              if (homeworkItem['subjectID'] == element['subjectID']) {
                homeworksList.add(
                  Homework(
                    uniqueID: homeworkItem['id'],
                    id: homeworkItem['subjectID'],
                    name: homeworkItem['name'],
                    description: homeworkItem['description'],
                    dueDate: DateService.decodeDate(homeworkItem['duedate']),
                    completed:
                        UtilityService.decodeBool(homeworkItem['completed']),
                  ),
                );
              }
            },
          );

          newList.add(
            Subject(
              uniqueID: element['id'],
              subjectID: element['subjectID'],
              nameOfSubject: element['subjectName'],
              professorName: element['professor'],
              classroom: element['classroom'],
              color: UtilityService.decodeColor(element['color']),
              day: element['day'],
              week: element['week'],
              startTime: UtilityService.decodeTime(element['startTime']),
              endTime: UtilityService.decodeTime(element['endTime']),
              homeworks: homeworksList,
            ),
          );
        },
      );

      emit(
        ScheduleState.init(
          currentDate: state.currentDate,
          selectedWeek: weekFetch[0]['week'],
          numberOfWeeks: weekFetch[1]['week'],
          subjects: newList,
        ),
      );
    } on Exception catch (e) {
      print(e);
    }
  }
}
