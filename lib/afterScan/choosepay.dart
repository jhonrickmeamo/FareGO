import 'package:flutter/material.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  final TextEditingController _destinationController = TextEditingController(
    text: "Housing terminal jeep c5",
  );

  String? _selectedDestination;
  String? _paymentMethod;

  final List<String> destinations = [
    "C5 Road",
    "Market Avenue",
    "City Center",
    "Tech Park",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3DE1D4), Color(0xFFE6F9F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Destination",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Input field
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Enter destination",
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDestination,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  hint: const Text("Select Destination"),
                  items: destinations.map((dest) {
                    return DropdownMenuItem(value: dest, child: Text(dest));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDestination = value;
                    });
                  },
                ),

                const SizedBox(height: 15),

                // Radio buttons
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text("Student"),
                      value: "Student",
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
                      activeColor: Colors.teal,
                    ),
                    RadioListTile<String>(
                      title: const Text("GCash"),
                      value: "GCash",
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
                      activeColor: Colors.teal,
                    ),
                    RadioListTile<String>(
                      title: const Text("Cash"),
                      value: "Cash",
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
                      activeColor: Colors.teal,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11CDA4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      // Add confirm logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Destination: ${_destinationController.text}, "
                            "Selected: $_selectedDestination, "
                            "Payment: $_paymentMethod",
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Confirm",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
