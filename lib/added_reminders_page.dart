import 'package:flutter/material.dart';
import 'dart:async';
import 'create_reminder.dart';
import 'reminder_service.dart';

class AddedRemindersPage extends StatefulWidget {
  @override
  _AddedRemindersPageState createState() => _AddedRemindersPageState();
}

class _AddedRemindersPageState extends State<AddedRemindersPage> {
  List<Map<String, String>> reminders = [];
  List<Map<String, String>> expiredReminders = [];
  Timer? _timer;
  bool _isLoading = true;
  Map<String, String>? mostUpcomingReminder;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _scheduleNextExpirationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNextExpirationCheck() {
    DateTime now = DateTime.now();
    DateTime nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute)
            .add(Duration(minutes: 1));
    Duration durationUntilNextMinute = nextMinute.difference(now);

    _timer = Timer(durationUntilNextMinute, () {
      _processExpiredReminders();
      _scheduleNextExpirationCheck();
    });
  }

  Future<void> _loadReminders() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate a delay for loading

    List<List<Map<String, String>>> loadedReminders =
        await ReminderUtils.loadReminders();

    setState(() {
      reminders = loadedReminders[0];
      expiredReminders = loadedReminders[1];
      mostUpcomingReminder = ReminderUtils.getMostUpcomingReminder(reminders);
      _isLoading = false;
    });

    print('Reminders loaded: $reminders');
    print('Expired reminders loaded: $expiredReminders');
    print('Most upcoming reminder: $mostUpcomingReminder');

    _processExpiredReminders();
  }

  Future<void> _showLoadingIndicator() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });
  }
  //   // Future<void> _showLoadingIndicator() async { // i will see it later on why this method is not wrking as expected

  //   await ReminderUtils.showLoadingIndicator(context);
  // }

  void _processExpiredReminders() {
    ReminderUtils.processExpiredReminders(reminders, expiredReminders);
    setState(() {});
    _saveReminders();
  }

  Future<void> _saveReminders() async {
    await ReminderUtils.saveReminders(reminders, expiredReminders);
  }

  void _confirmDeleteReminder(int index) async {
    final result = await ReminderUtils.confirmDeleteReminder(context);
    if (result) {
      setState(() {
        reminders.removeAt(index);
        _saveReminders();
      });
    }
  }

  Future<void> _editReminder(int index) async {
    await ReminderUtils.editReminder(
      context,
      reminders[index],
      (updatedReminder) {
        setState(() {
          reminders[index] = updatedReminder;
          _saveReminders();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Added Reminders')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Added Reminders'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                expiredReminders.clear();
                _saveReminders();
              });
            },
          ),
        ],
      ),
      body: reminders.isEmpty
          ? Center(
              child: Text(
                'No reminders added',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return Card(
                  child: ListTile(
                    title: Text(reminder['title'] ?? 'No Title'),
                    subtitle: Text(
                        '${reminder['description']}\n${reminder['date']} ${reminder['time']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _confirmDeleteReminder(index),
                    ),
                    onTap: () => _editReminder(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReminderPage(
                onReminderSaved: _loadReminders,
              ),
            ),
          ).then((result) {
            if (result == true) {
              _showLoadingIndicator();
            }
          });
        },
        child: Icon(Icons.add),
        tooltip: 'Create Reminder',
      ),
    );
  }
}