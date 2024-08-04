import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

class AddedRemindersPage extends StatefulWidget {
  @override
  _AddedRemindersPageState createState() => _AddedRemindersPageState();
}

class _AddedRemindersPageState extends State<AddedRemindersPage> {
  List<Map<String, String>> reminders = [];
  List<Map<String, String>> expiredReminders = [];
  Timer? _timer;

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
    // Calculate the time remaining until the next full minute
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

    // Process to remove expired reminders
    _processExpiredReminders();

    setState(() {
      reminders = loadedReminders;
      expiredReminders = loadedExpiredReminders;
    });

    print('Reminders loaded: $reminders');
    print('Expired reminders loaded: $expiredReminders');
  }

  void _processExpiredReminders() {
    DateTime now = DateTime.now();
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

    // Update the expired reminders list and save changes
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

  void _removeExpiredReminders() {
    DateTime now = DateTime.now();
    setState(() {
      reminders.removeWhere((reminder) {
        DateTime? reminderDateTime =
            _parseDateTime(reminder['date']!, reminder['time']!);
        if (reminderDateTime != null && reminderDateTime.isBefore(now)) {
          expiredReminders.add(reminder);
          return true;
        }
        return false;
      });
      _saveReminders();
    });
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
                // Validate date and time before saving
                DateTime? selectedDateTime = _parseDateTime(
                  dateController.text,
                  timeController.text,
                );

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

                // Show success SnackBar after saving
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

  DateTime? _parseDateTime(String date, String time) {
    try {
      // Parse the date
      DateTime parsedDate = DateFormat('d MMMM yyyy').parse(date);

      // Parse the time
      List<String> timeParts = time.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1].split(' ')[0]);

      // Adjust hour for AM/PM
      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      // Combine date and time
      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
      );
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
      controller.text = DateFormat('d MMMM yyyy')
          .format(pickedDate); // Adjust format as needed
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Added Reminders'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpiredRemindersPage(expiredReminders),
                ),
              );
            },
          ),
        ],
      ),
      body: reminders.isEmpty
          ? Center(
              child: Text(
                'No reminders added yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                final dateTimeText =
                    reminder['date'] != null && reminder['time'] != null
                        ? '${reminder['date']} at ${reminder['time']}'
                        : '';

                return Card(
                  elevation: 20,
                  shadowColor: Colors.black,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder['title'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          reminder['description'] ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Scheduled time:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reminder['date'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    reminder['time'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editReminder(index),
                                ),
                                Container(
                                  height:
                                      24.0, // Adjust the height to fit the icons properly
                                  child: VerticalDivider(
                                    color: Colors.grey,
                                    thickness: 1,
                                    width: 20,
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      Icon(Icons.delete, color: Colors.orange),
                                  onPressed: () =>
                                      _confirmDeleteReminder(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ExpiredRemindersPage extends StatelessWidget {
  final List<Map<String, String>> expiredReminders;

  ExpiredRemindersPage(this.expiredReminders);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expired Reminders'),
      ),
      body: expiredReminders.isEmpty
          ? Center(
              child: Text(
                'No expired reminders.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: expiredReminders.length,
              itemBuilder: (context, index) {
                final reminder = expiredReminders[index];
                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(reminder['title'] ?? ''),
                    subtitle: Text(
                        '${reminder['description'] ?? ''}\n${reminder['date']} at ${reminder['time']}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
