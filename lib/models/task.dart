class Task {
  String id;
  String title;
  String date;
  String startTime;
  String endTime;
  String description;
  List<String> categories;
  bool isCompleted;
  String userId;
  String status;
  double progress;
  int priority;

  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.categories,
    required this.isCompleted,
    required this.userId,
    required this.status,
    required this.progress,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
      'categories': categories,
      'isCompleted': isCompleted,
      'userId': userId,
      'status': status,
      'progress': progress,
      'priority': priority,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      description: map['description'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'] ?? '',
      status: map['status'] ?? 'A Fazer',
      progress: map['progress']?.toDouble() ?? 0.0,
      priority: map['priority'] ?? 4,
    );
  }
}
