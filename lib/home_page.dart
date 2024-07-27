import 'package:flutter/material.dart';
import 'create_reminder.dart';
import 'welcome_page.dart';
import 'added_reminders_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _reminders = [];

  void _addReminder(
      String title, String description, String date, String time) {
    setState(() {
      _reminders.add('$title\n$description\n$date at $time');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Remind Me',
          style:
              TextStyle(color: Color.fromARGB(255, 255, 153, 0), fontSize: 25),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/white.jpg', // Ensure this path is correct
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _reminders.isEmpty
                    ? Center(
                        child: Text(
                          "Oh! There are no reminders yet. Create one now.",
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _reminders.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              _reminders[index],
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to the WelcomePage
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomePage()),
                    );
                  },
                  child: Text('Back to Welcome Page'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddedRemindersPage()),
                    );
                  },
                  child: Text('View Added Reminders'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReminderPage(
                  // onReminderCreated: (title, description, date, time) {
                  //   _addReminder(title, description, date, time);
                  // },
                  ),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Color.fromARGB(255, 255, 153, 0),
        tooltip: 'Add Reminder',
      ),
    );
  }
}
