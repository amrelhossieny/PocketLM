import '../ffi/hardware_ffi.dart';

class RamData {
  final int totalRamBytes;
  final int availableRamBytes;
  final int usedRamBytes;
  final int swapTotalBytes;
  final int swapFreeBytes;
  final int swapUsedBytes;
  final int zramCompressedBytes;
  final bool isLowMemory;

  const RamData({
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.usedRamBytes,
    required this.swapTotalBytes,
    required this.swapFreeBytes,
    required this.swapUsedBytes,
    required this.zramCompressedBytes,
    required this.isLowMemory,
  });

  // ── Existing Getters ──────────────────────
  double get totalGb       => totalRamBytes       / (1024 * 1024 * 1024);
  double get availableGb   => availableRamBytes   / (1024 * 1024 * 1024);
  double get usedGb        => usedRamBytes        / (1024 * 1024 * 1024);
  double get swapTotalGb   => swapTotalBytes      / (1024 * 1024 * 1024);
  double get swapFreeGb    => swapFreeBytes       / (1024 * 1024 * 1024);
  double get usagePercent  => totalRamBytes > 0
      ? (usedRamBytes / totalRamBytes) * 100
      : 0;

  // ── zRAM Stats ────────────────────────────
  double get swapUsedGb => swapUsedBytes / (1024 * 1024 * 1024);
  double get swapUsedMb => swapUsedBytes / (1024 * 1024);
  double get zramCompressedGb => zramCompressedBytes / (1024 * 1024 * 1024);
  double get zramCompressedMb => zramCompressedBytes / (1024 * 1024);
  
  // Compression ratio (e.g. 3.0 = 3:1 compression)
  double get compressionRatio => zramCompressedBytes > 0
      ? swapUsedBytes / zramCompressedBytes
      : 0.0;
  
  // TRUE available RAM (CRITICAL FIX: MemAvailable already accounts for zRAM overhead in Linux)
  double get trueAvailableGb => availableGb;
  double get trueAvailableMb => availableRamBytes / (1024 * 1024);

  // Check if zRAM is active
  bool get hasZram => swapTotalBytes > 0;
  
  // Check if zRAM is being used
  bool get isUsingZram => swapUsedBytes > 0;

  // Calculate swap usage percentage
  double get swapUsagePercent => swapTotalBytes > 0
      ? (swapUsedBytes / swapTotalBytes) * 100
      : 0;

  factory RamData.fromFFI(RamSnapshotFFI ffi) {
    return RamData(
      totalRamBytes:       ffi.totalRamBytes,
      availableRamBytes:   ffi.availableRamBytes,
      usedRamBytes:        ffi.usedRamBytes,
      swapTotalBytes:      ffi.swapTotalBytes,
      swapFreeBytes:       ffi.swapFreeBytes,
      swapUsedBytes:       ffi.swapUsedBytes,
      zramCompressedBytes: ffi.zramCompressedBytes,
      isLowMemory:         ffi.isLowMemory == 1,
    );
  }
}