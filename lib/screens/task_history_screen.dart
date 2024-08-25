import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/task.dart';
import '../theme/light_colors.dart';
import 'package:intl/intl.dart';

class TaskHistoryScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  final String userId;

  TaskHistoryScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Tarefas'),
        backgroundColor: LightColors.kBlue,
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firestoreService.getTasks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhuma tarefa disponível.'));
          }

          List<Task> allTasks = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: allTasks.length,
            itemBuilder: (context, index) {
              Task task = allTasks[index];
              String formattedDate;

              try {
                DateTime taskDate = DateFormat('dd/MM/yyyy').parse(task.date);
                formattedDate = DateFormat('dd/MM/yyyy').format(taskDate);
              } catch (e) {
                formattedDate = task.date;
              }

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(15.0),
                  leading: CircleAvatar(
                    backgroundColor: task.isCompleted ? LightColors.kGreen : LightColors.kRed,
                    child: Icon(
                      task.isCompleted ? Icons.check : Icons.error,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text(
                        'Data: $formattedDate',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Concluída: ${task.isCompleted ? "Sim" : "Não"}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: task.isCompleted ? LightColors.kGreen : LightColors.kRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
