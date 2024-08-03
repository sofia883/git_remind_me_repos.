import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async'; // Import the async package
import 'package:intl/intl.dart';
import 'create_reminder.dart';

class AddedRemindersPage extends StatefulWidget {
  @override
  _AddedRemindersPageState createState() => _AddedRemindersPageState();
}

class _AddedRemindersPageState extends State<AddedRemindersPage> {
  List<Map<String, String>> reminders = [];
  bool isLoading = true;
  Timer? timer; // Timer to check reminders

  @override
  void initState() {
    super.initState();
    _initializePage();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await Future.delayed(Duration(seconds: 1));
    await _loadReminders();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData = prefs.getStringList('reminders') ?? [];

    setState(() {
      reminders = remindersData
          .map((reminder) => Map<String, String>.from(jsonDecode(reminder)))
          .toList();
    });
  }

  Future<void> _saveReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData =
        reminders.map((reminder) => jsonEncode(reminder)).toList();
    await prefs.setStringList('reminders', remindersData);
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
                final DateTime now = DateTime.now();
                final DateTime selectedDateTime = _parseDateTime(
                  dateController.text,
                  timeController.text,
                );

                if (selectedDateTime.isBefore(now)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'The selected date and time cannot be in the past.'),
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
                  SnackBar(content: Text('Reminder edited successfully!')),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  DateTime _parseDateTime(String date, String time) {
    try {
      DateTime parsedDate = DateFormat('d MMMM yyyy').parse(date);
      List<String> timeParts = time.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      // Check for AM/PM if necessary
      if (time.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (time.toLowerCase().contains('am') && hour == 12) hour = 0;

      DateTime parsedDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
      );

      print('Parsed date time: $parsedDateTime'); // Debug print
      return parsedDateTime;
    } catch (e) {
      print('Error parsing date time: $e'); // Debug print
      return DateTime.now();
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

  Future<void> _navigateToAddReminder(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReminderPage(
          onReminderSaved: () async {
            await _loadReminders(); // Refresh reminders
          },
        ),
      ),
    );

    if (result == true) {
      await _loadReminders(); // Refresh reminders
    }
  }

  void _checkAndUpdateReminders() {
    final currentTime = DateTime.now();
    print('Current time: $currentTime'); // Debug print

    setState(() {
      reminders = reminders.map((reminder) {
        final scheduledDateTime = _parseDateTime(
          reminder['date'] ?? '',
          reminder['time'] ?? '',
        );

        print('Scheduled time: $scheduledDateTime'); // Debug print

        if (scheduledDateTime.year == currentTime.year &&
            scheduledDateTime.month == currentTime.month &&
            scheduledDateTime.day == currentTime.day &&
            scheduledDateTime.hour == currentTime.hour &&
            scheduledDateTime.minute == currentTime.minute) {
          // Mark reminder as red
          print(
              'Time matched for reminder: ${reminder['title']}'); // Debug print
          return {...reminder, 'isRed': 'true'};
        }

        return {...reminder, 'isRed': 'false'};
      }).toList();
    });
  }

  void _startTimer() {
    timer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      print('Timer tick: ${DateTime.now()}'); // Debug print
      _checkAndUpdateReminders();
    });
  }

  void _moveToExpiredRemindersPage(List<Map<String, String>> expiredReminders) {
    // Implement the navigation to the "Expired Reminders" page
    // You can pass the expired reminders to the new page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Added Reminders'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _navigateToAddReminder(context),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : reminders.isEmpty
              ? Center(
                  child: Text(
                    'No reminders added yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    final scheduledDateTime = _parseDateTime(
                      reminder['date'] ?? '',
                      reminder['time'] ?? '',
                    );
                    final currentTime = DateTime.now();
                    final isTimeMatching =
                        scheduledDateTime.year == currentTime.year &&
                            scheduledDateTime.month == currentTime.month &&
                            scheduledDateTime.day == currentTime.day &&
                            scheduledDateTime.hour == currentTime.hour &&
                            scheduledDateTime.minute == currentTime.minute;

                    return Card(
                      color: reminder['isRed'] == 'true'
                          ? Colors.red
                          : Colors.white,
                      // Other card properties...

                      elevation: 20,
                      shadowColor: Colors.black,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              reminder['description'] ?? '',
                              style: TextStyle(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editReminder(index),
                                ),
                                Container(
                                  height: 24.0,
                                  child: VerticalDivider(
                                    color: Colors.grey,
                                    thickness: 1,
                                    width: 20,
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      Icon(Icons.delete, color: Colors.orange),
                                  onPressed: () => _deleteReminder(index),
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
