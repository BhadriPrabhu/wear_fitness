// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
          seedColor: const Color(0xFF2B5876),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationContainer(),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer>
    with SingleTickerProviderStateMixin {
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
      if (!_isStreaming) return; // Retains old data when not streaming
      final random = Random();
      setState(() {
        _heartRate = 68 + random.nextInt(12);
        _spo2 = random.nextInt(100) > 92 ? 98 : 96;
        _pwv = double.parse(
          (7.8 + random.nextDouble() * 2.5).toStringAsFixed(1),
        );
        _flowStatus = _pwv > 9.5 ? 'Elevated' : 'Optimal';

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
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2B5876),
        content: Text(
          _isStreaming
              ? 'Resumed live device stream'
              : 'Paused live device stream (Showing last recorded data)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBluetoothScanner() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nearby Devices'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bluetooth, color: Color(0xFF2B5876)),
                title: const Text('ESP32_WearFit'),
                subtitle: const Text('Signal: -45 dBm'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleStreaming();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B5876),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isStreaming ? 'Disconnect' : 'Connect'),
                ),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.bluetooth, color: Colors.grey),
                title: Text('Unknown Device'),
                subtitle: Text('Signal: -88 dBm'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // AI Assistant Bottom Sheet
  void _showAIAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isWarning = _pwv > 9.5;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'WearFit AI',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                isWarning
                    ? 'I noticed your Pulse Wave Velocity (PWV) is currently at $_pwv m/s, which is elevated. Your heart rate is $_heartRate bpm. I recommend taking a moment to rest, drinking some water, and re-evaluating in 5 minutes.'
                    : 'Your vascular metrics look fantastic right now! Your PWV is stable at $_pwv m/s, and your tissue oxygenation is highly optimal at $_spo2%. Keep up the good work.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B5876),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboardView(),
      _buildTrendsView(),
      _buildBreathingView(),
      _buildProfileView(),
      _buildSettingsView(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.watch,
              color: _isStreaming ? const Color(0xFF2B5876) : Colors.grey,
            ),
            const SizedBox(width: 8),
            const Text(
              'WearFit',
              style: TextStyle(
                color: Color(0xFF2B5876),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
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
                  color: _batteryLevel > 20 ? Colors.green[700] : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isStreaming
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: _isStreaming ? Colors.blueAccent : Colors.grey,
            ),
            tooltip: 'BLE Streaming',
            onPressed: _showBluetoothScanner,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton.extended(
                onPressed: _showAIAssistant,
                backgroundColor: const Color(0xFF4E4376),
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  'AI Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF2B5876),
            unselectedItemColor: Colors.grey[400],
            backgroundColor: Colors.white,
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights_rounded),
                label: 'Trends',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.air_rounded),
                label: 'Therapy',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VIEW 1: DASHBOARD VIEW ---
  Widget _buildDashboardView() {
    bool isWarning = _pwv > 9.5;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conditionally render the LIVE PPG SENSOR based on streaming status
          if (_isStreaming) ...[
            Container(
              width: double.infinity,
              height: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B5876).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LIVE PPG SENSOR',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (_isStreaming)
                        const Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.greenAccent,
                              size: 10,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'REC',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Expanded(child: LiveWaveform()),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            _isStreaming ? 'Primary Vitals' : 'Last Recorded Vitals',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            childAspectRatio: 1.1,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildModernVitalCard(
                'Heart Rate',
                '$_heartRate',
                'bpm',
                Icons.favorite,
                Colors.redAccent,
                isGlowing: false,
              ),
              _buildModernVitalCard(
                'Blood Oxygen',
                '$_spo2',
                '%',
                Icons.water_drop_outlined,
                Colors.lightBlue,
                isGlowing: false,
              ),
              _buildModernVitalCard(
                'Pulse Wave Vel.',
                '$_pwv',
                _metricUnits ? 'm/s' : 'ft/s',
                Icons.speed,
                isWarning ? Colors.orange : Colors.deepPurple,
                isGlowing: isWarning,
              ),
              _buildModernVitalCard(
                'Vascular Tone',
                _flowStatus,
                '',
                Icons.waves,
                isWarning ? Colors.orange : Colors.teal,
                isGlowing: isWarning,
              ),
            ],
          ),

          const SizedBox(height: 80), // Padding for FAB
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
            '7-Day Vascular Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          _buildVisualChart(),
          const SizedBox(height: 24),
          _buildTrendAnalyticsRow(
            'Average PWV',
            '8.1 m/s',
            Colors.deepPurple,
            Icons.trending_flat,
          ),
          _buildTrendAnalyticsRow(
            'Est. ABI Ratio',
            '1.05 (Normal)',
            Colors.green,
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text(
                'Export 7-Day Clinical Report',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2B5876),
                side: const BorderSide(color: Color(0xFF2B5876), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating PDF report...'),
                    backgroundColor: Color(0xFF4E4376),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 3 (NEW): VASCULAR COHERENCE THERAPY ---
  Widget _buildBreathingView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Coherence Training',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sync your breath with the visualizer to lower vascular stiffness and optimize blood flow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // The Interactive Breathing Orb
            const CoherenceOrb(),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModernVitalCard(
                  'Live HR',
                  '$_heartRate',
                  'bpm',
                  Icons.favorite,
                  Colors.redAccent,
                  isGlowing: false,
                ),
                _buildModernVitalCard(
                  'Current PWV',
                  '$_pwv',
                  'm/s',
                  Icons.speed,
                  Colors.deepPurple,
                  isGlowing: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- VIEW 3: PROFILE VIEW ---
  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Color(0xFF2B5876)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'John Doe',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const Text(
            'Patient ID: #CS-99210',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          _buildHardwareInfoTile(
            'Main Controller',
            'ESP32 Microcontroller',
            Icons.developer_board,
          ),
          _buildHardwareInfoTile(
            'Biosensors connected',
            'Dual MAX30102 PPG Array',
            Icons.sensors,
          ),
          _buildHardwareInfoTile(
            'Sync Status',
            'Secure Cloud Encryption Active',
            Icons.cloud_done,
          ),
        ],
      ),
    );
  }

  // --- VIEW 4: SETTINGS VIEW ---
  Widget _buildSettingsView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Preferences',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Clinical Alerts'),
          subtitle: const Text('Push notifications for abnormal PWV'),
          secondary: const Icon(
            Icons.notifications_active,
            color: Color(0xFF2B5876),
          ),
          activeColor: const Color(0xFF2B5876),
          value: _notificationsEnabled,
          onChanged:
              (bool value) => setState(() => _notificationsEnabled = value),
        ),
        SwitchListTile(
          title: const Text('Metric Units'),
          subtitle: const Text('Toggle m/s vs ft/s'),
          secondary: const Icon(Icons.straighten, color: Color(0xFF2B5876)),
          activeColor: const Color(0xFF2B5876),
          value: _metricUnits,
          onChanged: (bool value) => setState(() => _metricUnits = value),
        ),
      ],
    );
  }

  // --- WIDGET BUILD COMPONENT UTILITIES ---

  Widget _buildModernVitalCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color accentColor, {
    bool isGlowing = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            isGlowing
                ? Border.all(color: accentColor.withOpacity(0.5), width: 2)
                : Border.all(color: Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(
            color:
                isGlowing
                    ? accentColor.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
            blurRadius: isGlowing ? 20 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              if (isGlowing)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isGlowing ? accentColor : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalyticsRow(
    String metric,
    String target,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: 12),
              Text(
                metric,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            target,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: accentColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualChart() {
    final List<double> pastWeekData = [8.0, 7.9, 8.2, 8.8, 8.1, 7.8, _pwv];

    return Container(
      padding: const EdgeInsets.all(20),
      height: 250, // Increased height for better visibility
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 12, // Set based on expected PWV ranges
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: 2,
            getDrawingHorizontalLine:
                (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget:
                    (value, meta) => Text(
                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value
                          .toInt()],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(pastWeekData.length, (i) {
            final isHigh = pastWeekData[i] > 9.5;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: pastWeekData[i],
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors:
                        isHigh
                            ? [Colors.orange, Colors.red]
                            : [Colors.blue.shade200, Colors.blue.shade900],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHardwareInfoTile(
    String component,
    String status,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2B5876).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2B5876)),
        ),
        title: Text(
          component,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          status,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ),
    );
  }
}

// =====================================================================
// WOW FEATURE: CUSTOM PAINTER FOR LIVE ECG/PPG WAVEFORM
// =====================================================================
class LiveWaveform extends StatefulWidget {
  const LiveWaveform({super.key});

  @override
  State<LiveWaveform> createState() => _LiveWaveformState();
}

class _LiveWaveformState extends State<LiveWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: WaveformPainter(_controller.value),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;
  WaveformPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.greenAccent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final double width = size.width;
    final double height = size.height;
    final double midY = height / 2;

    for (double x = 0; x < width; x++) {
      double shiftedX = (x + (animationValue * width)) % width;
      double y = midY;

      if (shiftedX % 100 < 10) {
        y -= 5;
      } else if (shiftedX % 100 > 15 && shiftedX % 100 < 25) {
        y -= 30 * sin((shiftedX % 100 - 15) * pi / 10);
      } else if (shiftedX % 100 > 25 && shiftedX % 100 < 35) {
        y += 15 * sin((shiftedX % 100 - 25) * pi / 10);
      } else if (shiftedX % 100 > 50 && shiftedX % 100 < 70) {
        y -= 10 * sin((shiftedX % 100 - 50) * pi / 20);
      }

      y += (sin(x * 0.5) * 1.5);

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final rect = Rect.fromLTWH(0, 0, width, height);
    final gradient = LinearGradient(
      colors: [
        const Color(0xFF2B5876),
        const Color(0xFF2B5876).withOpacity(0.0),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.0, 0.3],
    ).createShader(rect);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = gradient
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =====================================================================
// WOW FEATURE 2: VASCULAR COHERENCE BREATHING ORB
// =====================================================================
class CoherenceOrb extends StatefulWidget {
  const CoherenceOrb({super.key});

  @override
  State<CoherenceOrb> createState() => _CoherenceOrbState();
}

class _CoherenceOrbState extends State<CoherenceOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // 10 second full cycle: 5s inhale, 5s exhale
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        String breathText =
            _controller.status == AnimationStatus.forward ? "Inhale" : "Exhale";

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Halo
            Container(
              width: 200 * _scaleAnimation.value,
              height: 200 * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF4E4376,
                    ).withOpacity(_opacityAnimation.value),
                    const Color(0xFF2B5876).withOpacity(0.0),
                  ],
                ),
              ),
            ),
            // Inner Solid Core
            Container(
              width: 120 * (_scaleAnimation.value * 0.8),
              height: 120 * (_scaleAnimation.value * 0.8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B5876).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5 * _scaleAnimation.value,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  breathText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
