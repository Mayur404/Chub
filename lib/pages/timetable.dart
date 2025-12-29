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
    await _fetchData(isInitialLoad: true);
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

  Future<void> _fetchData({bool isInitialLoad = false}) async {
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
        setState(() { isLoading = false; }); // Show cached data immediately
      }
    }

    try {
      final apiUrl = apiUrls[selectedYear]![selectedBranch]!;
      final response = await ApiService(apiUrl: apiUrl).fetchData();
      await prefs.setString(cacheKey, json.encode(response));
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
    // Clear existing data
    timetable.forEach((key, value) => value.clear());

    for (var entry in data) {
      final String day = entry['Day'] ?? '';
      final String time = entry['Time'] ?? '';
      final String subject = entry['Subject'] ?? '';

      if (timetable.containsKey(day) && time.isNotEmpty && subject.isNotEmpty) {
        timetable[day]!.add({'Time': time, 'Subject': subject});
      }
    }

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

  // **IMPROVEMENT**: Made time parsing more robust. It now returns a predictable
  // date on failure to prevent unpredictable sorting or comparison behavior.
  DateTime _parseTime(String time) {
    try {
      final regExp = RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)?', caseSensitive: false);
      final match = regExp.firstMatch(time.trim());

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
                                        return Card(
                                          color: const Color.fromARGB(255, 122, 133, 133),
                                          elevation: 3,
                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.all(15),
                                            title: Text(entry['Subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color.fromARGB(255, 237, 240, 231))),
                                            subtitle: Text(entry['Time'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color.fromARGB(255, 237, 240, 231))),
                                            minTileHeight: 80,
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
    );
  }
}