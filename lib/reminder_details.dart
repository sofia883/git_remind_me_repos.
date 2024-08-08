import 'package:flutter/material.dart';
import 'reminder_service.dart';

class ReminderDetailsPage extends StatelessWidget {
  final Map<String, String> reminder;
  final Function(Map<String, String>) onEdit;
  final Function() onDelete;

  ReminderDetailsPage({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminder Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editReminder(context),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteReminder(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder['title'] ?? 'No Title',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              reminder['description'] ?? 'No Description',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              '${reminder['date']} ${reminder['time']}',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _editReminder(BuildContext context) async {
    await ReminderUtils.editReminder(
      context,
      reminder,
      (updatedReminder) {
        onEdit(updatedReminder);
        Navigator.pop(context);
      },
    );
  }

  void _deleteReminder(BuildContext context) async {
    bool confirmDelete = await ReminderUtils.confirmDeleteReminder(context);
    if (confirmDelete) {
      onDelete();
      Navigator.pop(context);
    }
  }
  
}