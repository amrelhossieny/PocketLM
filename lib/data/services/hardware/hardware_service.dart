import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'ffi/hardware_ffi.dart';
import 'models/hardware_snapshot.dart';
import 'models/ram_data.dart';
import 'models/thermal_data.dart';

class HardwareService {
  static final HardwareService _instance = HardwareService._();
  factory HardwareService() => _instance;
  HardwareService._();

  bool _initialized = false;

  // ── Stream Caches ────────────────────────
  Stream<RamData>? _ramStream;
  Stream<List<int>>? _cpuStream;
  Stream<ThermalData>? _thermalStream;

  // ── Init ──────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    HardwareFFI.init();

    // Pass app data path to C++ for storage calculations
    final appDir = await getApplicationDocumentsDirectory();
    HardwareFFI.setAppPath(appDir.path);

    _initialized = true;
  }

  // ── One-shot Full Snapshot ─────────────────
  Future<HardwareSnapshot> getSnapshot() async {
    await init();

    final ptr = HardwareFFI.getSnapshot();
    final snapshot = HardwareSnapshot.fromPointer(ptr);
    calloc.free(ptr);

    return snapshot;
  }

  // ── Realtime RAM Stream ────────────────────
  Stream<RamData> get realtimeRam {
    // Create the broadcast stream once and cache it
    _ramStream ??= _createRamStream().asBroadcastStream();
    return _ramStream!;
  }

  Stream<RamData> _createRamStream() async* {
    await init();
    while (true) {
      final ptr = HardwareFFI.getRam();
      yield RamData.fromFFI(ptr.ref);
      calloc.free(ptr);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // ── Realtime CPU Freq Stream ───────────────
  Stream<List<int>> realtimeCpuFreqs(int coreCount) {
    // Create the broadcast stream once and cache it
    _cpuStream ??= _createCpuStream(coreCount).asBroadcastStream();
    return _cpuStream!;
  }

  Stream<List<int>> _createCpuStream(int coreCount) async* {
    await init();
    while (true) {
      yield HardwareFFI.getCpuLiveFreqs(coreCount);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // ── Realtime Thermal Stream ────────────────
  Stream<ThermalData> get realtimeThermal {
    // Create the broadcast stream once and cache it
    _thermalStream ??= _createThermalStream().asBroadcastStream();
    return _thermalStream!;
  }

  Stream<ThermalData> _createThermalStream() async* {
    await init();
    while (true) {
      final ptr = HardwareFFI.getThermal();
      yield ThermalData.fromFFI(ptr.ref);
      calloc.free(ptr);
      await Future.delayed(const Duration(seconds: 2)); // Thermal is slower
    }
  }
}