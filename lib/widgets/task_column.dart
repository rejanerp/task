import 'package:flutter/material.dart';

class TaskColumn extends StatelessWidget {
  final String taskId;
  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final String status;
  final Function(String) onChangeStatus;

  TaskColumn({
    required this.taskId,
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onChangeStatus,
  });

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Change Task Status'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                onChangeStatus('To Do');
                Navigator.pop(context);
              },
              child: Text('To Do'),
            ),
            SimpleDialogOption(
              onPressed: () {
                onChangeStatus('In Progress');
                Navigator.pop(context);
              },
              child: Text('In Progress'),
            ),
            SimpleDialogOption(
              onPressed: () {
                onChangeStatus('Done');
                Navigator.pop(context);
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showStatusDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
