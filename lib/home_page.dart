import 'package:flutter/material.dart';
import 'create_reminder.dart';
import 'welcome_page.dart';

class RemindersPage extends StatelessWidget {
  final List<String> reminders = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // forceMaterialTransparency: true,
        title: Text('Remind Me'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/home_page.jpg', // Ensure this path is correct
            fit: BoxFit.cover,
            // width: double.infinity,
            // height: double.infinity,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: reminders.isEmpty
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
                            title: Text(
                              reminders[index],
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
                onReminderCreated: (String reminder) {
                  // Handle adding the reminder
                },
              ),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Reminder',
      ),
    );
  }
}
