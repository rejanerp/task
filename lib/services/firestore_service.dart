import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Adicionar uma nova task
  Future<void> addTask(Task task) async {
    await _db.collection('tasks').add(task.toMap());
  }
  

  // Editar uma task existente
  Future<void> updateTask(Task task) async {
    await _db.collection('tasks').doc(task.id).update(task.toMap());
  }

  // Atualizar status de uma task
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _db.collection('tasks').doc(taskId).update({'status': newStatus});
  }

  // Atualizar progresso de uma task
  Future<void> updateTaskProgress(String taskId, double progress) async {
    await _db.collection('tasks').doc(taskId).update({'progress': progress});
  }

  // Deletar uma task
  Future<void> deleteTask(String id) async {
    await _db.collection('tasks').doc(id).delete();
  }

  // Obter lista de tasks para um usuário específico
  Stream<List<Task>> getTasks(String userId) {
    return _db.collection('tasks')
        .where('userId', isEqualTo: userId) // Verifique se este campo 'userId' está correto no Firestore
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Salvar categorias do usuário
  Future<void> saveCategory(String userId, String category) async {
    await _db.collection('users').doc(userId).update({
      'categories': FieldValue.arrayUnion([category])
    });
  }
  

  // Carregar categorias do usuário
  Future<List<String>> loadCategories(String userId) async {
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc['categories'] != null) {
      return List<String>.from(doc['categories']);
    }
    return [];
  }
}
  
