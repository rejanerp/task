import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/light_colors.dart';
import '../widgets/top_container.dart';
import '../widgets/back_button.dart';
import '../widgets/my_text_field.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:task/main.dart';

class CreateNewTaskPage extends StatefulWidget {
  @override
  _CreateNewTaskPageState createState() => _CreateNewTaskPageState();
}

class _CreateNewTaskPageState extends State<CreateNewTaskPage> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  List<String> _categories = [];
  final FirestoreService _firestoreService = FirestoreService();

  int _selectedPriority = 4; // Default to 'Sem Prioridade'
  int _selectedUrgency = 4;  // Default to 'Sem Urgência'

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    List<String> categories = await _firestoreService.loadCategories(userId);
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _saveCategory(String category) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await _firestoreService.saveCategory(userId, category);
    setState(() {
      _categories.add(category);
    });
  }

  Future<void> _saveTask(BuildContext context) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    if (_titleController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios')),
      );
      return;
    }

    Task newTask = Task(
      id: '',
      title: _titleController.text,
      date: _dateController.text,
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
      categories: _categories,
      isCompleted: false,
      userId: userId,
      description: _descriptionController.text,
      status: 'A Fazer', // Status inicial
      progress: 0.0, // Progresso inicial
      priority: _selectedPriority, // Selected priority
    );

    try {
      // Salva a tarefa no Firestore
      await _firestoreService.addTask(newTask);

      // Agendar a notificação para o horário da tarefa
      scheduleTaskNotification(newTask);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarefa criada com sucesso')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar tarefa: $e')),
      );
    }
  }

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      setState(() {
        _categories.add(_categoryController.text);
        _categoryController.clear();
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() {
        controller.text = DateFormat('HH:mm').format(selectedTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    var downwardIcon = Icon(
      Icons.keyboard_arrow_down,
      color: Colors.black54,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TopContainer(
                height: 200,
                padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
                width: width,
                child: Column(
                  children: <Widget>[
                    MyBackButton(),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Criar nova tarefa',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 20),
                    MyTextField(
                      label: 'Título',
                      controller: _titleController,
                      icon: downwardIcon,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: MyTextField(
                            label: 'Data',
                            controller: _dateController,
                            icon: downwardIcon,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () {
                            _selectDate(context);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: MyTextField(
                            label: 'Hora de Início',
                            controller: _startTimeController,
                            icon: downwardIcon,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.access_time),
                          onPressed: () {
                            _selectTime(context, _startTimeController);
                          },
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: MyTextField(
                            label: 'Hora de Término',
                            controller: _endTimeController,
                            icon: downwardIcon,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.access_time),
                          onPressed: () {
                            _selectTime(context, _endTimeController);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    MyTextField(
                      label: 'Descrição',
                      controller: _descriptionController,
                      icon: downwardIcon,
                      minLines: 3,
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),
                    Container(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Categoria',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: MyTextField(
                                  label: 'Nova Categoria',
                                  controller: _categoryController,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: _addCategory,
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children: _categories.map((category) {
                              return Chip(
                                label: Text(category),
                                backgroundColor: LightColors.kBlue,
                                labelStyle: TextStyle(color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Priority Dropdown
                    DropdownButton<int>(
                      value: _selectedPriority,
                      items: [
                        DropdownMenuItem(value: 1, child: Text('Prioridade Alta')),
                        DropdownMenuItem(value: 2, child: Text('Prioridade Média')),
                        DropdownMenuItem(value: 3, child: Text('Prioridade Baixa')),
                        DropdownMenuItem(value: 4, child: Text('Sem Prioridade')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    // Urgency Dropdown
                    DropdownButton<int>(
                      value: _selectedUrgency,
                      items: [
                        DropdownMenuItem(value: 1, child: Text('Urgente')),
                        DropdownMenuItem(value: 2, child: Text('Média')),
                        DropdownMenuItem(value: 3, child: Text('Baixa')),
                        DropdownMenuItem(value: 4, child: Text('Sem Urgência')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUrgency = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: ElevatedButton(
                  onPressed: () {
                    _saveTask(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LightColors.kBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 20),
                    minimumSize: Size(width - 40, 50),
                  ),
                  child: Text(
                    'Criar Tarefa',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
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
