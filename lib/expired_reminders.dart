import 'package:flutter/material.dart';

class ExpiredRemindersPage extends StatelessWidget {
  final List<Map<String, String>> expiredReminders;
  final Function(int) onRestore;

  ExpiredRemindersPage({required this.expiredReminders, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expired Reminders'),
        backgroundColor: Colors.teal,
      ),
      body: expiredReminders.isEmpty
          ? Center(
              child: Text(
                'No expired reminders',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: expiredReminders.length,
              itemBuilder: (context, index) {
                final reminder = expiredReminders[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(reminder['title'] ?? 'No Title'),
                    subtitle: Text(reminder['description'] ?? 'No Description'),
                    trailing: Text('${reminder['date']} ${reminder['time']}'),
                    onTap: () => onRestore(index),
                  ),
                );
              },
            ),
    );
  }
}