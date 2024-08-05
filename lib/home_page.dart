import 'package:flutter/material.dart';
import 'dart:async';
import 'create_reminder.dart';
import 'reminder_service.dart';
import 'expired_reminders.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
        appBar: AppBar(title: Text('Home Page')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
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
          IconButton(
            icon: Icon(Icons.history, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpiredRemindersPage(
                    expiredReminders: expiredReminders,
                    onRestore: (index) {
                      setState(() {
                        // Move the reminder from expired to active
                        reminders.add(expiredReminders[index]);
                        expiredReminders.removeAt(index);
                        _saveReminders();
                      });
                      // Optionally, you can show a snackbar or toast to confirm the restoration
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reminder restored')),
                      );
                    },
                  ),
                ),
              );
            },
            tooltip: 'View expired reminders',
          ),
        ],
      ),
      body: mostUpcomingReminder == null
          ? Center(
              child: Text(
                'No reminders added',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () =>
                      _editReminder(reminders.indexOf(mostUpcomingReminder!)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Most Upcoming Reminder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          mostUpcomingReminder!['title'] ?? 'No Title',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          mostUpcomingReminder!['description'] ??
                              'No Description',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${mostUpcomingReminder!['date']} ${mostUpcomingReminder!['time']}',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
