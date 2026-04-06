import 'dart:ffi';
import '../ffi/hardware_ffi.dart';

class CpuData {
  final int coreCount;
  final int maxFreqMhz;
  final List<int> liveCoreFreqsMhz;
  final String architecture;
  final String chipsetName;

  const CpuData({
    required this.coreCount,
    required this.maxFreqMhz,
    required this.liveCoreFreqsMhz,
    required this.architecture,
    required this.chipsetName,
  });

  // Convenience getters
  double get maxFreqGhz => maxFreqMhz / 1000.0;

  bool get isArm64 => architecture.contains('aarch64');

  int get activeCores =>
      liveCoreFreqsMhz.where((f) => f > 0).length;

  int get highestLiveFreqMhz =>
      liveCoreFreqsMhz.isEmpty
          ? 0
          : liveCoreFreqsMhz.reduce((a, b) => a > b ? a : b);

  double get highestLiveFreqGhz => highestLiveFreqMhz / 1000.0;

  // Cluster detection (LITTLE / big / Prime)
  // Based on frequency ranges
  List<CoreCluster> get clusters {
    if (liveCoreFreqsMhz.isEmpty) return [];

    final clusters = <CoreCluster>[];
    for (int i = 0; i < liveCoreFreqsMhz.length; i++) {
      final freq = liveCoreFreqsMhz[i];
      final type = _detectCoreType(i, freq);
      clusters.add(CoreCluster(
        coreIndex: i,
        freqMhz: freq,
        type: type,
      ));
    }
    return clusters;
  }

  CoreType _detectCoreType(int index, int freqMhz) {
    // Typical cluster layout for big.LITTLE
    // First 4 = LITTLE, next 3 = big, last 1 = Prime
    if (coreCount >= 8) {
      if (index < 4) return CoreType.little;
      if (index < 7) return CoreType.big;
      return CoreType.prime;
    }
    if (coreCount >= 6) {
      if (index < 4) return CoreType.little;
      return CoreType.big;
    }
    return CoreType.big;
  }

  factory CpuData.fromFFI(CpuSnapshotFFI ffi) {
    // Read architecture char array
    final archList = <int>[];
    for (int i = 0; i < 32; i++) {
      final c = ffi.architecture[i];
      if (c == 0) break;
      archList.add(c);
    }

    // Read chipset char array
    final chipList = <int>[];
    for (int i = 0; i < 64; i++) {
      final c = ffi.chipsetName[i];
      if (c == 0) break;
      chipList.add(c);
    }

    // Read live core frequencies array
    final freqs = <int>[];
    final cores = ffi.coreCount > 8 ? 8 : ffi.coreCount;
    for (int i = 0; i < cores; i++) {
      freqs.add(ffi.liveCoreFreqsMhz[i]);
    }

    return CpuData(
      coreCount:        ffi.coreCount,
      maxFreqMhz:       ffi.maxFreqMhz,
      liveCoreFreqsMhz: freqs,
      architecture:     String.fromCharCodes(archList),
      chipsetName:      String.fromCharCodes(chipList),
    );
  }

  // Updated live freqs (for realtime stream)
  CpuData copyWithLiveFreqs(List<int> newFreqs) {
    return CpuData(
      coreCount:        coreCount,
      maxFreqMhz:       maxFreqMhz,
      liveCoreFreqsMhz: newFreqs,
      architecture:     architecture,
      chipsetName:      chipsetName,
    );
  }
}

class CoreCluster {
  final int coreIndex;
  final int freqMhz;
  final CoreType type;

  const CoreCluster({
    required this.coreIndex,
    required this.freqMhz,
    required this.type,
  });

  double get freqGhz => freqMhz / 1000.0;
  bool get isOnline => freqMhz > 0;
}

enum CoreType { little, big, prime }

extension CoreTypeExt on CoreType {
  String get label {
    switch (this) {
      case CoreType.little: return 'LITTLE';
      case CoreType.big:    return 'Big';
      case CoreType.prime:  return 'Prime';
    }
  }

  String get emoji {
    switch (this) {
      case CoreType.little: return '🔵';
      case CoreType.big:    return '🟡';
      case CoreType.prime:  return '🔴';
    }
  }
}