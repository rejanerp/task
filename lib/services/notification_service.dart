import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import '../models/task.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static void scheduleTaskNotification(Task task) async {
    tz.initializeTimeZones();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Convertendo a data e a hora da tarefa para o tipo DateTime
    DateTime taskDateTime =
        DateFormat('dd/MM/yyyy HH:mm').parse('${task.date} ${task.startTime}');
    
    // Convertendo para TZDateTime
    tz.TZDateTime scheduleDate = tz.TZDateTime.from(taskDateTime, tz.local);

    // Checando se a data agendada não é antes do momento atual
    if (scheduleDate.isBefore(now)) {
      return; // Não agendar a notificação se o horário já passou
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id.hashCode, // Usando o hashCode do ID como ID da notificação
      'Hora de iniciar a tarefa',
      task.title,
      scheduleDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Agendamento com base na hora exata
    );
  }
}
