import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'notifications_service.dart';

class CreateReminderPage extends StatefulWidget {
  final VoidCallback onReminderSaved;

  CreateReminderPage({required this.onReminderSaved});

  @override
  _CreateReminderPageState createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String? _titleError;
  String? _descriptionError;
  String? _dateError;
  String? _timeError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  bool isPastDateTime(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  void _scheduleNotification(Map<String, String> reminder) {
    final String title = reminder['title'] ?? 'Reminder';
    final String body = reminder['description'] ?? '';

    // Parse the date
    final DateFormat dateFormat = DateFormat('d MMMM yyyy');
    final DateTime date = dateFormat.parse(reminder['date'] ?? '');

    // Combine date and time
    final DateTime scheduledDate = DateTime(
      date.year,
      date.month,
      date.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Generate a unique ID for the notification
    final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    NotificationService().showNotification(id, title, body, scheduledDate);

    print('Notification scheduled for: $scheduledDate with id: $id');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('d MMMM yyyy').format(pickedDate);
        _dateError = null; // Clear date error message when a date is selected
      });
      print('Selected Date: $_selectedDate');
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _timeController.text = pickedTime.format(context);
        _timeError = null; // Clear time error message when a time is selected
      });
      print('Selected Time: $_selectedTime');
    }
  }

  void _validateAndSaveReminder() {
    setState(() {
      _titleError =
          _titleController.text.isEmpty ? 'Please enter a title' : null;
      _descriptionError = _descriptionController.text.isEmpty
          ? 'Please enter a description'
          : null;
      _dateError = _dateController.text.isEmpty ? 'Please select a date' : null;
      _timeError = _timeController.text.isEmpty ? 'Please select a time' : null;
    });

    if (_titleError == null &&
        _descriptionError == null &&
        _dateError == null &&
        _timeError == null) {
      _saveReminder();
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      final selectedDate = _selectedDate;
      final selectedTime = _selectedTime;

      if (selectedDate == null || selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a valid date and time')),
        );
        return;
      }

      final dateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      if (isPastDateTime(dateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The date and time cannot be in the past.')),
        );
        return;
      }

      final DateFormat dateFormat = DateFormat('d MMMM yyyy');
      final DateFormat timeFormat = DateFormat('h:mm a');

      Map<String, String> newReminder = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': dateFormat.format(selectedDate),
        'time': timeFormat
            .format(DateTime(0, 0, 0, selectedTime.hour, selectedTime.minute)),
      };

      print('Saving reminder: $newReminder');

      // Schedule the notification
      _scheduleNotification(newReminder);

      // Save the reminder to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> reminders = prefs.getStringList('reminders') ?? [];
      reminders.add(jsonEncode(newReminder));
      await prefs.setStringList('reminders', reminders);

      print('Reminders saved: $reminders');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder saved successfully!')),
      );

      // Call the callback to notify the HomePage
      widget.onReminderSaved();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Reminder')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode:
              AutovalidateMode.onUserInteraction, // Enable real-time validation
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  errorText: _titleError,
                ),
                onChanged: (value) {
                  setState(() {
                    _titleError = null; // Clear error when value changes
                  });
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  errorText: _descriptionError,
                ),
                onChanged: (value) {
                  setState(() {
                    _descriptionError = null; // Clear error when value changes
                  });
                },
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                      errorText: _dateError,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Time',
                      suffixIcon: Icon(Icons.access_time),
                      errorText: _timeError,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _validateAndSaveReminder,
                child: Text('Save Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
