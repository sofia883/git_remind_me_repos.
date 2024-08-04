import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'create_reminder.dart';
import 'reminder_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> reminders = [];
  List<Map<String, String>> expiredReminders = [];
  Timer? _timer;
  bool _isLoading = true; // Loading state

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
      _scheduleNextExpirationCheck(); // Schedule the next check
    });
  }

  Future<void> _loadReminders() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate a delay for loading

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData = prefs.getStringList('reminders') ?? [];
    List<String> expiredRemindersData =
        prefs.getStringList('expiredReminders') ?? [];

    List<Map<String, String>> loadedReminders = remindersData
        .map((reminder) => Map<String, String>.from(jsonDecode(reminder)))
        .toList();
    List<Map<String, String>> loadedExpiredReminders = expiredRemindersData
        .map((reminder) => Map<String, String>.from(jsonDecode(reminder)))
        .toList();

    setState(() {
      reminders = loadedReminders;
      expiredReminders = loadedExpiredReminders;
      _isLoading = false; // Loading finished
    });

    print('Reminders loaded: $reminders');
    print('Expired reminders loaded: $expiredReminders');

    // Immediately process expired reminders upon loading
    _processExpiredReminders();
  }

  void _processExpiredReminders() async {
    DateTime now = DateTime.now().subtract(Duration(
        seconds: DateTime.now().second,
        microseconds:
            DateTime.now().microsecond)); // Round down to the nearest minute
    List<Map<String, String>> newExpiredReminders = [];

    reminders.removeWhere((reminder) {
      DateTime? reminderDateTime =
          _parseDateTime(reminder['date']!, reminder['time']!);
      if (reminderDateTime != null && reminderDateTime.isBefore(now)) {
        newExpiredReminders.add(reminder);
        print('Reminder expired: $reminder');
        return true;
      }
      return false;
    });

    setState(() {
      expiredReminders.addAll(newExpiredReminders);
    });

    if (newExpiredReminders.isNotEmpty) {
      print('Expired reminders added: $newExpiredReminders');
    }

    _saveReminders();
  }

  Future<void> _saveReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData =
        reminders.map((reminder) => jsonEncode(reminder)).toList();
    List<String> expiredRemindersData =
        expiredReminders.map((reminder) => jsonEncode(reminder)).toList();
    await prefs.setStringList('reminders', remindersData);
    await prefs.setStringList('expiredReminders', expiredRemindersData);
  }

  DateTime? _parseDateTime(String date, String time) {
    try {
      DateTime parsedDate = DateFormat('d MMMM yyyy').parse(date);

      List<String> timeParts = time.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1].split(' ')[0]);

      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      return DateTime(
          parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
    } catch (e) {
      print('Error parsing date or time: $e');
      return null;
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime initialDate = DateTime(now.year, now.month, now.day);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('d MMMM yyyy').format(pickedDate);
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    TimeOfDay now = TimeOfDay.now();
    TimeOfDay initialTime = TimeOfDay(hour: now.hour, minute: now.minute);

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      controller.text = pickedTime.format(context);
    }
  }

  void _confirmDeleteReminder(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Reminder'),
          content: Text('Are you sure you want to delete this reminder?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _deleteReminder(index);
    }
  }

  void _deleteReminder(int index) async {
    setState(() {
      reminders.removeAt(index);
      _saveReminders();
    });
  }

  Future<void> _editReminder(int index) async {
    final reminder = reminders[index];
    final titleController = TextEditingController(text: reminder['title']);
    final descriptionController =
        TextEditingController(text: reminder['description']);
    final dateController = TextEditingController(text: reminder['date']);
    final timeController = TextEditingController(text: reminder['time']);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                GestureDetector(
                  onTap: () => _selectDate(context, dateController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectTime(context, timeController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                DateTime? selectedDateTime =
                    _parseDateTime(dateController.text, timeController.text);

                if (selectedDateTime == null ||
                    selectedDateTime.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Date and time should not be in the past.'),
                    ),
                  );
                  return;
                }
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please add a title'),
                    ),
                  );
                  return;
                }

                if (descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please add a description'),
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                setState(() {
                  reminders[index] = {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'date': dateController.text,
                    'time': timeController.text,
                  };
                  _saveReminders();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reminder edited successfully!'),
                  ),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Added Reminders'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
                expiredReminders
                    .clear(); // Clear expired reminders from the list
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
              _loadReminders(); // Reload reminders if a new reminder was added
            }
          });
        },
        child: Icon(Icons.add),
        tooltip: 'Create Reminder',
      ),
    );
  }
}
