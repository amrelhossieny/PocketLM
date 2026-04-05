import 'package:flutter/services.dart';

class RamService {
  static const _method = MethodChannel('pocketlm/ram');
  static const _event = EventChannel('pocketlm/ram/realtime');

  /// Full snapshot — call once on startup to get totalRam, lowMemThreshold, etc.
  Future<RamData> getRamInfo() async {
    final data = await _method.invokeMapMethod<String, dynamic>('getRamInfo');
    return RamData.fromMap(data!);
  }

  /// Realtime stream — emits lightweight [RamRealtimeData] every second.
  /// Static fields (totalRam, lowMemThreshold) are NOT included; use [getRamInfo] for those.
  Stream<RamRealtimeData> get realtimeRam {
    return _event
        .receiveBroadcastStream()
        .map((data) => RamRealtimeData.fromMap(Map<String, dynamic>.from(data)));
  }
}

/// Full RAM snapshot — returned by [RamService.getRamInfo].
class RamData {
  final int totalRam;
  final int availableRam;
  final int usedRam;
  final bool isLowMemory;
  final int lowMemThreshold;

  const RamData({
    required this.totalRam,
    required this.availableRam,
    required this.usedRam,
    required this.isLowMemory,
    required this.lowMemThreshold,
  });

  double get totalRamGb => totalRam / (1024 * 1024 * 1024);
  double get availableRamGb => availableRam / (1024 * 1024 * 1024);
  double get usedRamGb => usedRam / (1024 * 1024 * 1024);
  double get usagePercent => totalRam == 0 ? 0 : (usedRam / totalRam) * 100;

  factory RamData.fromMap(Map<String, dynamic> map) {
    return RamData(
      totalRam: map['totalRam'] as int,
      availableRam: map['availableRam'] as int,
      usedRam: map['usedRam'] as int,
      isLowMemory: map['isLowMemory'] as bool,
      lowMemThreshold: map['lowMemThreshold'] as int,
    );
  }
}

/// Lightweight realtime update — emitted every second by the event channel.
/// Only contains fields that actually change tick-to-tick.
class RamRealtimeData {
  final int availableRam;
  final int usedRam;
  final bool isLowMemory;

  const RamRealtimeData({
    required this.availableRam,
    required this.usedRam,
    required this.isLowMemory,
  });

  double get availableRamGb => availableRam / (1024 * 1024 * 1024);
  double get usedRamGb => usedRam / (1024 * 1024 * 1024);

  factory RamRealtimeData.fromMap(Map<String, dynamic> map) {
    return RamRealtimeData(
      availableRam: map['availableRam'] as int,
      usedRam: map['usedRam'] as int,
      isLowMemory: map['isLowMemory'] as bool,
    );
  }
}