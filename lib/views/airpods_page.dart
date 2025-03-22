import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AirpodsPage extends StatefulWidget {
  const AirpodsPage({Key? key}) : super(key: key);

  @override
  State<AirpodsPage> createState() => _AirpodsPageState();
}

class _AirpodsPageState extends State<AirpodsPage> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  String connectionStatus = "";

  @override
  void initState() {
    super.initState();
    requestPermissions();

    // Listen for connection state changes to update the UI
    // Listen to connection state changes
    FlutterBluePlus.events.onConnectionStateChanged.listen((event) {
      if (event.device.remoteId == connectedDevice?.remoteId) {
        if (event.connectionState == BluetoothConnectionState.connected) {
          setState(() {
            connectionStatus = "Connected to ${event.device.platformName}";
          });
        } else if (event.connectionState ==
            BluetoothConnectionState.disconnected) {
          if (connectedDevice?.remoteId == event.device.remoteId) {
            setState(() {
              connectionStatus =
                  "Device disconnected: ${event.device.platformName}";
              // Only clear connectedDevice if it's the same device that got disconnected
              connectedDevice = null;
            });
          }
        }
      }
    });
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    setState(() {
      connectionStatus = "Ready to scan";
    });
  }

  void scanForDevices() async {
    // Check if Bluetooth is on
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      setState(() {
        connectionStatus = "Please turn on Bluetooth";
      });
      return;
    }

    // Stop any previous scan
    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
    }

    setState(() {
      devices.clear();
      isScanning = true;
      connectionStatus = "Scanning...";
    });

    try {
      // Use the withServices parameter to filter for audio devices
      // Use longer timeout since AirPods can be slow to appear
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 15),
        withServices: [], // Keep empty to scan all devices
      );

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          // Don't filter too aggressively for AirPods - they might not advertise as expected
          devices = results
              .map((result) => result.device)
              .toSet() // Remove duplicates
              .toList();
        });
      });

      // Update UI when scan completes
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      setState(() {
        isScanning = false;
        connectionStatus = "Scan completed. Found ${devices.length} devices.";
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        connectionStatus = "Error scanning: $e";
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectionStatus =
          "Connecting to ${device.name.isNotEmpty ? device.name : 'device'}...";
    });

    try {
      // Stop scanning to improve connection success
      if (await FlutterBluePlus.isScanning.first) {
        await FlutterBluePlus.stopScan();
      }

      // Set as connected device early to update UI
      setState(() {
        connectedDevice = device;
      });

      // For AirPods, we need to handle the connection differently
      // First check if already connected
      final isConnected = await device.isConnected;
      if (isConnected) {
        setState(() {
          connectionStatus = "Already connected to ${device.name}";
        });
        return;
      }

      // IMPORTANT: For AirPods, disable auto-connect and don't request MTU
      // Connect with specific parameters to avoid LINK_SUPERVISION_TIMEOUT
      await device
          .connect(
        autoConnect: false,
        timeout: Duration(seconds: 35), // Longer timeout for AirPods
      )
          .catchError((error) {
        print("Connection error: $error");
        // Don't throw - AirPods often report connection errors even when connected
      });

      // For AirPods, we often get a quick disconnect after connect
      // so we need to check the connection state after a brief delay
      await Future.delayed(Duration(seconds: 1));

      final isStillConnected = await device.isConnected;
      setState(() {
        connectionStatus = isStillConnected
            ? "Connected to ${device.name}"
            : "Connection unstable - try again";
      });
    } catch (e) {
      print("Connect exception: $e");
      setState(() {
        // Don't clear connectedDevice here since AirPods might still be partially connected
        connectionStatus = "Error connecting: $e";
      });
    }
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      setState(() {
        connectionStatus = "Disconnecting...";
      });

      try {
        // For AirPods, we might need to force disconnect
        await connectedDevice!.disconnect().catchError((e) {
          print("Error during disconnect: $e");
        });

        setState(() {
          connectedDevice = null;
          connectionStatus = "Disconnected";
        });
      } catch (e) {
        setState(() {
          connectionStatus = "Error disconnecting: $e";
          // Still clear device reference since we want UI to show disconnected
          connectedDevice = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AirPods Scanner"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              // Force refresh the Bluetooth adapter
              if (await FlutterBluePlus.isAvailable) {
                setState(() {
                  devices.clear();
                  connectedDevice = null;
                  connectionStatus = "Bluetooth refreshed";
                });
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connectionStatus,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (connectedDevice != null)
                  Text(
                    "Connected: ${connectedDevice!.name.isNotEmpty ? connectedDevice!.name : 'Unknown Device'}",
                    style: TextStyle(color: Colors.blue),
                  ),
                SizedBox(height: 8),
                Text(
                  "Note: AirPods may show as connected in system settings even if not fully connected in the app",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isScanning ? null : scanForDevices,
                  icon: Icon(Icons.search),
                  label: Text(isScanning ? "Scanning..." : "Scan for Devices"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (connectedDevice != null)
                  ElevatedButton.icon(
                    onPressed: disconnectDevice,
                    icon: Icon(Icons.link_off),
                    label: Text("Disconnect"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // Device list
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.blue.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          isScanning
                              ? "Scanning for devices..."
                              : "No devices found. Try scanning again.",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Make sure your AirPods case is open and in pairing mode",
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final bool isConnected = connectedDevice?.id == device.id;
                      final String deviceName = device.name.isNotEmpty
                          ? device.name
                          : "Unknown Device (${device.id.toString().substring(0, 8)})";

                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: isConnected ? 4 : 1,
                        color: isConnected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: Icon(
                            device.name.toLowerCase().contains("airpod")
                                ? Icons.headphones
                                : Icons.bluetooth,
                            color: isConnected ? Colors.blue : Colors.grey,
                            size: 36,
                          ),
                          title: Text(
                            deviceName,
                            style: TextStyle(
                              fontWeight: isConnected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            "Address: ${device.id}",
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            onPressed: isScanning
                                ? null
                                : (isConnected
                                    ? disconnectDevice
                                    : () => connectToDevice(device)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isConnected ? Colors.red : Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isConnected ? "Disconnect" : "Connect"),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
