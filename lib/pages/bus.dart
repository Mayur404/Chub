import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'dart:convert';
import 'dart:async'; // Added for the Timer

class BusPage extends StatefulWidget {
  const BusPage({super.key});

  @override
  _BusPageState createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  // late Future<List<Map<String, dynamic>>> data; // This variable was declared but not used. It can be removed.
  String nextBusTime = "No buses available";
  String nextBusPickup = "";
  String nextBusDrop = "";
  Timer? _timer; // **FIX**: Added a Timer to periodically update the 'Next Bus'.

  final String apiUrl =
      'https://script.google.com/macros/s/AKfycbzZ1ctMGkHygQpuxKXQXLn-Yz1DMRQuuC0IH_zfnj8xPjpEWV1jGVNpP0I4lqaOiMzy/exec?sheet=BUS';

  Map<String, List<Map<String, String>>> busSchedule = {
    'Weekday': [],
    'Weekend/Holiday': [],
  };

  bool isWeekend = false;
  String selectedSchedule = 'Weekday';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineDayType();
    _loadAndFetchData(); // **FIX**: Consolidated data loading into one method.

    // **FIX**: Set a timer to check for the next bus every 30 seconds to keep the info current.
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _findNextBus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // **FIX**: Always cancel timers in dispose() to prevent memory leaks.
    super.dispose();
  }

  void _determineDayType() {
    DateTime now = DateTime.now();
    // Saturday is 6, Sunday is 7
    if (now.weekday == 6 || now.weekday == 7) {
      setState(() {
        isWeekend = true;
        selectedSchedule = 'Weekend/Holiday';
      });
    }
  }

  // **FIX**: Combined loadData and fetchData into a more robust single function.
  // It will:
  // - On first open: load cached data if available, otherwise fetch from network.
  // - On refresh: always fetch from network.
  Future<void> _loadAndFetchData({bool forceRefresh = false}) async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('bus_data');

    // If we have cached data, display it first for a faster user experience.
    if (savedData != null) {
      _processBusData(List<Map<String, dynamic>>.from(json.decode(savedData)));

      // If this is the automatic load on first open and we already have cached data,
      // we don't need to hit the network again. The user can always pull fresh data
      // with the refresh button.
      if (!forceRefresh) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
    }

    // If there is no cache or the user explicitly requested a refresh, fetch fresh data.
    try {
      final response = await ApiService(apiUrl: apiUrl).fetchData();
      await prefs.setString('bus_data', json.encode(response));
      if (mounted) {
        _processBusData(response);
      }
    } catch (e) {
      print('Error fetching bus data: $e');
      // If the fetch fails and we have no cached data, we can show an error.
      // For this basic fix, we just ensure the loading indicator stops.
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _processBusData(List<Map<String, dynamic>> data) {
    // Clear previous data
    busSchedule.forEach((key, value) => value.clear());

    for (var entry in data) {
      String day = entry['Day'] ?? 'Weekday';
      String time24 = entry['Time24'] ?? '00:00';
      String time12 = entry['Time'] ?? 'Unknown Time';
      String pickup = entry['Pickup'] ?? 'Unknown Pickup';
      String drop = entry['Drop'] ?? 'Unknown Destination';

      if (busSchedule.containsKey(day)) {
        busSchedule[day]!.add({
          'Time24': time24,
          'Time': time12,
          'Pickup': pickup,
          'Drop': drop,
        });
      }
    }
    // Sort schedules by time to ensure "findNextBus" works correctly.
    busSchedule.forEach((key, value) {
      value.sort((a, b) => _parseTime24(a['Time24']!).compareTo(_parseTime24(b['Time24']!)));
    });
    // Update the UI with the processed data.
    _findNextBus();
  }

  // **FIX**: Returning a fixed old date on failure is safer than returning DateTime.now().
  // This prevents malformed data from breaking the sorting and next-bus logic.
  DateTime _parseTime24(String time24) {
    try {
      var parts = time24.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      // Return a date in the past so it's always sorted first and ignored by 'isAfter'.
      return DateTime(1970);
    }
  }

  void _findNextBus() {
    DateTime now = DateTime.now();
    String newNextBusTime = "No buses available";
    String newNextBusPickup = "";
    String newNextBusDrop = "";

    // Get the schedule for the selected day type
    final schedule = busSchedule[selectedSchedule];
    if (schedule == null || schedule.isEmpty) {
        // Handle case where schedule might be empty
    } else {
        // Find the first bus in the sorted list that is after the current time
        for (var bus in schedule) {
            DateTime busTime = _parseTime24(bus['Time24']!);
            if (busTime.isAfter(now)) {
                newNextBusTime = bus['Time'] ?? "Unknown Time";
                newNextBusPickup = bus['Pickup'] ?? "Unknown Pickup";
                newNextBusDrop = bus['Drop'] ?? "Unknown Destination";
                break; // Found the next bus, so we can stop searching
            }
        }
    }
    
    // Only call setState if the information has actually changed
    if (nextBusTime != newNextBusTime || nextBusPickup != newNextBusPickup) {
        setState(() {
          nextBusTime = newNextBusTime;
          nextBusPickup = newNextBusPickup;
          nextBusDrop = newNextBusDrop;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 62, 78, 75),
      appBar: AppBar(
        title: const Text('Bus Schedule', style: TextStyle(color: Colors.white, fontSize: 30)),
        backgroundColor: const Color.fromARGB(255, 62, 78, 75),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            // Force a fresh fetch when the user explicitly taps refresh.
            onPressed: () => _loadAndFetchData(forceRefresh: true), // Use the consolidated loading function
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading && busSchedule[selectedSchedule]!.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  // Next Bus Widget
                  Card(
                    color: const Color.fromARGB(255, 122, 133, 133),
                    margin: const EdgeInsets.all(25),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text("Next Bus", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE0E2DB))),
                          const SizedBox(height: 5),
                          Text(
                            nextBusTime == "No buses available" ? "No more buses for today" : "$nextBusPickup → $nextBusDrop",
                            style: const TextStyle(fontSize: 18, color: Color(0xFFE0E2DB)),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            nextBusTime,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE0E2DB)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Schedule Selector
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Weekday", style: TextStyle(fontSize: 16, color: Color(0xFFE0E2DB))),
                        Switch(
                          activeColor: const Color(0xFFE0E2DB),
                          inactiveThumbColor: const Color.fromARGB(255, 122, 133, 133),
                          inactiveTrackColor: const Color(0xFFE0E2DB),
                          value: selectedSchedule == "Weekend/Holiday",
                          onChanged: (bool value) {
                            setState(() {
                              selectedSchedule = value ? "Weekend/Holiday" : "Weekday";
                              _findNextBus();
                            });
                          },
                        ),
                        const Text("Weekend", style: TextStyle(fontSize: 16, color: Color(0xFFE0E2DB))),
                      ],
                    ),
                  ),

                  // Bus Schedule List
                  Expanded(
                    child: ListView.builder(
                      itemCount: busSchedule[selectedSchedule]!.length,
                      itemBuilder: (context, index) {
                        final bus = busSchedule[selectedSchedule]![index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          color: const Color.fromARGB(255, 122, 133, 133),
                          child: ListTile(
                            tileColor: Colors.transparent,
                            title: Text(
                              "${bus['Pickup']} → ${bus['Drop']}",
                              style: const TextStyle(fontSize: 20, color: Color(0xFFE0E2DB)),
                            ),
                            subtitle: Text(
                              bus['Time'] ?? "Unknown Time",
                              style: const TextStyle(fontSize: 16, color: Color(0xFFE0E2DB)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}