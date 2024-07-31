import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'create_reminder.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> reminders = [];
  List<Map<String, String>> filteredReminders = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _searchController.addListener(_filterReminders);
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

      filteredReminders = List.from(reminders);
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

  void _filterReminders() {
    setState(() {
      if (_searchController.text.isEmpty) {
        filteredReminders = List.from(reminders);
      } else {
        filteredReminders = reminders.where((reminder) {
          return (reminder['title'] ?? '')
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              (reminder['description'] ?? '')
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.list, // File icon
              color: Colors.white, // Icon color
              size: 30.0, // Icon size
            ),
            SizedBox(height: 12.0), // Space between icon and title
            Text(
              'Remind Me',
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(
              height: 12,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reminders...',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(30.0), // Circular border radius
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                ),
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/canva_design.html'))),
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: CircularProgressIndicator(),
                ),
              )
            : filteredReminders.isEmpty
                ? Center(
                    child: Text(
                      'No upcoming reminders.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredReminders.length > 5
                        ? 5
                        : filteredReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = filteredReminders[index];
                      final dateTimeText =
                          reminder['date'] != null && reminder['time'] != null
                              ? '${reminder['date']} at ${reminder['time']}'
                              : '';

                      return Card(
                        elevation: 20,
                        shadowColor: Colors.black,
                        margin: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CreateReminderPage(
                      onReminderSaved: _loadReminders,
                    )),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Create Reminder',
      ),
    );
  }
}
