import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'dart:convert';
import 'dart:async'; // Added for Timer

class TimetablePage extends StatefulWidget {
  // ThemeData is not used in the state, so it can be defined here or within the build method.
  // Kept as is, per request.
  ThemeData get theme => ThemeData(
        primarySwatch: Colors.blueGrey,
      );
  const TimetablePage({super.key});

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late PageController _pageController;
  Timer? _timer; // Timer to periodically update the current/next class info.

  Map<String, List<Map<String, String>>> timetable = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  // Custom courses stored separately
  Map<String, List<Map<String, String>>> customCourses = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  // Track deleted API courses (will be restored on refresh)
  Set<String> deletedApiCourses = {}; // Format: "Day_Time_Subject"

  // State variables for displaying class information
  String currentClass = "No class currently";
  String currentClassEndTime = "";
  String nextClass = "No class scheduled";
  String nextClassInfo = ""; // Combined time and day info for the next class

  final List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  final Map<String, Map<String, String>> apiUrls = {
    '1st Year': {
      'CSEA': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=CSEA_1',
      'CSEB': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=CSEB_1',
      'DSAI': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=DSAI_1',
      'ECE': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=ECE_1',
    },
    '2nd Year': {
      'CSEA': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=CSEA_2',
      'CSEB': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=CSEB_2',
      'DSAI': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=DSAI_2',
      'ECE': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=ECE_2',
    },
    '3rd Year': {
      'CSEA': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=CSEA_3',
      'CSEB': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=CSEB_3',
      'DSAI': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=DSAI_3',
      'ECE': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=ECE_3',
    },
    '4th Year': {
      'CSEA': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=CSEA_4',
      'CSEB': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=CSEB_4',
      'DSAI': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=DSAI_4',
      'ECE': 'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=ECE_4',
    },
  };

  String selectedYear = '1st Year';
  String selectedBranch = 'CSEA';
  bool isLoading = true;
  String? errorMessage; // To hold error messages for the UI

  @override
  void initState() {
    super.initState();
    int currentDayIndex = DateTime.now().weekday - 1;
    _pageController = PageController(initialPage: currentDayIndex);
    _initializeData();

    // Set up a timer to check for class changes every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _findCurrentAndNextClass();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadSavedOptions();
    await _loadCustomCourses();
    await _loadDeletedApiCourses();
    // On the very first open, we want to fetch from the network only if there is
    // no cached timetable yet for the selected year/branch. If cached data exists,
    // we'll just use that and avoid an unnecessary auto-fetch.
    await _fetchData(isInitialLoad: true, skipIfCacheAvailable: true);
  }
  
  Future<void> _loadSavedOptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedYear = prefs.getString('selectedYear') ?? '1st Year';
      selectedBranch = prefs.getString('selectedBranch') ?? 'CSEA';
    });
  }

  Future<void> _saveSelectedOptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedYear', selectedYear);
    await prefs.setString('selectedBranch', selectedBranch);
  }

  Future<void> _fetchData({bool isInitialLoad = false, bool skipIfCacheAvailable = false}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final String cacheKey = 'timetable_data_${selectedYear}_${selectedBranch}';
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // **IMPROVEMENT**: On initial load, try to load from cache first for a fast startup.
    if (isInitialLoad) {
      final String? cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        _processTimetableData(List<Map<String, dynamic>>.from(json.decode(cachedData)));
        // If requested, stop here and don't hit the network at all.
        if (skipIfCacheAvailable) {
          setState(() {
            isLoading = false;
          });
          return;
        }
        setState(() {
          isLoading = false;
        }); // Show cached data immediately
      }
    }

    try {
      final apiUrl = apiUrls[selectedYear]![selectedBranch]!;
      final response = await ApiService(apiUrl: apiUrl).fetchData();
      await prefs.setString(cacheKey, json.encode(response));
      
      // Clear deleted courses when refreshing from API (they will come back)
      deletedApiCourses.clear();
      await _saveDeletedApiCourses();
      
      _processTimetableData(response);
    } catch (e) {
      print('Error fetching data: $e');
      // **IMPROVEMENT**: If network fails, try cache as a fallback.
      final String? cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        _processTimetableData(List<Map<String, dynamic>>.from(json.decode(cachedData)));
      } else {
        // If both network and cache fail, show an error.
        setState(() {
          errorMessage = 'Failed to load timetable. Please check your connection.';
        });
      }
    } finally {
      // Ensure loading indicator is turned off
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _processTimetableData(List<Map<String, dynamic>> data) {
    // Clear existing API data (but keep custom courses)
    timetable.forEach((key, value) => value.clear());

    for (var entry in data) {
      final String day = entry['Day'] ?? '';
      final String time = entry['Time'] ?? '';
      final String subject = entry['Subject'] ?? '';

      if (timetable.containsKey(day) && time.isNotEmpty && subject.isNotEmpty) {
        // Create unique key for this API course
        final courseKey = _getApiCourseKey(day, time, subject);
        
        // Only add if not deleted
        if (!deletedApiCourses.contains(courseKey)) {
          timetable[day]!.add({
            'Time': time,
            'Subject': subject,
            'isCustom': 'false',
            'courseKey': courseKey,
          });
        }
      }
    }

    // Merge custom courses with API courses
    _mergeCustomCourses();
    
    // **IMPROVEMENT**: Sort classes by time to ensure "next class" logic is correct.
    timetable.forEach((day, classes) {
      classes.sort((a, b) {
        try {
          DateTime timeA = _parseTime(a['Time']!.split(' - ')[0]);
          DateTime timeB = _parseTime(b['Time']!.split(' - ')[0]);
          return timeA.compareTo(timeB);
        } catch (_) {
          return 0;
        }
      });
    });
    
    _findCurrentAndNextClass();
  }

  // Generate unique key for API course
  String _getApiCourseKey(String day, String time, String subject) {
    return '${day}_${time}_${subject}';
  }

  // Merge custom courses with API courses
  void _mergeCustomCourses() {
    customCourses.forEach((day, customClasses) {
      for (var customClass in customClasses) {
        // Check if this custom course already exists in timetable
        bool exists = timetable[day]!.any((course) =>
          course['Subject'] == customClass['Subject'] &&
          course['Time'] == customClass['Time'] &&
          course['isCustom'] == 'true'
        );
        
        if (!exists) {
          timetable[day]!.add({
            'Time': customClass['Time']!,
            'Subject': customClass['Subject']!,
            'isCustom': 'true',
            'id': customClass['id'] ?? '',
          });
        }
      }
    });
  }

  // Load deleted API courses from SharedPreferences
  Future<void> _loadDeletedApiCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDeletedCourses = prefs.getString('deleted_api_courses');
    
    if (savedDeletedCourses != null) {
      try {
        List<dynamic> decoded = json.decode(savedDeletedCourses);
        deletedApiCourses = decoded.map((e) => e.toString()).toSet();
      } catch (e) {
        print('Error loading deleted API courses: $e');
        deletedApiCourses = {};
      }
    }
  }

  // Save deleted API courses to SharedPreferences
  Future<void> _saveDeletedApiCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('deleted_api_courses', json.encode(deletedApiCourses.toList()));
  }

  // Delete API course (temporary - will come back on refresh)
  Future<void> _deleteApiCourse(String day, String courseKey) async {
    deletedApiCourses.add(courseKey);
    await _saveDeletedApiCourses();
    
    // Remove from timetable display
    timetable[day]!.removeWhere((course) => course['courseKey'] == courseKey);
    
    // Re-sort and update
    _sortAndUpdateTimetable();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course deleted. It will be restored when you refresh.'),
          backgroundColor: Color.fromARGB(255, 122, 133, 133),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Load custom courses from SharedPreferences
  Future<void> _loadCustomCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedCustomCourses = prefs.getString('custom_courses');
    
    if (savedCustomCourses != null) {
      try {
        List<dynamic> decoded = json.decode(savedCustomCourses);
        customCourses.forEach((key, value) => value.clear());
        
        for (var course in decoded) {
          String day = course['Day'] ?? '';
          if (customCourses.containsKey(day)) {
            customCourses[day]!.add({
              'Time': course['Time'] ?? '',
              'Subject': course['Subject'] ?? '',
              'id': course['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            });
          }
        }
      } catch (e) {
        print('Error loading custom courses: $e');
      }
    }
  }

  // Save custom courses to SharedPreferences
  Future<void> _saveCustomCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> coursesToSave = [];
    
    customCourses.forEach((day, classes) {
      for (var course in classes) {
        coursesToSave.add({
          'Day': day,
          'Time': course['Time'] ?? '',
          'Subject': course['Subject'] ?? '',
          'id': course['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        });
      }
    });
    
    await prefs.setString('custom_courses', json.encode(coursesToSave));
  }

  // **IMPROVEMENT**: Made time parsing more robust. It now returns a predictable
  // date on failure to prevent unpredictable sorting or comparison behavior.
  // Handles both 24-hour format (HH:mm) and 12-hour format (h:mm AM/PM)
  DateTime _parseTime(String time) {
    try {
      final timeTrimmed = time.trim();
      
      // First try 24-hour format (HH:mm)
      final time24Pattern = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9])$');
      final match24 = time24Pattern.firstMatch(timeTrimmed);
      
      if (match24 != null) {
        int hours = int.parse(match24.group(1)!);
        int minutes = int.parse(match24.group(2)!);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hours, minutes);
      }
      
      // Fallback to 12-hour format (h:mm AM/PM)
      final regExp = RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)?', caseSensitive: false);
      final match = regExp.firstMatch(timeTrimmed);

      if (match == null) return DateTime(1970); // Return a very old date on failure

      int hours = int.parse(match.group(1)!);
      int minutes = int.parse(match.group(2)!);
      String? period = match.group(3)?.toUpperCase();

      if (period != null) {
        if (period == "PM" && hours != 12) hours += 12;
        if (period == "AM" && hours == 12) hours = 0; // Midnight case
      }
      
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hours, minutes);
    } catch (e) {
      print("Error parsing time '$time': $e");
      return DateTime(1970); // Return a very old date on failure
    }
  }

  // **IMPROVEMENT**: Complete rewrite of this function for correctness.
  // It now finds the next class across multiple days.
  void _findCurrentAndNextClass() {
    DateTime now = DateTime.now();
    int todayIndex = now.weekday - 1;
    String today = daysOfWeek[todayIndex];
    List<Map<String, String>> todayClasses = timetable[today] ?? [];

    // Reset state variables
    String foundCurrentClass = "No class currently";
    String foundCurrentClassEndTime = "";
    String foundNextClass = "No class scheduled";
    String foundNextClassInfo = "";

    // Find current and next class for today
    for (var entry in todayClasses) {
      final timeParts = entry['Time']!.split(' - ');
      if (timeParts.length != 2) continue; // Skip malformed entries

      DateTime classStart = _parseTime(timeParts[0]);
      DateTime classEnd = _parseTime(timeParts[1]);

      if (now.isAfter(classStart) && now.isBefore(classEnd)) {
        foundCurrentClass = entry['Subject']!;
        foundCurrentClassEndTime = timeParts[1];
      } else if (classStart.isAfter(now) && foundNextClass == "No class scheduled") {
        foundNextClass = entry['Subject']!;
        foundNextClassInfo = "at ${entry['Time']!}";
      }
    }

    // If no next class is found today, search subsequent days
    if (foundNextClass == "No class scheduled") {
      for (int i = 1; i <= 7; i++) {
        int nextDayIndex = (todayIndex + i) % 7;
        String nextDayName = daysOfWeek[nextDayIndex];
        List<Map<String, String>> nextDayClasses = timetable[nextDayName] ?? [];

        if (nextDayClasses.isNotEmpty) {
          final firstClass = nextDayClasses.first;
          foundNextClass = firstClass['Subject']!;
          foundNextClassInfo = "on $nextDayName at ${firstClass['Time']!}";
          break; // Found the next class, so exit the loop
        }
      }
    }

    // Update the state only if values have changed to prevent unnecessary rebuilds
    if (currentClass != foundCurrentClass ||
        currentClassEndTime != foundCurrentClassEndTime ||
        nextClass != foundNextClass ||
        nextClassInfo != foundNextClassInfo) {
      setState(() {
        currentClass = foundCurrentClass;
        currentClassEndTime = foundCurrentClassEndTime;
        nextClass = foundNextClass;
        nextClassInfo = foundNextClassInfo;
      });
    }
  }

  // **IMPROVEMENT**: Refactored dropdown logic into a single handler.
  Future<void> _onSelectionChanged({String? year, String? branch}) async {
    setState(() {
      isLoading = true;
      if (year != null) selectedYear = year;
      if (branch != null) selectedBranch = branch;
    });
    await _saveSelectedOptions();
    await _fetchData();
  }

  // Show dialog to add/edit custom course
  Future<void> _showAddCourseDialog({String? day, Map<String, String>? courseToEdit, int? editIndex}) async {
    String selectedDay = day ?? daysOfWeek[0];
    String subject = courseToEdit?['Subject'] ?? '';
    String startTime = '';
    String endTime = '';
    
    if (courseToEdit != null && courseToEdit['Time'] != null) {
      final timeParts = courseToEdit['Time']!.split(' - ');
      if (timeParts.length == 2) {
        startTime = timeParts[0];
        endTime = timeParts[1];
      }
    }

    final TextEditingController subjectController = TextEditingController(text: subject);
    final TextEditingController startTimeController = TextEditingController(text: startTime);
    final TextEditingController endTimeController = TextEditingController(text: endTime);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 62, 78, 75),
              title: Text(
                courseToEdit == null ? 'Add Custom Course' : 'Edit Course',
                style: const TextStyle(color: Color(0xFFE0E2DB)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Day selector
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      dropdownColor: const Color.fromARGB(255, 122, 133, 133),
                      style: const TextStyle(color: Color(0xFFE0E2DB)),
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        labelStyle: TextStyle(color: Color(0xFFE0E2DB)),
                      ),
                      items: daysOfWeek.map((day) {
                        return DropdownMenuItem(value: day, child: Text(day));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedDay = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Subject field
                    TextField(
                      controller: subjectController,
                      style: const TextStyle(color: Color(0xFFE0E2DB)),
                      decoration: const InputDecoration(
                        labelText: 'Subject/Course Name',
                        labelStyle: TextStyle(color: Color(0xFFE0E2DB)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Start time
                    TextField(
                      controller: startTimeController,
                      style: const TextStyle(color: Color(0xFFE0E2DB)),
                      decoration: const InputDecoration(
                        labelText: 'Start Time (24-hour format)',
                        labelStyle: TextStyle(color: Color(0xFFE0E2DB)),
                        hintText: '16:00',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      // Allow full datetime input so user can type ":" and numbers
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 16),
                    // End time
                    TextField(
                      controller: endTimeController,
                      style: const TextStyle(color: Color(0xFFE0E2DB)),
                      decoration: const InputDecoration(
                        labelText: 'End Time (24-hour format)',
                        labelStyle: TextStyle(color: Color(0xFFE0E2DB)),
                        hintText: '18:00',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      // Allow full datetime input so user can type ":" and numbers
                      keyboardType: TextInputType.datetime,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(const Color(0xFFE0E2DB)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 122, 133, 133)),
                  ),
                  onPressed: () {
                    final subjectText = subjectController.text.trim();
                    final startTimeText = startTimeController.text.trim();
                    final endTimeText = endTimeController.text.trim();

                    // Validate inputs
                    if (subjectText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a subject/course name'),
                          backgroundColor: Color.fromARGB(255, 232, 76, 65),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (startTimeText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a start time'),
                          backgroundColor: Color.fromARGB(255, 232, 76, 65),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (endTimeText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an end time'),
                          backgroundColor: Color.fromARGB(255, 232, 76, 65),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    // Validate time format (24-hour format: HH:mm)
                    if (!_isValid24HourFormat(startTimeText)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid start time format. Use 24-hour format like "16:00" or "09:30"'),
                          backgroundColor: Color.fromARGB(255, 232, 76, 65),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    if (!_isValid24HourFormat(endTimeText)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid end time format. Use 24-hour format like "18:00" or "10:30"'),
                          backgroundColor: Color.fromARGB(255, 232, 76, 65),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    // Validate that end time is after start time
                    try {
                      DateTime startTime = _parseTime24(startTimeText);
                      DateTime endTime = _parseTime24(endTimeText);
                      
                      if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End time must be after start time'),
                            backgroundColor: Color.fromARGB(255, 232, 76, 65),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error parsing time. Please check the format (HH:mm)'),
                          backgroundColor: Color.fromARGB(255, 232, 76, 65),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    final timeString = '$startTimeText - $endTimeText';
                    
                    if (courseToEdit == null) {
                      // Add new course
                      final newId = DateTime.now().millisecondsSinceEpoch.toString();
                      customCourses[selectedDay]!.add({
                        'Time': timeString,
                        'Subject': subjectText,
                        'id': newId,
                      });
                    } else {
                      // Edit existing course
                      if (editIndex != null && editIndex < customCourses[selectedDay]!.length) {
                        customCourses[selectedDay]![editIndex] = {
                          'Time': timeString,
                          'Subject': subjectText,
                          'id': courseToEdit['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        };
                      }
                    }
                    
                    _saveCustomCourses();
                    _mergeCustomCourses();
                    _sortAndUpdateTimetable(); // Re-sort and update
                    Navigator.pop(context);
                  },
                  child: Text(
                    courseToEdit == null ? 'Add' : 'Save',
                    style: const TextStyle(color: Color(0xFFE0E2DB)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Validate 24-hour format (HH:mm)
  bool _isValid24HourFormat(String time) {
    if (time.isEmpty) return false;
    
    // Pattern: HH:mm where HH is 00-23 and mm is 00-59
    final time24Pattern = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9])$');
    return time24Pattern.hasMatch(time.trim());
  }

  // Parse 24-hour format time string to DateTime
  DateTime _parseTime24(String time24) {
    try {
      final parts = time24.trim().split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format');
      }
      
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      
      if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        throw FormatException('Invalid time values');
      }
      
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hours, minutes);
    } catch (e) {
      print("Error parsing 24-hour time '$time24': $e");
      return DateTime(1970); // Return a very old date on failure
    }
  }

  // Delete custom course
  Future<void> _deleteCustomCourse(String day, int index) async {
    if (index < customCourses[day]!.length) {
      customCourses[day]!.removeAt(index);
      await _saveCustomCourses();
      _mergeCustomCourses();
      _sortAndUpdateTimetable(); // Re-sort and update
    }
  }

  // Sort and update timetable without clearing data
  void _sortAndUpdateTimetable() {
    // Remove custom courses from timetable first
    timetable.forEach((day, classes) {
      classes.removeWhere((course) => course['isCustom'] == 'true');
    });
    
    // Merge custom courses back
    _mergeCustomCourses();
    
    // Sort classes by time
    timetable.forEach((day, classes) {
      classes.sort((a, b) {
        try {
          DateTime timeA = _parseTime(a['Time']!.split(' - ')[0]);
          DateTime timeB = _parseTime(b['Time']!.split(' - ')[0]);
          return timeA.compareTo(timeB);
        } catch (_) {
          return 0;
        }
      });
    });
    
    setState(() {});
    _findCurrentAndNextClass();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 62, 78, 75),
      appBar: AppBar(
        title: const Text('Timetable', style: TextStyle(color: Colors.white, fontSize: 30)),
        backgroundColor: const Color.fromARGB(255, 62, 78, 75),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _fetchData(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dropdowns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<String>(
                value: selectedYear,
                dropdownColor: const Color.fromARGB(255, 122, 133, 133),
                style: const TextStyle(color: Colors.white, fontSize: 20),
                items: apiUrls.keys.map((year) {
                  return DropdownMenuItem<String>(value: year, child: Text(year));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null && newValue != selectedYear) {
                    _onSelectionChanged(year: newValue);
                  }
                },
              ),
              DropdownButton<String>(
                value: selectedBranch,
                dropdownColor: const Color.fromARGB(255, 122, 133, 133),
                style: const TextStyle(color: Colors.white, fontSize: 20),
                items: apiUrls[selectedYear]!.keys.map((branch) {
                  return DropdownMenuItem<String>(value: branch, child: Text(branch));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null && newValue != selectedBranch) {
                    _onSelectionChanged(branch: newValue);
                  }
                },
              ),
            ],
          ),

          // Class Info Cards
          if (!isLoading) ...[
            Card(
              color: const Color.fromARGB(255, 122, 133, 133),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  currentClass == "No class currently"
                      ? "No Class Ongoing"
                      : "Current: $currentClass (Ends at $currentClassEndTime)",
                  style: const TextStyle(color: Color.fromARGB(255, 237, 240, 231), fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Card(
              color: const Color.fromARGB(255, 122, 133, 133),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  nextClass == "No class scheduled"
                      ? "No Upcoming Classes Today"
                      : "Next: $nextClass $nextClassInfo", // Using the improved info string
                  style: const TextStyle(color: Color.fromARGB(255, 237, 240, 231), fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          
          // Body Content: Loading, Error, or Timetable
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : errorMessage != null
                    ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.white70, fontSize: 16)))
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: daysOfWeek.length,
                        itemBuilder: (context, index) {
                          String day = daysOfWeek[index];
                          var dayClasses = timetable[day] ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(day, style: const TextStyle(color: Color.fromARGB(255, 237, 240, 231), fontSize: 32, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: dayClasses.isEmpty
                                  ? const Center(child: Text("No classes scheduled.", style: TextStyle(color: Colors.white70, fontSize: 18)))
                                  : ListView.builder(
                                      itemCount: dayClasses.length,
                                      itemBuilder: (context, i) {
                                        var entry = dayClasses[i];
                                        bool isCustom = entry['isCustom'] == 'true';
                                        String courseId = entry['id'] ?? '';
                                        
                                        // Find index in custom courses for editing/deleting
                                        int customIndex = -1;
                                        if (isCustom) {
                                          customIndex = customCourses[day]!.indexWhere((c) => c['id'] == courseId);
                                        }
                                        
                                        // Get course key for API courses
                                        String apiCourseKey = entry['courseKey'] ?? '';
                                        
                                        return Dismissible(
                                          key: Key('${day}_${i}_${isCustom ? courseId : apiCourseKey}'),
                                          direction: DismissDirection.endToStart, // Allow swipe for both types
                                          background: Container(
                                            color: const Color.fromARGB(255, 232, 76, 65),
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(right: 20),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.delete, color: Colors.white),
                                                if (!isCustom)
                                                  const Padding(
                                                    padding: EdgeInsets.only(top: 4),
                                                    child: Text(
                                                      'Will restore\non refresh',
                                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: const Color.fromARGB(255, 62, 78, 75),
                                                title: const Text('Delete Course', style: TextStyle(color: Color(0xFFE0E2DB))),
                                                content: Text(
                                                  isCustom
                                                      ? 'Are you sure you want to delete "${entry['Subject']}"?'
                                                      : 'Delete "${entry['Subject']}"?\n\nThis course will be restored when you refresh.',
                                                  style: const TextStyle(color: Color(0xFFE0E2DB)),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    style: ButtonStyle(
                                                      foregroundColor: WidgetStateProperty.all(const Color(0xFFE0E2DB)),
                                                    ),
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                    ElevatedButton(
                                                    style: ButtonStyle(
                                                      backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 232, 76, 65)),
                                                    ),
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            ) ?? false;
                                          },
                                          onDismissed: (direction) {
                                            if (isCustom && customIndex >= 0) {
                                              _deleteCustomCourse(day, customIndex);
                                            } else if (!isCustom && apiCourseKey.isNotEmpty) {
                                              _deleteApiCourse(day, apiCourseKey);
                                            }
                                          },
                                          child: Card(
                                            color: isCustom 
                                              ? const Color.fromARGB(255, 100, 120, 120) 
                                              : const Color.fromARGB(255, 122, 133, 133),
                                            elevation: 3,
                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.all(15),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      entry['Subject'] ?? '',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 22,
                                                        color: Color.fromARGB(255, 237, 240, 231),
                                                      ),
                                                    ),
                                                  ),
                                                  if (isCustom)
                                                    const Icon(
                                                      Icons.edit,
                                                      color: Color(0xFFE0E2DB),
                                                      size: 20,
                                                    ),
                                                ],
                                              ),
                                              subtitle: Text(
                                                entry['Time'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color.fromARGB(255, 237, 240, 231),
                                                ),
                                              ),
                                              minTileHeight: 80,
                                              onTap: isCustom && customIndex >= 0
                                                ? () {
                                                    _showAddCourseDialog(
                                                      day: day,
                                                      courseToEdit: customCourses[day]![customIndex],
                                                      editIndex: customIndex,
                                                    );
                                                  }
                                                : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 122, 133, 133),
        onPressed: () => _showAddCourseDialog(),
        child: const Icon(Icons.add, color: Color(0xFFE0E2DB)),
      ),
    );
  }
}