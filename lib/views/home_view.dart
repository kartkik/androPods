import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'battery_progress_view.dart';
import 'airpods_page.dart';
import 'settings_page.dart';

class BluetoothDetector extends StatefulWidget {
  @override
  _BluetoothDetectorState createState() => _BluetoothDetectorState();
}

class _BluetoothDetectorState extends State<BluetoothDetector> {
  List<BluetoothDevice> devices = [];

  int selectedIndex = 0;
  int batteryLevel = 75; // Example battery level
  double _currentVolume = 0.5; // Default volume level

  bool isPlaying = false;
  double progress = 0.3; // Default progress (30%)
  bool isBluetoothOn = false;

  // Main content of the current page
  Widget _buildCurrentPage() {
    switch (selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return AirpodsPage();
      case 2:
        return SettingsPage();
      default:
        return _buildHomePage();
    }
  }

  // Home page content
  Widget _buildHomePage() {
    return Column(
      children: [
        // Top Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.menu),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "My App",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications),
              ),
            ],
          ),
        ),

        // Battery Level & Other Widgets
        Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Battery Progress Container
              Container(
                height: 170,
                width: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Shadow color
                      blurRadius: 10, // Softness of shadow
                      spreadRadius: 2, // How much the shadow spreads
                      offset: Offset(4, 4), // Shadow position (x, y)
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 80,
                        child: CustomPaint(
                          size: Size(150, 120),
                          painter: BatteryProgressPainter(
                            progress: batteryLevel / 100,
                          ),
                        ),
                      ),
                      Text(
                        "${batteryLevel.toInt()}%",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                height: 170,
                width: 170,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20), // Apply border radius to image
                  child: Image.asset(
                    'assets/airpods.jpg', // Ensure correct image path
                    height: 200, // Match container height
                    width: 170, // Match container width
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),

        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: 25,
                  bottom: 10,
                  right: 10,
                  top: 10), // Added left padding
              child: Column(
                children: [
                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! < -10) {
                        // Detects swipe up
                        _increaseVolume();
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(
                            20), // Optional: Rounded corners
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Black Container on the right
            Container(
              height: 180,
              width: 260,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album Cover + Song Title
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded album image
                          child: Image.asset(
                            'assets/airpods.jpg', // Add your album image in assets
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Song Title",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Artist Name",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    // Progress Bar
                    Slider(
                      value: progress,
                      onChanged: (value) {
                        setState(() {
                          progress = value;
                        });
                      },
                      min: 0,
                      max: 1,
                      activeColor: Colors.white,
                      inactiveColor: Colors.grey[700],
                    ),

                    // Music Controls (Previous, Play/Pause, Next)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.skip_previous,
                              color: Colors.white, size: 30),
                          onPressed: () {
                            // Handle previous action
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            color: Colors.white,
                            size: 50,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next,
                              color: Colors.white, size: 30),
                          onPressed: () {
                            // Handle next action
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Distributes items evenly
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: 10, top: 20, bottom: 20), // Left padding for first box
              child: Container(
                height: 60,
                width: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Shadow color
                      blurRadius: 10, // Softness of shadow
                      spreadRadius: 2, // How much the shadow spreads
                      offset: Offset(2, 2), // Shadow position (x, y)
                    ),
                  ],
                ),
                child: Center(
                  child: Text("Sound"),
                ),
              ),
            ),

            // Corrected Spacing Between Boxes
            SizedBox(width: 20),

            Padding(
              padding: EdgeInsets.only(
                  right: 10,
                  top: 20,
                  bottom: 20), // Right padding for second box
              child: Container(
                height: 60,
                width: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Shadow color
                      blurRadius: 10, // Softness of shadow
                      spreadRadius: 2, // How much the shadow spreads
                      offset: Offset(2, 2), // Shadow position (x, y)
                    ),
                  ],
                ),
                child: Center(
                  child: Text("Mute"),
                ),
              ),
            ),
          ],
        ),
        Divider(),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Ensure space between elements
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 30,
              ),
              child: Row(
                children: [
                  Icon(Icons.bluetooth,
                      color: Colors.black, size: 20), // Bluetooth icon
                  SizedBox(width: 10), // Space between icon and text
                  Text(
                    "Bluetooth",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                right: 20,
              ),
              child: Switch(
                value: isBluetoothOn, // Boolean variable to track state
                onChanged: (bool value) {
                  setState(() {
                    isBluetoothOn = value; // Toggle Bluetooth state
                  });
                },
              ),
            )
          ],
        ),
        Divider(),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Ensure space between elements
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 30,
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi,
                      color: Colors.black, size: 20), // Bluetooth icon
                  SizedBox(width: 10), // Space between icon and text
                  Text(
                    "Wifi",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                right: 20,
              ),
              child: Switch(
                value: isBluetoothOn, // Boolean variable to track state
                onChanged: (bool value) {
                  setState(() {
                    isBluetoothOn = value; // Toggle Bluetooth state
                  });
                },
              ),
            )
          ],
        )
      ],
    );
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    scanForDevices();
    _getCurrentVolume();
  }

  /// Request necessary Bluetooth permissions
  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  void _getCurrentVolume() async {
    double? volume = await FlutterVolumeController.getVolume();
    setState(() {
      _currentVolume = volume!;
    });
  }

  // Increase volume on swipe up
  void _increaseVolume() async {
    if (_currentVolume < 1.0) {
      double newVolume = (_currentVolume + 0.1).clamp(0.0, 1.0);
      await FlutterVolumeController.setVolume(newVolume);
      setState(() {
        _currentVolume = newVolume;
      });
    }
  }

  /// Scan for ALL Bluetooth devices
  void scanForDevices() async {
    setState(() {
      devices.clear();
    });

    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        devices = results.map((r) => r.device).toList();
      });
    });
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildCurrentPage(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.air), label: "AirDops"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
        currentIndex: selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
