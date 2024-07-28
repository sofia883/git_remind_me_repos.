import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'create_reminder.dart'; // Make sure to import the CreateReminderPage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData = prefs.getStringList('reminders') ?? [];

    setState(() {
      reminders = remindersData
          .map((reminder) => Map<String, String>.from(jsonDecode(reminder)))
          .toList();

      // Sort reminders by date and time
      reminders.sort((a, b) {
        DateTime dateTimeA = _parseDateTime(a['date'] ?? '', a['time'] ?? '');
        DateTime dateTimeB = _parseDateTime(b['date'] ?? '', b['time'] ?? '');
        return dateTimeA.compareTo(dateTimeB);
      });

      // Filter upcoming reminders
      DateTime now = DateTime.now();
      reminders = reminders.where((reminder) {
        DateTime reminderDateTime =
            _parseDateTime(reminder['date'] ?? '', reminder['time'] ?? '');
        return reminderDateTime.isAfter(now);
      }).toList();

      _isLoading = false;
    });
  }

  DateTime _parseDateTime(String date, String time) {
    try {
      DateTime parsedDate = DateFormat('d MMMM yyyy').parse(date);
      List<String> timeParts = time.split(':');
      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(),
              ),
            )
          : reminders.isEmpty
              ? Center(
                  child: Text(
                    'No upcoming reminders.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: reminders.length > 3 ? 3 : reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    final dateTimeText =
                        reminder['date'] != null && reminder['time'] != null
                            ? '${reminder['date']} at ${reminder['time']}'
                            : '';

                    return Card(
                      elevation: 20,
                      shadowColor: Colors.black,
                      margin:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                            Text(
                              dateTimeText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateReminderPage()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Create Reminder',
      ),
    );
  }
}
