import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task/screens/create_new_task_page.dart';
import '../theme/theme.dart';
import '../screens/welcome_screen.dart';
import '../screens/signin_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Inicializar Timezone
  tz.initializeTimeZones();

  // Configurar notificações locais
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Solicitar permissões para iOS
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Usuário concedeu permissão para notificações!');
  }

  // Receber token de FCM
  String? token = await messaging.getToken();
  print('Token de FCM: $token');

  // Configurar manipuladores para notificações
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensagem recebida enquanto o app estava em primeiro plano!');
  });

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'task',
      theme: lightMode,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return HomeScreen(userId: args['userId']);
            },
          );
        }

        return null;
      },
      routes: {
        '/' : (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/register': (context) => const SignUpScreen(),
        'newtask': (context) =>  CreateNewTaskPage()
      },
    );
  }
}

// Função para agendar notificações com base nas tarefas
void scheduleTaskNotification(Task task) async {
  final time = task.startTime.split(":");
  final hour = int.parse(time[0]);
  final minute = int.parse(time[1]);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    task.id.hashCode, // Um ID único para cada notificação
    'Lembrete de Tarefa: ${task.title}',
    'Hora de começar: ${task.title}',
    _nextInstanceOfTime(hour, minute),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'task notification channel id', 
        'Task Notifications',
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

// Função para salvar a tarefa e agendar a notificação
void saveTask(Task task) {
  // Código para salvar a tarefa no Firestore
  scheduleTaskNotification(task);
}
