 import 'package:flutter/material.dart';
 import 'create_reminder.dart';
class RemindersPage extends StatefulWidget {
  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<String> reminders = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remind Me'),
      ),
      body: reminders.isEmpty
          ? Center(
              child: Text(
                "Oh! There are no reminders yet. Create one now.",
                style: TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(reminders[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateReminderPage(
              onReminderCreated: (String reminder) {
                setState(() {
                  reminders.add(reminder);
                });
              },
            )),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Reminder',
      ),
    );
  }
}
