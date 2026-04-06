import 'package:flutter/material.dart';
import 'data/services/hardware/hardware_service.dart';
import 'data/services/hardware/models/hardware_snapshot.dart';
import 'data/services/hardware/models/ram_data.dart';
import 'data/services/hardware/models/storage_data.dart';
import 'data/services/hardware/models/thermal_data.dart';
import 'data/services/hardware/models/cpu_data.dart';
import 'data/services/hardware/models/gpu_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PocketLMApp());
}

class PocketLMApp extends StatelessWidget {
  const PocketLMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketLM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        cardColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF03DAC6),
        ),
      ),
      home: const HardwareTestPage(),
    );
  }
}

class HardwareTestPage extends StatefulWidget {
  const HardwareTestPage({super.key});

  @override
  State<HardwareTestPage> createState() => _HardwareTestPageState();
}

class _HardwareTestPageState extends State<HardwareTestPage> {
  final _hardware = HardwareService();

  HardwareSnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final snapshot = await _hardware.getSnapshot();
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Text('🧠', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'PocketLM',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'Hardware',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadSnapshot,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D0D0D),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6C63FF)),
            SizedBox(height: 16),
            Text(
              'Reading hardware...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('❌', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSnapshot,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_snapshot == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── LLM Capability Banner ──
        _buildCapabilityBanner(_snapshot!),
        const SizedBox(height: 16),

        // ── RAM Card (Static) ──
        _buildSectionHeader('🧠 RAM'),
        _buildRamCard(_snapshot!.ram),
        const SizedBox(height: 8),

        // ── RAM Card (Realtime) ──
        _buildSectionHeader('🔴 Live RAM'),
        _buildRealtimeRam(),
        const SizedBox(height: 8),

        // ── CPU Card ──
        _buildSectionHeader('⚡ CPU'),
        _buildCpuCard(_snapshot!.cpu),
        const SizedBox(height: 8),

        // ── CPU Live Freqs ──
        _buildSectionHeader('🔴 Live CPU Cores'),
        _buildRealtimeCpu(_snapshot!.cpu.coreCount),
        const SizedBox(height: 8),

        // ── GPU Card ──
        _buildSectionHeader('🎮 GPU'),
        _buildGpuCard(_snapshot!.gpu),
        const SizedBox(height: 8),

        // ── Storage Card ──
        _buildSectionHeader('💾 Storage'),
        _buildStorageCard(_snapshot!.storage),
        const SizedBox(height: 8),

        // ── Thermal Card ──
        _buildSectionHeader('🌡️ Thermal'),
        _buildThermalCard(_snapshot!.thermal),
        const SizedBox(height: 8),

        // ── Realtime Thermal ──
        _buildSectionHeader('🔴 Live Thermal'),
        _buildRealtimeThermal(),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Capability Banner ────────────────────────────
  Widget _buildCapabilityBanner(HardwareSnapshot snapshot) {
    final cap = snapshot.llmCapability;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C63FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(cap.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                cap.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cap.description,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Max recommended model: '
            '${snapshot.maxRecommendedModelGb.toStringAsFixed(1)} GB',
            style: const TextStyle(color: Color(0xFF03DAC6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── RAM Card ─────────────────────────────────────
  Widget _buildRamCard(RamData ram) {
    return _Card(
      children: [
        _Row('Total RAM', '${ram.totalGb.toStringAsFixed(1)} GB'),
        _Row('Available RAM', '${ram.availableGb.toStringAsFixed(2)} GB'),
        _Row('Used RAM', '${ram.usedGb.toStringAsFixed(2)} GB'),
        const SizedBox(height: 8),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),

        // zRAM Section
        _Row('Swap Total (zRAM)', '${ram.swapTotalGb.toStringAsFixed(1)} GB'),
        _Row('Swap Free', '${ram.swapFreeGb.toStringAsFixed(1)} GB'),
        _Row('Swap Used', '${ram.swapUsedGb.toStringAsFixed(2)} GB'),
        _Row('zRAM Physical', '${ram.zramCompressedMb.toStringAsFixed(0)} MB'),
        if (ram.compressionRatio > 0)
          _Row(
            'Compression Ratio',
            '${ram.compressionRatio.toStringAsFixed(2)}:1',
          ),

        const SizedBox(height: 8),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),

        // True Available RAM (accounting for zRAM overhead)
        _Row(
          'True Available RAM',
          '${ram.trueAvailableGb.toStringAsFixed(2)} GB',
          highlight: true,
        ),
        _Row('Low Memory', ram.isLowMemory ? '⚠️ YES' : '✅ NO'),

        const SizedBox(height: 8),
        _ProgressBar(
          value: ram.usagePercent / 100,
          color: ram.isLowMemory ? Colors.red : const Color(0xFF6C63FF),
          label: '${ram.usagePercent.toStringAsFixed(1)}% used',
        ),
      ],
    );
  }

  // ── Realtime RAM ─────────────────────────────────
  Widget _buildRealtimeRam() {
    return StreamBuilder<RamData>(
      stream: _hardware.realtimeRam,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _Card(
            children: [Center(child: CircularProgressIndicator())],
          );
        }
        final ram = snapshot.data!;
        return _Card(
          children: [
            _Row('Available', '${ram.availableGb.toStringAsFixed(2)} GB'),
            _Row(
              'True Available',
              '${ram.trueAvailableGb.toStringAsFixed(2)} GB',
              highlight: true,
            ),
            _Row('Used', '${ram.usedGb.toStringAsFixed(2)} GB'),
            _Row(
              'zRAM Physical',
              '${ram.zramCompressedMb.toStringAsFixed(0)} MB',
            ),
            if (ram.compressionRatio > 0)
              _Row(
                'Compression',
                '${ram.compressionRatio.toStringAsFixed(2)}:1',
              ),
            _Row('Low Mem', ram.isLowMemory ? '⚠️ YES' : '✅ NO'),
            const SizedBox(height: 8),
            _ProgressBar(
              value: ram.usagePercent / 100,
              color: ram.isLowMemory ? Colors.red : const Color(0xFF6C63FF),
              label: '${ram.usagePercent.toStringAsFixed(1)}% used',
            ),
          ],
        );
      },
    );
  }

  // ── CPU Card ─────────────────────────────────────
  Widget _buildCpuCard(CpuData cpu) {
    return _Card(
      children: [
        _Row('Chipset', cpu.chipsetName),
        _Row('Architecture', cpu.architecture),
        _Row('Core Count', '${cpu.coreCount} cores'),
        _Row('Max Freq', '${cpu.maxFreqGhz.toStringAsFixed(2)} GHz'),
        _Row('Is ARM64', cpu.isArm64 ? '✅ YES' : '❌ NO'),
      ],
    );
  }

  // ── Realtime CPU ─────────────────────────────────
  Widget _buildRealtimeCpu(int coreCount) {
    return StreamBuilder<List<int>>(
      stream: _hardware.realtimeCpuFreqs(coreCount),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _Card(
            children: [Center(child: CircularProgressIndicator())],
          );
        }
        final freqs = snapshot.data!;
        return _Card(
          children: [
            ...List.generate(freqs.length, (i) {
              final freq = freqs[i];
              final isOnline = freq > 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(
                      'Core $i',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: isOnline ? freq / 3500 : 0, // 3500MHz max
                        backgroundColor: Colors.white12,
                        color: _coreColor(i, coreCount),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? '${freq}MHz' : 'offline',
                      style: TextStyle(
                        color: isOnline ? Colors.white : Colors.white24,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Color _coreColor(int index, int total) {
    if (total >= 8) {
      if (index < 4) return Colors.blue;
      if (index < 7) return Colors.orange;
      return Colors.red;
    }
    if (index < total ~/ 2) return Colors.blue;
    return Colors.orange;
  }

  // ── GPU Card ─────────────────────────────────────
  Widget _buildGpuCard(GpuData gpu) {
    return _Card(
      children: [
        _Row('Renderer', gpu.renderer),
        _Row('Vendor', gpu.vendor),
        _Row('Tier', '${gpu.tier.emoji} ${gpu.tier.label}'),
      ],
    );
  }

  // ── Storage Card ─────────────────────────────────
  Widget _buildStorageCard(StorageData storage) {
    return _Card(
      children: [
        _Row('Total', '${storage.totalGb.toStringAsFixed(1)} GB'),
        _Row('Used', '${storage.usedGb.toStringAsFixed(1)} GB'),
        _Row('Free', storage.freeSpaceLabel),
        _Row('Status', '${storage.status.emoji} ${storage.status.label}'),
        const SizedBox(height: 8),
        _ProgressBar(
          value: storage.usagePercent / 100,
          color: storage.status == StorageStatus.critical
              ? Colors.red
              : const Color(0xFF03DAC6),
          label: '${storage.usagePercent.toStringAsFixed(1)}% used',
        ),
      ],
    );
  }

  // ── Thermal Card ─────────────────────────────────
  Widget _buildThermalCard(ThermalData thermal) {
    return _Card(
      children: [
        _Row('SoC Temp', thermal.temperatureLabel),
        _Row('Throttling', thermal.isThrottling ? '⚠️ YES' : '✅ NO'),
        _Row('Critical', thermal.isCritical ? '🔥 YES' : '✅ NO'),
        _Row('Status', '${thermal.status.emoji} ${thermal.status.label}'),
      ],
    );
  }

  // ── Realtime Thermal ─────────────────────────────
  Widget _buildRealtimeThermal() {
    return StreamBuilder<ThermalData>(
      stream: _hardware.realtimeThermal,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _Card(
            children: [Center(child: CircularProgressIndicator())],
          );
        }
        final thermal = snapshot.data!;
        final tempColor = thermal.isCritical
            ? Colors.red
            : thermal.isThrottling
            ? Colors.orange
            : Colors.green;

        return _Card(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  thermal.temperatureLabel,
                  style: TextStyle(
                    color: tempColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Row('Status', '${thermal.status.emoji} ${thermal.status.label}'),
            if (thermal.isCritical)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ LLM inference should be paused!',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Row(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? const Color(0xFF03DAC6) : Colors.white54,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFF03DAC6) : Colors.white,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final String label;
  const _ProgressBar({
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            color: color,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
