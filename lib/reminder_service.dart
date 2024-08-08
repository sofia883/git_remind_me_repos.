import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'reminder_details.dart';

class ReminderUtils {
  static Future<void> saveReminders(List<Map<String, String>> reminders,
      List<Map<String, String>> expiredReminders) async {
    // Show loading indicator for 1 second
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData =
        reminders.map((reminder) => jsonEncode(reminder)).toList();
    List<String> expiredRemindersData =
        expiredReminders.map((reminder) => jsonEncode(reminder)).toList();
    await prefs.setStringList('reminders', remindersData);
    await prefs.setStringList('expiredReminders', expiredRemindersData);
  }

  static Future<List<List<Map<String, String>>>> loadReminders() async {
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

    return [loadedReminders, loadedExpiredReminders];
  }

  static DateTime? parseDateTime(String date, String time) {
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

  static Future<void> selectDate(
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

  static Future<void> selectTime(
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

  static Future<bool> confirmDeleteReminder(BuildContext context) async {
    return await showDialog<bool>(
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
        ) ??
        false;
  }

  static Future<void> editReminder(
    BuildContext context,
    Map<String, String> reminder,
    Function(Map<String, String>) onSave,
  ) async {
    final titleController = TextEditingController(text: reminder['title']);
    final descriptionController =
        TextEditingController(text: reminder['description']);
    final dateController = TextEditingController(text: reminder['date']);
    final timeController = TextEditingController(text: reminder['time']);

    try {
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
                    onTap: () => selectDate(context, dateController),
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
                    onTap: () => selectTime(context, timeController),
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
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  DateTime? selectedDateTime =
                      parseDateTime(dateController.text, timeController.text);

                  if (selectedDateTime == null ||
                      selectedDateTime.isBefore(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Date and time should not be in the past.')),
                    );
                    return;
                  }
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please add a title')),
                    );
                    return;
                  }
                  if (descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please add a description')),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  onSave({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'date': dateController.text,
                    'time': timeController.text,
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
    } catch (e) {
      print('Error editing reminder: $e');
    }
  }

  static void processExpiredReminders(List<Map<String, String>> reminders,
      List<Map<String, String>> expiredReminders) {
    DateTime now = DateTime.now().subtract(Duration(
        seconds: DateTime.now().second,
        microseconds:
            DateTime.now().microsecond)); // Round down to the nearest minute
    List<Map<String, String>> newExpiredReminders = [];

    reminders.removeWhere((reminder) {
      DateTime? reminderDateTime =
          parseDateTime(reminder['date']!, reminder['time']!);
      if (reminderDateTime != null && reminderDateTime.isBefore(now)) {
        newExpiredReminders.add(reminder);
        print('Reminder expired: $reminder');
        return true;
      }
      return false;
    });

    expiredReminders.addAll(newExpiredReminders);

    if (newExpiredReminders.isNotEmpty) {
      print('Expired reminders added: $newExpiredReminders');
    }
  }

  static Future<void> showLoadingIndicator(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    await Future.delayed(Duration(seconds: 1));

    Navigator.of(context).pop(); // Close the loading indicator
  }

  static Map<String, String>? getMostUpcomingReminder(
      List<Map<String, String>> reminders) {
    if (reminders.isEmpty) return null;

    DateTime now = DateTime.now();
    reminders.sort((a, b) {
      DateTime dateTimeA = _parseDateTime(a['date']!, a['time']!);
      DateTime dateTimeB = _parseDateTime(b['date']!, b['time']!);
      return dateTimeA.compareTo(dateTimeB);
    });

    // Find the first reminder that's in the future
    return reminders.firstWhere(
      (reminder) {
        DateTime reminderDateTime =
            _parseDateTime(reminder['date']!, reminder['time']!);
        return reminderDateTime.isAfter(now);
      },
      orElse: () =>
          reminders.first, // If all are in the past, return the first one
    );
  }

  static DateTime _parseDateTime(String date, String time) {
    // Parse date like "7 August 2024"
    List<String> dateParts = date.split(' ');
    int day = int.parse(dateParts[0]);
    int month = _getMonthNumber(dateParts[1]);
    int year = int.parse(dateParts[2]);

    // Parse time like "2:11 AM"
    List<String> timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1].split(' ')[0]);
    bool isPM = timeParts[1].contains('PM');

    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    return DateTime(year, month, day, hour, minute);
  }

  static int _getMonthNumber(String monthName) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12
    };
    return months[monthName] ?? 1; // Default to 1 if month name is not found
  }

  static Future<bool> openReminderDetails(
    BuildContext context,
    Map<String, String> reminder,
    int index,
    List<Map<String, String>> reminders,
    Function() onSave,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailsPage(
          reminder: reminder,
          onEdit: (updatedReminder) async {
            reminders[index] = updatedReminder;
            await saveReminders(
                reminders, []); // Assuming empty expired reminders list
            onSave();
            Navigator.pop(context, true);
          },
          onDelete: () async {
            reminders.removeAt(index);
            await saveReminders(
                reminders, []); // Assuming empty expired reminders list
            onSave();
            Navigator.pop(context, true);
          },
        ),
      ),
    );
    return result ?? false;
  }
}
