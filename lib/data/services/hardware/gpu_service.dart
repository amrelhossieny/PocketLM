import 'package:flutter/services.dart';

class GpuService {
  static const _method = MethodChannel('pocketlm/gpu');
  static const _event = EventChannel('pocketlm/gpu/realtime');

  Future<GpuData> getGpuInfo() async {
    final data = await _method.invokeMapMethod<String, dynamic>('getGpuInfo');
    return GpuData.fromMap(data!);
  }

  Stream<GpuRealtimeData> get realtimeGpu {
    return _event
        .receiveBroadcastStream()
        .map((data) => GpuRealtimeData.fromMap(Map<String, dynamic>.from(data)));
  }
}

class GpuData {
  final String renderer;
  final String vendor;
  final String version;
  final int maxFreqMhz;
  final int currentFreqMhz;
  final double usagePercent;

  const GpuData({
    required this.renderer,
    required this.vendor,
    required this.version,
    required this.maxFreqMhz,
    required this.currentFreqMhz,
    required this.usagePercent,
  });

  factory GpuData.fromMap(Map<String, dynamic> map) {
    return GpuData(
      renderer: map['renderer'] as String,
      vendor: map['vendor'] as String,
      version: map['version'] as String,
      maxFreqMhz: (map['maxFreqMhz'] as int?) ?? 0,
      currentFreqMhz: (map['currentFreqMhz'] as int?) ?? 0,
      usagePercent: (map['usagePercent'] as num).toDouble(),
    );
  }
}

class GpuRealtimeData {
  final int currentFreqMhz;
  final double usagePercent;

  const GpuRealtimeData({
    required this.currentFreqMhz,
    required this.usagePercent,
  });

  factory GpuRealtimeData.fromMap(Map<String, dynamic> map) {
    return GpuRealtimeData(
      currentFreqMhz: (map['currentFreqMhz'] as int?) ?? 0,
      usagePercent: (map['usagePercent'] as num).toDouble(),
    );
  }
}