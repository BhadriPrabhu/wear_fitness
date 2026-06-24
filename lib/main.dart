// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const SmartBandApp());
}

class SmartBandApp extends StatelessWidget {
  const SmartBandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vascular Smart Band',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const MainNavigationContainer(),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  
  // Real-time data states simulated from ESP32 BLE
  int _heartRate = 72;
  int _spo2 = 98;
  double _pwv = 8.2;
  String _flowStatus = 'Optimal';
  bool _isStreaming = true;
  int _batteryLevel = 84; 
  Timer? _dataTimer;

  // Settings states
  bool _notificationsEnabled = true;
  bool _metricUnits = true;

  @override
  void initState() {
    super.initState();
    _startLiveSensorSimulation();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    super.dispose();
  }

  // Simulates streaming data from the Wrist and Foot PPG Sensors via BLE
  void _startLiveSensorSimulation() {
    _dataTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isStreaming) return;
      final random = Random();
      setState(() {
        _heartRate = 68 + random.nextInt(10); 
        _spo2 = random.nextInt(100) > 90 ? 97 : 98; 
        _pwv = double.parse((7.9 + random.nextDouble() * 0.6).toStringAsFixed(1)); 
        _flowStatus = _pwv > 10.0 ? 'Abnormal' : 'Optimal';
        
        // Simulate slow battery drain
        if (random.nextInt(100) > 95 && _batteryLevel > 0) {
          _batteryLevel -= 1;
        }
      });
    });
  }

  void _toggleStreaming() {
    setState(() {
      _isStreaming = !_isStreaming;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isStreaming ? 'Resumed live device stream' : 'Paused live device stream'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboardView(),
      _buildTrendsView(),
      _buildProfileView(),
      _buildSettingsView(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.watch, color: _isStreaming ? Colors.blueAccent : Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'CirculSense',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '$_batteryLevel%',
                style: TextStyle(
                  color: _batteryLevel > 20 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _batteryLevel > 20 ? Icons.battery_charging_full : Icons.battery_alert,
              color: _batteryLevel > 20 ? Colors.green : Colors.red,
            ),
            tooltip: 'Battery Level',
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              _isStreaming ? Icons.bluetooth_connected : Icons.bluetooth_disabled, 
              color: _isStreaming ? Colors.blueAccent : Colors.grey
            ),
            tooltip: _isStreaming ? 'BLE Streaming Connected' : 'BLE Stream Paused',
            onPressed: _toggleStreaming,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: 'Trends'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // --- VIEW 1: DASHBOARD VIEW ---
  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Vitals Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (_isStreaming)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('Live streaming', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildVitalCard('Heart Rate', '$_heartRate', ' bpm', Icons.monitor_heart, Colors.redAccent),
              _buildVitalCard('Blood Oxygen', '$_spo2', ' %', Icons.air, Colors.lightBlue),
              _buildVitalCard('Pulse Wave Vel.', '$_pwv', _metricUnits ? ' m/s' : ' ft/s', Icons.waves, Colors.deepPurple),
              _buildVitalCard('Vascular Tone', _flowStatus, '', Icons.water_drop, Colors.teal),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'AI Vascular Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          _buildAIAnalysisCard(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _handleDoctorConnectivity(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.medical_services),
              label: const Text('Share Report with Doctor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- VIEW 2: TRENDS VIEW ---
  Widget _buildTrendsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vascular Trends History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tracking Pulse Wave Velocity (PWV) variations across wrist and limb sites over time.',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          // Visual Chart Component
          _buildVisualChart(),
          
          const SizedBox(height: 24),
          _buildTrendAnalyticsRow('PWV Average (7 days)', '8.1 m/s', Colors.deepPurple, Icons.trending_flat),
          _buildTrendAnalyticsRow('Estimated ABI Value', '1.05 (Normal)', Colors.green, Icons.check_circle_outline),
          
          const SizedBox(height: 24),
          const Text('Recent Logging Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildHistoryLogTile('Today, 10:45 AM', 'PWV: 8.2 m/s | ABI Equivalent: 1.04', Icons.history, Colors.blue),
          _buildHistoryLogTile('Yesterday, 04:20 PM', 'PWV: 8.4 m/s | ABI Equivalent: 1.02', Icons.history, Colors.blue),
          _buildHistoryLogTile('22 June 2026', 'PWV: 8.0 m/s | ABI Equivalent: 1.07', Icons.history, Colors.blue),
          _buildHistoryLogTile('21 June 2026', 'PWV: 7.9 m/s | ABI Equivalent: 1.09', Icons.history, Colors.blue),
        ],
      ),
    );
  }

  // --- VIEW 3: PROFILE VIEW ---
  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text('John Doe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Patient ID: #CS-99210', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Hardware & Smart Band Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildHardwareInfoTile('Main Controller', 'ESP32 Microcontroller', Icons.developer_board),
          _buildHardwareInfoTile('Biosensors Connected', 'Dual MAX30102 PPG Array (Wrist/Ankle)', Icons.sensors),
          _buildHardwareInfoTile('Battery Charge Status', '$_batteryLevel% (TP4056 Charge Controller)', Icons.battery_charging_full),
          _buildHardwareInfoTile('Cloud Data Synchronization', 'Active (Secure Cloud Storage)', Icons.cloud_done),
        ],
      ),
    );
  }

  // --- VIEW 4: SETTINGS VIEW (NEW) ---
  Widget _buildSettingsView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Application Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Push Notifications'),
          subtitle: const Text('Alerts for abnormal vascular parameters'),
          secondary: const Icon(Icons.notifications_active, color: Colors.blueAccent),
          value: _notificationsEnabled,
          onChanged: (bool value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Metric Units'),
          subtitle: const Text('Toggle between m/s and ft/s for PWV'),
          secondary: const Icon(Icons.straighten, color: Colors.blueAccent),
          value: _metricUnits,
          onChanged: (bool value) {
            setState(() {
              _metricUnits = value;
            });
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.download, color: Colors.blueAccent),
          title: const Text('Export Data (CSV)'),
          subtitle: const Text('Download your raw PPG and vitals history'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preparing CSV export...')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.bluetooth_searching, color: Colors.blueAccent),
          title: const Text('Pair New Smart Band'),
          subtitle: const Text('Scan for nearby CirculSense devices'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Scanning for BLE devices...')),
            );
          },
        ),
      ],
    );
  }

  // --- WIDGET BUILD COMPONENT UTILITIES ---
  Widget _buildVitalCard(String title, String value, String unit, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 30),
              const Icon(Icons.analytics_outlined, color: Colors.black12, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(unit, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    bool optimal = _flowStatus == 'Optimal';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (optimal ? Colors.green : Colors.redAccent).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              optimal ? Icons.check_circle : Icons.warning_amber, 
              color: optimal ? Colors.green : Colors.redAccent, 
              size: 32
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  optimal ? 'Circulation Optimal' : 'Circulation Warning',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  optimal 
                    ? 'Intelligent algorithms report normal vascular parameters. Early markers for PAD are well within standard ranges.'
                    : 'Elevated PWV detected. Consider notifying your practitioner to inspect potential circulation irregularities.',
                  style: const TextStyle(color: Colors.black54, height: 1.4, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalyticsRow(String metric, String target, Color accentColor, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: 12),
              Text(metric, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ],
          ),
          Text(target, style: TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildVisualChart() {
    // Simulated past 7 days data points scaled for a simple bar UI
    final List<double> pastWeekData = [8.0, 7.9, 8.2, 8.4, 8.1, 7.8, _pwv]; 
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7-Day PWV Spread', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(pastWeekData.length, (index) {
              // Normalize the bar height visually for 7.0 - 10.0 range
              double normalizedHeight = ((pastWeekData[index] - 7.0) / 3.0) * 100;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24,
                    height: normalizedHeight.clamp(10.0, 100.0), // ensure min/max bounds visually
                    decoration: BoxDecoration(
                      color: pastWeekData[index] > 8.3 ? Colors.orangeAccent : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(days[index], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLogTile(String time, String data, IconData icon, Color iconColor) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(data, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildHardwareInfoTile(String component, String status, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(component, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(status, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ),
    );
  }

  // --- ACTION FUNCTIONS ---
  void _handleDoctorConnectivity(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Encrypt & Sync Report'),
          ],
        ),
        content: const Text(
          'This action compiles your historical PWV metrics, pulse readings, and telemetry diagnostics, transferring them instantly to your synchronized clinical provider account.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vascular report securely routed to your primary care provider.')),
              );
            },
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }
}