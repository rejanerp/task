import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/light_colors.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class VirtualAssistantScreen extends StatefulWidget {
  @override
  _VirtualAssistantScreenState createState() => _VirtualAssistantScreenState();
}

class _VirtualAssistantScreenState extends State<VirtualAssistantScreen> {
  final TextEditingController _commandController = TextEditingController();
  String _response = '';
  final FirestoreService _firestoreService = FirestoreService();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
  bool available = await _speech.initialize(
    onStatus: (val) => print('onStatus: $val'),
    onError: (val) => print('onError: $val'),
    debugLogging: true,  // This helps with debugging if something goes wrong
  );
  
  if (available) {
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (val) => setState(() {
        _commandController.text = val.recognizedWords;
      }),
      localeId: 'pt_BR',  // Ensure that speech recognition uses Portuguese (Brazil)
    );
  }
}

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _sendCommand() async {
    String command = _commandController.text.trim();

    if (command.isEmpty) {
      return;
    }

    setState(() {
      _response = 'Processando...';
    });

    // Converte termos relativos de data em datas absolutas
    command = _convertRelativeDates(command);

    try {
      await _handleTaskCreation(command);
    } catch (e) {
      setState(() {
        _response = 'Erro ao processar comando: $e';
      });
    }
  }

  String _convertRelativeDates(String command) {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy');

    if (command.contains("hoje")) {
      command = command.replaceAll("hoje", formatter.format(now));
    }

    if (command.contains("amanhã")) {
      final tomorrow = now.add(Duration(days: 1));
      command = command.replaceAll("amanhã", formatter.format(tomorrow));
    }

    if (command.contains("esse sábado")) {
      final nextSaturday = now.add(Duration(days: (6 - now.weekday + 7) % 7));
      command = command.replaceAll("esse sábado", formatter.format(nextSaturday));
    }


    return command;
  }

  Future<void> _handleTaskCreation(String command) async {
  try {
    final String aiResponse = await _fetchGPT4oResponseForTaskCreation(command);

    print('Resposta da API: $aiResponse');

    // Decodificar a resposta JSON
    final Map<String, dynamic> decodedResponse = jsonDecode(aiResponse);
    final String content = decodedResponse['choices'][0]['message']['content'];

    // Extração dos dados com base no conteúdo
    String title = _extractTitle(content);
    String date = _extractDate(content);
    String startTime = _extractStartTime(content);
    String endTime = _extractEndTime(content);

    if (title.isNotEmpty && date.isNotEmpty && startTime.isNotEmpty && endTime.isNotEmpty) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      Task newTask = Task(
        id: '',
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        categories: [],
        isCompleted: false,
        userId: userId,
        description: '',
        status: 'A Fazer',
        progress: 0.0,
        priority: 4,
      );

      await _firestoreService.addTask(newTask);

      setState(() {
        _response = 'Tarefa criada com sucesso!';
      });
    } else {
      setState(() {
        _response = 'Erro: Não foi possível extrair todas as informações necessárias.';
      });
    }
  } catch (e) {
    setState(() {
      _response = 'Erro ao processar comando: $e';
    });
  }
}

  Future<String> _fetchGPT4oResponseForTaskCreation(String prompt) async {
  final url = Uri.parse('https://us-central1-taskmanager2-9e0a9.cloudfunctions.net/getOpenAIResponse');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'prompt': prompt,
    }),
  );

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Falha ao buscar resposta da IA: ${response.statusCode}');
  }
}

  String _extractTitle(String content) {
  final match = RegExp(r'Título da tarefa:\s*(.*)\n').firstMatch(content);
  return match != null ? _cleanText(match.group(1)!) : '';
}

String _extractDate(String content) {
  final match = RegExp(r'Data:\s*(\d{2}/\d{2}/\d{4})').firstMatch(content);
  return match != null ? _cleanText(match.group(1)!) : '';
}

String _extractStartTime(String content) {
  final match = RegExp(r'Horário de início:\s*(\d{2}:\d{2})').firstMatch(content);
  return match != null ? _cleanText(match.group(1)!) : '';
}

String _extractEndTime(String content) {
  final match = RegExp(r'Horário de término:\s*(\d{2}:\d{2})').firstMatch(content);
  return match != null ? _cleanText(match.group(1)!) : '';
}

String _cleanText(String text) {
  return text
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[\\"]'), '')
      .trim();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assistente Virtual'),
        backgroundColor: LightColors.kBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _commandController,
              decoration: InputDecoration(
                labelText: 'Digite seu comando',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _sendCommand,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LightColors.kBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: Text('Enviar Comando'),
                ),
                SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  backgroundColor: LightColors.kBlue,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Resposta:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _response,
                  style: TextStyle(fontSize: 16),
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
