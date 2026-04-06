import '../ffi/hardware_ffi.dart';

class StorageData {
  final int totalStorageBytes;
  final int freeStorageBytes;
  final int usedStorageBytes;

  const StorageData({
    required this.totalStorageBytes,
    required this.freeStorageBytes,
    required this.usedStorageBytes,
  });

  // Convenience getters
  double get totalGb => totalStorageBytes / (1024 * 1024 * 1024);
  double get freeGb  => freeStorageBytes  / (1024 * 1024 * 1024);
  double get usedGb  => usedStorageBytes  / (1024 * 1024 * 1024);

  double get usagePercent => totalStorageBytes > 0
      ? (usedStorageBytes / totalStorageBytes) * 100
      : 0;

  double get freePercent => 100 - usagePercent;

  // Check if there's enough space to download a model
  bool hasEnoughSpaceForModel(int modelSizeBytes) {
    return freeStorageBytes > modelSizeBytes;
  }

  // Human readable free space
  String get freeSpaceLabel {
    if (freeGb >= 1.0) return '${freeGb.toStringAsFixed(1)} GB free';
    final freeMb = freeStorageBytes / (1024 * 1024);
    return '${freeMb.toStringAsFixed(0)} MB free';
  }

  StorageStatus get status {
    if (freePercent < 5)  return StorageStatus.critical;
    if (freePercent < 15) return StorageStatus.low;
    if (freePercent < 30) return StorageStatus.moderate;
    return StorageStatus.plenty;
  }

  factory StorageData.fromFFI(StorageSnapshotFFI ffi) {
    return StorageData(
      totalStorageBytes: ffi.totalStorageBytes,
      freeStorageBytes:  ffi.freeStorageBytes,
      usedStorageBytes:  ffi.usedStorageBytes,
    );
  }
}

enum StorageStatus { plenty, moderate, low, critical }

extension StorageStatusExt on StorageStatus {
  String get label {
    switch (this) {
      case StorageStatus.plenty:   return 'Plenty of space';
      case StorageStatus.moderate: return 'Moderate';
      case StorageStatus.low:      return 'Low space';
      case StorageStatus.critical: return 'Critical!';
    }
  }

  String get emoji {
    switch (this) {
      case StorageStatus.plenty:   return '🟢';
      case StorageStatus.moderate: return '🟡';
      case StorageStatus.low:      return '🟠';
      case StorageStatus.critical: return '🔴';
    }
  }
}