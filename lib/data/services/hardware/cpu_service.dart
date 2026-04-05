import 'package:flutter/services.dart';

class CpuService {
  static const _method = MethodChannel('pocketlm/cpu');
  static const _event = EventChannel('pocketlm/cpu/realtime');

  Future<CpuData> getCpuInfo() async {
    final data = await _method.invokeMapMethod<String, dynamic>('getCpuInfo');
    return CpuData.fromMap(data!);
  }

  Stream<CpuRealtimeData> get realtimeCpu {
    return _event
        .receiveBroadcastStream()
        .map((data) => CpuRealtimeData.fromMap(Map<String, dynamic>.from(data)));
  }
}

class CpuData {
  final int coreCount;
  final String architecture;
  final String chipName;
  final int minFreqMhz;
  final int maxFreqMhz;
  final List<int> clockSpeedsMhz;
  final double usagePercent;

  const CpuData({
    required this.coreCount,
    required this.architecture,
    required this.chipName,
    required this.minFreqMhz,
    required this.maxFreqMhz,
    required this.clockSpeedsMhz,
    required this.usagePercent,
  });

  factory CpuData.fromMap(Map<String, dynamic> map) {
    return CpuData(
      coreCount: map['coreCount'] as int,
      architecture: map['architecture'] as String,
      chipName: map['chipName'] as String,
      minFreqMhz: (map['minFreqMhz'] as int?) ?? 0,
      maxFreqMhz: (map['maxFreqMhz'] as int?) ?? 0,
      clockSpeedsMhz: List<int>.from(map['clockSpeedsMhz'] ?? []),
      usagePercent: (map['usagePercent'] as num).toDouble(),
    );
  }
}

class CpuRealtimeData {
  final List<int> clockSpeedsMhz;
  final double usagePercent;

  const CpuRealtimeData({
    required this.clockSpeedsMhz,
    required this.usagePercent,
  });

  factory CpuRealtimeData.fromMap(Map<String, dynamic> map) {
    return CpuRealtimeData(
      clockSpeedsMhz: List<int>.from(map['clockSpeedsMhz'] ?? []),
      usagePercent: (map['usagePercent'] as num).toDouble(),
    );
  }
}