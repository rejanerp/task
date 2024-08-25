import 'package:flutter/material.dart';
import '../dates_list.dart';
import '../theme/light_colors.dart';
import '../widgets/calendar_dates.dart';
import '../widgets/task_container.dart';
import '../screens/create_new_task_page.dart';
import '../widgets/back_button.dart';
import '../services/firestore_service.dart';
import '../models/task.dart';

class CalendarPage extends StatefulWidget {
  final String userId;

  CalendarPage({required this.userId});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String? selectedDate;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now().day.toString().padLeft(2, '0');
  }

  Widget buildTaskListForSelectedDate(String selectedDate) {
    return StreamBuilder<List<Task>>(
      stream: _firestoreService.getTasks(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Nenhuma tarefa disponível para este dia'));
        }

        List<Task> tasks = snapshot.data!;
        List<Task> filteredTasks = tasks.where((task) {
          String fullSelectedDate = '${selectedDate.padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';
          return task.date == fullSelectedDate;
        }).toList();

        if (filteredTasks.isEmpty) {
          return Center(child: Text('Nenhuma tarefa disponível para este dia'));
        }

        return Column(
          children: filteredTasks.map((task) {
            final startTime = TimeOfDay(
              hour: int.parse(task.startTime.split(':')[0]),
              minute: int.parse(task.startTime.split(':')[1]),
            );
            final endTime = TimeOfDay(
              hour: int.parse(task.endTime.split(':')[0]),
              minute: int.parse(task.endTime.split(':')[1]),
            );

            final startOffset = (startTime.hour * 60 + startTime.minute) / 1440;
            final endOffset = (endTime.hour * 60 + endTime.minute) / 1440;

            final topPosition = startOffset * MediaQuery.of(context).size.height;
            final height = (endOffset - startOffset) * MediaQuery.of(context).size.height;

            return Container(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: getTaskColor(task),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    task.description ?? '',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color getTaskColor(Task task) {
    List<Color> colors = [
      LightColors.kLightYellow2,
      LightColors.kLavender,
      LightColors.kPalePink,
      LightColors.kLightGreen,
      LightColors.kBlue,
    ];

    int colorIndex = task.id.hashCode % colors.length;
    return colors[colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    List<String> days = getCurrentWeekDays();
    List<String> dates = getCurrentWeekDates();
    String todayDate = DateTime.now().day.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: LightColors.kLightYellow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: <Widget>[
              MyBackButton(),
              SizedBox(height: 30.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Hoje',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    height: 40.0,
                    width: 120,
                    decoration: BoxDecoration(
                      color: LightColors.kGreen,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateNewTaskPage(),
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          'Adicionar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Dia Produtivo',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Agosto, 2024',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Container(
                height: 58.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  itemBuilder: (BuildContext context, int index) {
                    String day = dates[index].padLeft(2, '0');
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = dates[index];
                        });
                      },
                      child: CalendarDates(
                        day: days[index],
                        date: dates[index],
                        dayColor: day == todayDate ? LightColors.kRed : Colors.black54,
                        dateColor: selectedDate == dates[index]
                            ? LightColors.kRed
                            : LightColors.kDarkBlue,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: ListView.builder(
                            itemCount: 24,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${index}:00',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          flex: 5,
                          child: selectedDate != null
                              ? buildTaskListForSelectedDate(selectedDate!)
                              : Center(child: Text('Selecione uma data')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
