import 'dart:ffi';
import 'package:pocketlm/data/services/hardware/ffi/hardware_ffi.dart'
    show HardwareSnapshotFFI;

import 'ram_data.dart';
import 'cpu_data.dart';
import 'gpu_data.dart';
import 'storage_data.dart';
import 'thermal_data.dart';

class HardwareSnapshot {
  final RamData ram;
  final CpuData cpu;
  final GpuData gpu;
  final StorageData storage;
  final ThermalData thermal;
  final DateTime capturedAt;

  const HardwareSnapshot({
    required this.ram,
    required this.cpu,
    required this.gpu,
    required this.storage,
    required this.thermal,
    required this.capturedAt,
  });

  // ── LLM Capability Assessment ──────────────────────
  // FIXED: Now uses trueAvailableGb which accounts for zRAM overhead
  LlmCapability get llmCapability {
    final availableGb = ram.trueAvailableGb; // ← FIXED

    // Critical checks first
    if (thermal.isCritical) return LlmCapability.blockedThermal;
    if (ram.isLowMemory) return LlmCapability.blockedLowRam;

    // RAM-based capability
    if (availableGb >= 8.0) return LlmCapability.high;
    if (availableGb >= 5.0) return LlmCapability.medium;
    if (availableGb >= 3.0) return LlmCapability.low;
    return LlmCapability.veryLow;
  }

  // Max recommended model size in GB based on TRUE available RAM
  double get maxRecommendedModelGb {
    // 75% of available RAM is the industry standard safe margin for Android LLMs
    return ram.availableGb * 0.75;
  }

  // Check if a specific model size can run
  bool canRunModel(double modelSizeGb) {
    if (thermal.isCritical) return false;
    if (ram.isLowMemory) return false;
    return modelSizeGb <= maxRecommendedModelGb;
  }

  // Check if there's enough storage for download
  bool canDownloadModel(double modelSizeGb) {
    final modelSizeBytes = (modelSizeGb * 1024 * 1024 * 1024).toInt();
    return storage.hasEnoughSpaceForModel(modelSizeBytes);
  }

  factory HardwareSnapshot.fromPointer(Pointer<HardwareSnapshotFFI> ptr) {
    return HardwareSnapshot(
      ram: RamData.fromFFI(ptr.ref.ram),
      cpu: CpuData.fromFFI(ptr.ref.cpu),
      gpu: GpuData.fromSnapshot(ptr),
      storage: StorageData.fromFFI(ptr.ref.storage),
      thermal: ThermalData.fromFFI(ptr.ref.thermal),
      capturedAt: DateTime.now(),
    );
  }
}

enum LlmCapability { high, medium, low, veryLow, blockedLowRam, blockedThermal }

extension LlmCapabilityExt on LlmCapability {
  String get label {
    switch (this) {
      case LlmCapability.high:
        return 'High-End';
      case LlmCapability.medium:
        return 'Mid-Range';
      case LlmCapability.low:
        return 'Low-End';
      case LlmCapability.veryLow:
        return 'Very Limited';
      case LlmCapability.blockedLowRam:
        return 'Low RAM!';
      case LlmCapability.blockedThermal:
        return 'Too Hot!';
    }
  }

  String get description {
    switch (this) {
      case LlmCapability.high:
        return 'Can run 7B+ models comfortably';
      case LlmCapability.medium:
        return 'Can run 3B-7B models';
      case LlmCapability.low:
        return 'Best with 1B-3B models';
      case LlmCapability.veryLow:
        return 'Only very small models (< 1B)';
      case LlmCapability.blockedLowRam:
        return 'Not enough RAM. Close other apps';
      case LlmCapability.blockedThermal:
        return 'Device too hot. Let it cool down';
    }
  }

  String get emoji {
    switch (this) {
      case LlmCapability.high:
        return '🟢';
      case LlmCapability.medium:
        return '🟡';
      case LlmCapability.low:
        return '🟠';
      case LlmCapability.veryLow:
        return '🔴';
      case LlmCapability.blockedLowRam:
        return '❌';
      case LlmCapability.blockedThermal:
        return '🔥';
    }
  }
}
