import 'package:flutter/material.dart';
import 'data/services/hardware/hardware_service.dart';
import 'data/services/hardware/ram_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _hardware = HardwareService();
  HardwareSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _loadHardware();
  }

  Future<void> _loadHardware() async {
    final snapshot = await _hardware.getSnapshot();
    setState(() => _snapshot = snapshot);

    print(
      'Device: ${snapshot.device.fullName}, RAM: ${snapshot.ram.totalRamGb}GB, CPU: ${snapshot.cpu.chipName}, GPU: ${snapshot.gpu.renderer}',
    );
    print(
      "Ram info snapshot: Total ${snapshot.ram.totalRamGb}GB, Available ${snapshot.ram.availableRamGb}GB, Usage ${snapshot.ram.usagePercent.toStringAsFixed(1)}%",
    );
    print(
      "CPU info snapshot: ${snapshot.cpu.chipName}, Cores: ${snapshot.cpu.coreCount}, Usage: ${snapshot.cpu.usagePercent.toStringAsFixed(1)}%",
    );
    print(
      "GPU info snapshot: ${snapshot.gpu.renderer}, Vendor: ${snapshot.gpu.vendor}, Usage: ${snapshot.gpu.usagePercent.toStringAsFixed(1)}%",
    );
    print(
      "Live Ram Available: ${snapshot.ram.availableRamGb.toStringAsFixed(2)}GB, Usage: ${snapshot.ram.usagePercent.toStringAsFixed(1)}%",
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: _snapshot == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard('📱 Device', [
                    'Name: ${_snapshot!.device.fullName}',
                    'Android: ${_snapshot!.device.androidVersion}',
                    'ARM64: ${_snapshot!.device.isArm64}',
                    'Storage: ${_snapshot!.device.availStorageGb.toStringAsFixed(1)}GB free',
                  ]),
                  _buildCard('🧠 RAM', [
                    'Total: ${_snapshot!.ram.totalRamGb.toStringAsFixed(1)}GB',
                    'Available: ${_snapshot!.ram.availableRamGb.toStringAsFixed(1)}GB',
                    'Usage: ${_snapshot!.ram.usagePercent.toStringAsFixed(1)}%',
                  ]),
                  _buildCard('⚡ CPU', [
                    'Chip: ${_snapshot!.cpu.chipName}',
                    'Cores: ${_snapshot!.cpu.coreCount}',
                    'Arch: ${_snapshot!.cpu.architecture}',
                    'Max: ${_snapshot!.cpu.maxFreqMhz}MHz',
                    'Usage: ${_snapshot!.cpu.usagePercent.toStringAsFixed(1)}%',
                  ]),
                  _buildCard('🎮 GPU', [
                    'Renderer: ${_snapshot!.gpu.renderer}',
                    'Vendor: ${_snapshot!.gpu.vendor}',
                    'Freq: ${_snapshot!.gpu.currentFreqMhz}MHz',
                    'Usage: ${_snapshot!.gpu.usagePercent.toStringAsFixed(1)}%',
                  ]),
                  // Realtime RAM stream test
                  StreamBuilder<RamRealtimeData>(
                    stream: _hardware.ram.realtimeRam,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return _buildCard('🔴 Live RAM', [
                        'Available: ${snapshot.data!.availableRamGb.toStringAsFixed(2)}GB',
                        'Used: ${snapshot.data!.usedRamGb.toStringAsFixed(2)}GB',
                      ]);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCard(String title, List<String> items) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) =>
                  Text(item, style: const TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
