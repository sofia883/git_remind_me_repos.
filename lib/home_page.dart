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
  List<Map<String, String>> filteredReminders = [];
  Timer? _timer;
  bool _isLoading = true;
  Map<String, String>? mostUpcomingReminder;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterReminders);
    _loadReminders();
    _scheduleNextExpirationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
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
      filteredReminders = List.from(reminders);
      mostUpcomingReminder = ReminderUtils.getMostUpcomingReminder(reminders);
      _isLoading = false;
    });

    _processExpiredReminders();
  }

  void _filterReminders() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredReminders = reminders.where((reminder) {
        final title = reminder['title']?.toLowerCase() ?? '';
        final description = reminder['description']?.toLowerCase() ?? '';
        return title.contains(query) || description.contains(query);
      }).toList();
    });
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
        filteredReminders.removeAt(index); // Keep filtered list in sync
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
          filteredReminders = List.from(reminders); // Update filtered list
          mostUpcomingReminder =
              ReminderUtils.getMostUpcomingReminder(reminders);
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
                        filteredReminders = List.from(reminders);
                        mostUpcomingReminder =
                            ReminderUtils.getMostUpcomingReminder(reminders);
                        _saveReminders();
                      });
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
        backgroundColor: Color.fromARGB(200, 252, 172, 0),
        elevation: 15,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(bottom: Radius.elliptical(180, 40))),
        flexibleSpace: ClipPath(),
        toolbarHeight:
            100, // Increased height to accommodate the icon above the title
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.list, size: 30.0, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            SizedBox(height: 8.0), // Space between icon and title
            Text(
              'Remind Me',
              style: TextStyle(
                color: Colors.black,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
      body: Column(
        children: [
          if (mostUpcomingReminder != null)
            Card(
              elevation: 4,
              margin: EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () =>
                    _editReminder(reminders.indexOf(mostUpcomingReminder!)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReminderPage(
                onReminderSaved: () {
                  _loadReminders();
                  _showLoadingIndicator();
                },
              ),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Create Reminder',
      ),
    );
  }
}
