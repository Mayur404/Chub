import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const DebtTrackerApp());
}

class DebtTrackerApp extends StatelessWidget {
  const DebtTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const DebtTrackerPage(),
    );
  }
}

class Debt {
  String name;
  String type;
  double amount;

  Debt({required this.name, required this.type, required this.amount});

  Map<String, dynamic> toJson() {
    return {"name": name, "type": type, "amount": amount};
  }

  // A safer factory method to prevent crashes from bad data.
  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      name: json["name"] ?? 'No Name',
      type: json["type"] ?? 'I owe',
      amount: (json["amount"] ?? 0.0).toDouble(),
    );
  }
}

class DebtTrackerPage extends StatefulWidget {
  const DebtTrackerPage({super.key});

  @override
  State<DebtTrackerPage> createState() => _DebtTrackerPageState();
}

class _DebtTrackerPageState extends State<DebtTrackerPage> {
  List<Debt> debts = [];

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _saveDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final debtsJson = jsonEncode(debts.map((d) => d.toJson()).toList());
    await prefs.setString('debts', debtsJson);
  }

  Future<void> _loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final debtsJson = prefs.getString('debts');
    if (debtsJson != null) {
      final List<dynamic> decoded = jsonDecode(debtsJson);
      setState(() {
        debts = decoded.map((d) => Debt.fromJson(d)).toList();
      });
    }
  }

  void _addDebt() {
    String name = "";
    String type = "I owe";
    double amount = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 62, 78, 75),
          title: const Text("Add Debt", style: TextStyle(color: Color(0xFFE0E2DB))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Color(0xFFE0E2DB)),
                  decoration: const InputDecoration(
                      labelText: "Name", labelStyle: TextStyle(color: Color(0xFFE0E2DB))),
                  onChanged: (value) => name = value,
                ),
                DropdownButtonFormField<String>(
                  style: const TextStyle(color: Color(0xFFE0E2DB)),
                  dropdownColor: const Color.fromARGB(255, 122, 133, 133),
                  decoration: const InputDecoration(
                      labelText: "Type", labelStyle: TextStyle(color: Color(0xFFE0E2DB))),
                  value: type,
                  items: ["I owe", "Owes me"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => type = value!,
                ),
                TextField(
                  style: const TextStyle(color: Color(0xFFE0E2DB)),
                  decoration: const InputDecoration(
                      labelText: "Amount", labelStyle: TextStyle(color: Color(0xFFE0E2DB))),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    amount = double.tryParse(value) ?? 0.0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(const Color(0xFFE0E2DB))),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(const Color.fromARGB(255, 122, 133, 133))),
              onPressed: () {
                if (name.trim().isNotEmpty && amount > 0) {
                  setState(() {
                    debts.add(Debt(name: name.trim(), type: type, amount: amount));
                    _saveDebts();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add", style: TextStyle(color: Color(0xFFE0E2DB))),
            ),
          ],
        );
      },
    );
  }

  // Edit debt
  void _editDebt(int index) {
    String name = debts[index].name;
    String type = debts[index].type;
    double amount = debts[index].amount;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 62, 78, 75),
          title: const Text("Edit Debt", style: TextStyle(color: Color(0xFFE0E2DB))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Color(0xFFE0E2DB)),
                  decoration: const InputDecoration(
                      labelText: "Name", labelStyle: TextStyle(color: Color(0xFFE0E2DB))),
                  controller: TextEditingController(text: name),
                  onChanged: (value) => name = value,
                ),
                DropdownButtonFormField<String>(
                  style: const TextStyle(color: Color(0xFFE0E2DB)),
                  dropdownColor: const Color.fromARGB(255, 122, 133, 133),
                  decoration: const InputDecoration(
                      labelText: "Type", labelStyle: TextStyle(color: Color(0xFFE0E2DB))),
                  value: type,
                  items: ["I owe", "Owes me"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => type = value!,
                ),
                TextField(
                  style: const TextStyle(color: Color(0xFFE0E2DB)),
                  decoration: const InputDecoration(
                      labelText: "Amount", labelStyle: TextStyle(color: Color(0xFFE0E2DB))),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: amount.toStringAsFixed(2)),
                  onChanged: (value) {
                    amount = double.tryParse(value) ?? 0.0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(const Color(0xFFE0E2DB))),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(const Color.fromARGB(255, 122, 133, 133))),
              onPressed: () {
                if (name.trim().isNotEmpty && amount > 0) {
                  setState(() {
                    debts[index] = Debt(name: name.trim(), type: type, amount: amount);
                    _saveDebts();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save", style: TextStyle(color: Color(0xFFE0E2DB))),
            ),
          ],
        );
      },
    );
  }

  void _deleteDebt(int index) {
    setState(() {
      debts.removeAt(index);
      _saveDebts();
    });
  }

  Future<bool?> _showDeleteConfirmationDialog(String debtName) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 62, 78, 75),
          title: const Text("Delete Debt", style: TextStyle(color: Color(0xFFE0E2DB))),
          content: Text("Are you sure you want to delete the debt for '$debtName'?",
              style: const TextStyle(color: Color(0xFFE0E2DB))),
          actions: [
            TextButton(
              style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(const Color(0xFFE0E2DB))),
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 232, 76, 65))),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double iOweTotal =
        debts.where((d) => d.type == 'I owe').fold(0.0, (sum, d) => sum + d.amount);
    double owesMeTotal =
        debts.where((d) => d.type == 'Owes me').fold(0.0, (sum, d) => sum + d.amount);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE0E2DB)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        backgroundColor: const Color.fromARGB(255, 62, 78, 75),
        title: const Text(
          'Debt Tracker',
          style: TextStyle(
            color: Color(0xFFE0E2DB),
            fontSize: 30,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 62, 78, 75),
      body: Column(
        children: [
          Card(
            color: const Color.fromARGB(255, 122, 133, 133),
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text("You Owe", style: TextStyle(color: Color(0xFFE0E2DB), fontSize: 16)),
                      Text("₹${iOweTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text("Owed To You", style: TextStyle(color: Color(0xFFE0E2DB), fontSize: 16)),
                      Text("₹${owesMeTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: debts.isEmpty
                ? const Center(
                    child: Text("No debts added yet!",
                        style: TextStyle(color: Color(0xFFE0E2DB), fontSize: 30)))
                : ListView.builder(
                    itemCount: debts.length,
                    itemBuilder: (context, index) {
                      final debt = debts[index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await _showDeleteConfirmationDialog(debt.name);
                        },
                        onDismissed: (direction) {
                          _deleteDebt(index);
                        },
                        background: Container(
                          color: const Color.fromARGB(255, 232, 76, 65),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          color: const Color.fromARGB(255, 122, 133, 133),
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          child: ListTile(
                            title: Text(debt.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: Color(0xFFE0E2DB))),
                            subtitle: Text("${debt.type} ₹${debt.amount.toStringAsFixed(2)}",
                                style: const TextStyle(color: Color(0xFFE0E2DB))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFFE0E2DB)),
                                  onPressed: () => _editDebt(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Color(0xFFE0E2DB)),
                                  onPressed: () async {
                                    final bool? confirmed = await _showDeleteConfirmationDialog(debt.name);
                                    if (confirmed == true) {
                                      _deleteDebt(index);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 122, 133, 133),
        onPressed: _addDebt,
        child: const Icon(Icons.add, color: Color(0xFFE0E2DB)),
      ),
    );
  }
}
