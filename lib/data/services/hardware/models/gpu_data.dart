import 'dart:ffi';

import '../ffi/hardware_ffi.dart';

class GpuData {
  final String renderer;
  final String vendor;

  const GpuData({required this.renderer, required this.vendor});

  // Convenience getters
  bool get isQualcomm   => vendor.contains('Qualcomm');
  bool get isArm        => vendor.contains('ARM');
  bool get isSamsungAmd => vendor.contains('Samsung');
  bool get isUnknown    => vendor == 'Unknown';

  GpuTier get tier {
    // Adreno tier detection based on model number
    if (renderer.contains('Adreno')) {
      final match = RegExp(r'(\d{3})').firstMatch(renderer);
      if (match != null) {
        final model = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (model >= 700) return GpuTier.flagship;
        if (model >= 600) return GpuTier.high;
        if (model >= 500) return GpuTier.mid;
        return GpuTier.low;
      }
    }

    // Mali tier detection
    if (renderer.contains('Mali')) {
      if (renderer.contains('G9') || renderer.contains('G8')) return GpuTier.flagship;
      if (renderer.contains('G7') || renderer.contains('G6')) return GpuTier.high;
      return GpuTier.mid;
    }

    return GpuTier.unknown;
  }

  factory GpuData.fromSnapshot(Pointer<HardwareSnapshotFFI> ptr) {
    // Offset into the struct to reach the gpu field:
    // HardwareSnapshotFFI layout: ram | cpu | gpu | storage | thermal
    final gpuPtr = Pointer<Uint8>.fromAddress(
      ptr.address + sizeOf<RamSnapshotFFI>() + sizeOf<CpuSnapshotFFI>(),
    );

    // renderer is 128 bytes, vendor follows immediately after
    final vendorPtr = gpuPtr + 128;

    final rendererList = <int>[];
    for (int i = 0; i < 128; i++) {
      final c = gpuPtr[i];
      if (c == 0) break;
      rendererList.add(c);
    }

    final vendorList = <int>[];
    for (int i = 0; i < 64; i++) {
      final c = vendorPtr[i];
      if (c == 0) break;
      vendorList.add(c);
    }

    return GpuData(
      renderer: String.fromCharCodes(rendererList),
      vendor:   String.fromCharCodes(vendorList),
    );
  }
}

enum GpuTier { flagship, high, mid, low, unknown }

extension GpuTierExt on GpuTier {
  String get label {
    switch (this) {
      case GpuTier.flagship: return 'Flagship';
      case GpuTier.high:     return 'High-End';
      case GpuTier.mid:      return 'Mid-Range';
      case GpuTier.low:      return 'Low-End';
      case GpuTier.unknown:  return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case GpuTier.flagship: return '🟢';
      case GpuTier.high:     return '🟡';
      case GpuTier.mid:      return '🟠';
      case GpuTier.low:      return '🔴';
      case GpuTier.unknown:  return '⚪';
    }
  }
}