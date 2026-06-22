// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/projections_repository.dart';
// DOMAIN
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
import 'package:finance_calendar/domain/use_cases/helpers.dart';
import '../../domain/models/projection.dart';
// UI
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final ProjectionsRepository projectionsRepo;
  final GenerateProjectionsUseCase generateProjections;
  const CalendarPage({
    super.key,
    required this.projectionsRepo,
    required this.generateProjections,
  });

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  bool loading = true;
  DateTime selectedDay = DateTime.now();
  Projection? projectionForDay;
  List<Projection> projectionsForMonth = [];
  Map<String,Projection> projectionsForMonthByDate = {};

  @override
  void initState(){
    super.initState();
    loadProjectionsForDay(); // async
  }

  Future<void> loadProjectionsForDay() async {
    final forMonth = await widget.projectionsRepo.getForDateRange(startOfMonth(selectedDay), startOfNextMonth(selectedDay));
    final byDate = mapReadOnlyProjectionsByDateString(forMonth);
    final forDay = byDate[dateToStringForDB(selectedDay)];
    setState((){
      projectionForDay = forDay;
      projectionsForMonth = forMonth;
      projectionsForMonthByDate = byDate;
      loading = false;
    });
  }

  /* If day in calendar is selected day: then highlight it */
  bool selectedDayPredicate(DateTime day){
    return isSameDay(selectedDay, day);
  }

  /* If day not in projection range, gray out (disable) */
  bool enabledDayPredicate(DateTime day){
    return projectionsForMonthByDate[dateToStringForDB(day)] != null;
  }

  /* If day considered holiday, circle it */
  bool holidayPredicate(DateTime day){
    return false;
  }

  /* When selecting new day */
  void onDaySelected(DateTime selected, DateTime _) async { 
    var dateString = dateToStringForDB(selected);
    final projection = projectionsForMonthByDate[dateString];
    setState(() { 
      selectedDay = selected;
      projectionForDay = projection;
    });
  }

  /* When selecting new month */
  void onPageChanged(DateTime day) async {
    setState((){
      selectedDay = day;
    });
    await loadProjectionsForDay(); // async
  }

  /* If day in calendar has events, mark it with a graphic */
  List<String> eventLoader(DateTime day) {
    return projectionsForMonthByDate[dateToStringForDB(day)]?.transactionProjectionStrings ?? [];
  }

  @override
  Widget build(BuildContext context) {

    final circleWaiting = const Center(child: CircularProgressIndicator());
    final bodyForDay = ListView(children: [ ListTile(title: Text(projectionForDay?.toString() ?? "")) ]);
    final indexedStack = IndexedStack(index: loading ? 0 : 1, children: [ circleWaiting, bodyForDay ]);

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: selectedDay,
          availableCalendarFormats: const { CalendarFormat.month: 'Month' }, // disables 2 weeks / week
          selectedDayPredicate: selectedDayPredicate,   //
          enabledDayPredicate: enabledDayPredicate,     // grays out day, preventing selection
          holidayPredicate: holidayPredicate,           // places circle around date
          onDaySelected: onDaySelected,
          eventLoader: eventLoader,                     // Places a dot under date
          onPageChanged: onPageChanged,
        ),
        Expanded(
          child: indexedStack,
        ),
      ],
    );
  }
}