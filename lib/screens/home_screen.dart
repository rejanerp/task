import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_new_task_page.dart';
import 'calendar_page.dart';
import '../services/firestore_service.dart';
import '../models/task.dart';
import '../theme/light_colors.dart';
import '../widgets/top_container.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../widgets/task_column.dart';
import 'package:intl/intl.dart';
import 'VirtualAssistantScreen.dart';
import 'user_profile_screen.dart';
import 'task_history_screen.dart';
class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? userName;
  String? userRole;
  String? userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? 'Seu Nome';
          userRole = userDoc['role'] ?? 'Seu Cargo';
          userPhotoUrl = userDoc['photoURL'];
        });
      }
    } catch (e) {
      print("Erro ao carregar perfil: $e");
    }
  }

  

  Text subheading(String title) {
    return Text(
      title,
      style: TextStyle(
        color: LightColors.kDarkBlue,
        fontSize: 20.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  static CircleAvatar calendarIcon(BuildContext context, String userId) {
    return CircleAvatar(
      radius: 25.0,
      backgroundColor: LightColors.kGreen,
      child: IconButton(
        icon: Icon(
          Icons.calendar_today,
          size: 20.0,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarPage(userId: userId),
            ),
          );
        },
      ),
    );
  }

  static CircleAvatar addTaskIcon(BuildContext context) {
    return CircleAvatar(
      radius: 25.0,
      backgroundColor: LightColors.kBlue,
      child: IconButton(
        icon: Icon(
          Icons.add,
          size: 25.0,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNewTaskPage(),
            ),
          );
        },
      ),
    );
  }

  static CircleAvatar assistantIcon(BuildContext context) {
    return CircleAvatar(
      radius: 25.0,
      backgroundColor: LightColors.kRed,
      child: IconButton(
        icon: Icon(
          Icons.mic,
          size: 25.0, // Tamanho do ícone ajustado para 25.0 para manter consistência
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VirtualAssistantScreen(),
            ),
          );
        },
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'To Do':
        return LightColors.kRed;
      case 'In Progress':
        return LightColors.kBlue;
      case 'Done':
        return LightColors.kGreen;
      default:
        return LightColors.kPalePink;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'To Do':
        return Icons.radio_button_checked;
      case 'In Progress':
        return Icons.autorenew;
      case 'Done':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Widget buildTaskList(BuildContext context, List<Task> tasks) {
  String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
  List<Task> filteredTasks = tasks.where((task) => task.date == today).toList();

  if (filteredTasks.isEmpty) {
    return Center(child: Text('Nenhuma tarefa disponível para hoje'));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: filteredTasks.map((task) {
      return GestureDetector(
        onTap: () => _showStatusDialog(context, task),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TaskColumn(
                  icon: getStatusIcon(task.status),
                  iconBackgroundColor: getStatusColor(task.status),
                  title: task.title,
                  subtitle: task.description ?? 'Sem descrição',
                  taskId: task.id,
                  status: task.status,
                  onChangeStatus: (String newStatus) {
                    _firestoreService.updateTaskStatus(task.id, newStatus);
                    if (newStatus == 'Done') {
                      _firestoreService.updateTaskProgress(task.id, 1.0);
                    } else if (newStatus == 'In Progress') {
                      _firestoreService.updateTaskProgress(task.id, 0.5);
                    } else {
                      _firestoreService.updateTaskProgress(task.id, 0.0);
                    }
                    (context as Element).markNeedsBuild();
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteTask(context, task),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}
  Widget buildActiveProjectsSection(BuildContext context, List<Task> tasks) {
    String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    List<Task> todayTasks = tasks.where((task) => task.date == today).toList();

    if (todayTasks.isEmpty) {
      return Center(child: Text('Nenhuma tarefa disponível para hoje.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        subheading('Tarefas para Hoje'),
        SizedBox(height: 10.0),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: todayTasks.length,
          itemBuilder: (context, index) {
            double progress = todayTasks[index].progress;
            Color color = getStatusColor(todayTasks[index].status);
            return GestureDetector(
              onTap: () => _showProgressDialog(context, todayTasks[index]),
              child: buildProjectCard(context, todayTasks[index], progress, color),
            );
          },
        ),
      ],
    );
  }

  Widget buildProjectCard(BuildContext context, Task task, double progress, Color color) {
    String timeRange = "${task.startTime} - ${task.endTime}";
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedCircularProgressIndicator(progress: progress, color: color),
          SizedBox(height: 10.0),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            timeRange,
            style: TextStyle(
              fontSize: 14.0,
              color: color,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Alterar Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['To Do', 'In Progress', 'Done'].map((status) {
              return ListTile(
                title: Text(status),
                onTap: () {
                  _firestoreService.updateTaskStatus(task.id, status);
                  if (status == 'Done') {
                    _firestoreService.updateTaskProgress(task.id, 1.0);
                  } else if (status == 'In Progress') {
                    _firestoreService.updateTaskProgress(task.id, 0.5);
                  } else {
                    _firestoreService.updateTaskProgress(task.id, 0.0);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status atualizado para $status')),
                  );
                  (context as Element).markNeedsBuild();
                },
              );
            }).toList(),
          ),
        );
      },
    ).then((_) {
      (context as Element).markNeedsBuild();
    });
  }

  void _showProgressDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) {
        double progressValue = task.progress;
        TextEditingController controller = TextEditingController(
            text: (progressValue * 100).toInt().toString());

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Definir Progresso'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: progressValue,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: '${(progressValue * 100).toInt()}%',
                    onChanged: (newValue) {
                      setState(() {
                        progressValue = newValue;
                        controller.text = (progressValue * 100).toInt().toString();
                      });
                    },
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Progresso (%)",
                    ),
                    onChanged: (value) {
                      int? intValue = int.tryParse(value);
                      if (intValue != null && intValue >= 0 && intValue <= 100) {
                        setState(() {
                          progressValue = intValue / 100;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 8.0),
                  Text('${(progressValue * 100).toInt()}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    _firestoreService.updateTaskProgress(task.id, progressValue);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Progresso atualizado')),
                    );
                    (context as Element).markNeedsBuild();
                  },
                  child: Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      (context as Element).markNeedsBuild();
    });
  }

  void _confirmDeleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Excluir Tarefa'),
          content: Text('Você tem certeza que deseja excluir esta tarefa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestoreService.deleteTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tarefa excluída com sucesso')),
                  );
                  Navigator.of(context).pop();
                  (context as Element).markNeedsBuild();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir tarefa: $e')),
                  );
                }
              },
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: LightColors.kBlue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/avatar.jpg'),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Seu Nome',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Seu Cargo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Perfil do Usuário'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Histórico de Tarefas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskHistoryScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: LightColors.kLightYellow,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TopContainer(
                height: MediaQuery.of(context).size.height * 0.35,
                width: width,
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Builder(
                          builder: (context) {
                            return IconButton(
                              icon: Icon(
                                Icons.menu,
                                color: LightColors.kDarkBlue,
                                size: 30.0,
                              ),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            );
                          },
                        ),
                        Row(
                          children: [
                            calendarIcon(context, widget.userId),
                            SizedBox(width: 10),
                            addTaskIcon(context),
                            SizedBox(width: 10),
                            assistantIcon(context),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          CircularPercentIndicator(
                            radius: 80.0,
                            lineWidth: 8.0,
                            animation: true,
                            percent: 0.75,
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: LightColors.kRed,
                            backgroundColor: LightColors.kDarkYellow,
                            center: CircleAvatar(
                              backgroundColor: LightColors.kBlue,
                              radius: 35.0,
                              backgroundImage: AssetImage(
                                'assets/images/avatar.jpg',
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                userName ?? 'Seu Nome',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 22.0,
                                  color: LightColors.kDarkBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                userRole ?? 'Seu Cargo',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    StreamBuilder<List<Task>>(
                      stream: _firestoreService.getTasks(widget.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Erro: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('Nenhuma tarefa disponível'));
                        }

                        List<Task> tasks = snapshot.data!;

                        return Column(
                          children: <Widget>[
                            buildTaskList(context, tasks),
                            SizedBox(height: 15.0),
                            buildActiveProjectsSection(context, tasks),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedCircularProgressIndicator extends StatelessWidget {
  final double progress;
  final Color color;

  const AnimatedCircularProgressIndicator({
    Key? key,
    required this.progress,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: progress),
      duration: Duration(seconds: 1),
      builder: (context, double value, _) {
        return CircularPercentIndicator(
          radius: 40.0,
          lineWidth: 5.0,
          animation: false,
          percent: value,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: color,
          backgroundColor: Colors.grey.shade200,
          center: Text(
            "${(value * 100).toInt()}%",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
