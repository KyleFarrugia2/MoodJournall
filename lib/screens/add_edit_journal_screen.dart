import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../services/location_service.dart';
import '../services/analytics_service.dart';

class AddEditJournalScreen extends StatefulWidget {
  final JournalEntry? entry;

  const AddEditJournalScreen({super.key, this.entry});

  @override
  State<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends State<AddEditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Mood _selectedMood = Mood.okay;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _locationName;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
      _selectedDate = widget.entry!.entryDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.entry!.entryDate);
      _locationName = widget.entry!.locationName;
      _latitude = widget.entry!.latitude;
      _longitude = widget.entry!.longitude;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
    AnalyticsService.instance.logScreenView('add_edit_journal_screen');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    await AnalyticsService.instance.logDatePickerOpened();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    await AnalyticsService.instance.logTimePickerOpened();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        final locationString = locationService.formatLocation(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationName = locationString;
          _isLoadingLocation = false;
        });

        await AnalyticsService.instance.logLocationAccessed();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location captured: $_locationName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Could not get location. Please check permissions.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveEntry() async {
    await AnalyticsService.instance
        .logSaveButtonClicked('add_edit_journal_screen');
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select date and time'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final entryDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final entry = JournalEntry(
        id: widget.entry?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        mood: _selectedMood,
        entryDate: entryDate,
        locationName: _locationName,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        final journalProvider = context.read<JournalProvider>();
        if (widget.entry == null) {
          await journalProvider.addEntry(entry);
        } else {
          await journalProvider.updateEntry(entry);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.entry == null
                    ? 'Entry created successfully!'
                    : 'Entry updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving entry: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'What\'s on your mind?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How are you feeling?',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: Mood.values.map((mood) {
                            final isSelected = _selectedMood == mood;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMood = mood;
                                });
                                AnalyticsService.instance.logMoodSelected(mood);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? mood.colorValue.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? mood.colorValue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      mood.emoji,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mood.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? mood.colorValue
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Journal Entry',
                    hintText: 'Write about your day...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit_note),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please write something';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(
                      _selectedDate != null
                          ? dateFormat.format(_selectedDate!)
                          : 'Not selected',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Time'),
                    subtitle: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Not selected',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectTime(context),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on),
                            const SizedBox(width: 8),
                            Text(
                              'Location',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _locationName ?? 'No location set',
                          style: TextStyle(
                            color: _locationName != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingLocation
                                    ? null
                                    : _getCurrentLocation,
                                icon: _isLoadingLocation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.my_location),
                                label: Text(_isLoadingLocation
                                    ? 'Getting...'
                                    : 'Get GPS'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_locationName != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _locationName = null;
                                    _latitude = null;
                                    _longitude = null;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.entry == null ? 'Create Entry' : 'Update Entry',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
