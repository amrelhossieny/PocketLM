import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// Load the shared library
final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open('libpocketlm_hardware.so')
    : DynamicLibrary.process();

// ── C Struct Definitions ──────────────────

final class RamSnapshotFFI extends Struct {
  @Int64()
  external int totalRamBytes;

  @Int64()
  external int availableRamBytes;

  @Int64()
  external int usedRamBytes;

  @Int64()
  external int swapTotalBytes;

  @Int64()
  external int swapFreeBytes;

  @Int64()
  external int swapUsedBytes;        // NEW

  @Int64()
  external int zramCompressedBytes;  // NEW

  @Int32()
  external int isLowMemory;
}

final class CpuSnapshotFFI extends Struct {
  @Int32()
  external int coreCount;

  @Long()
  external int maxFreqMhz;

  @Array(8)
  external Array<Long> liveCoreFreqsMhz;

  @Array(32)
  external Array<Char> architecture;

  @Array(64)
  external Array<Char> chipsetName;
}

final class GpuSnapshotFFI extends Struct {
  @Array(128)
  external Array<Char> renderer;

  @Array(64)
  external Array<Char> vendor;
}

final class StorageSnapshotFFI extends Struct {
  @Int64()
  external int totalStorageBytes;

  @Int64()
  external int freeStorageBytes;

  @Int64()
  external int usedStorageBytes;
}

final class ThermalSnapshotFFI extends Struct {
  @Float()
  external double socTemperatureCelsius;

  @Int32()
  external int isThrottling;

  @Int32()
  external int isCritical;
}

final class HardwareSnapshotFFI extends Struct {
  external RamSnapshotFFI     ram;
  external CpuSnapshotFFI     cpu;
  external GpuSnapshotFFI     gpu;
  external StorageSnapshotFFI storage;
  external ThermalSnapshotFFI thermal;
}

// ── Function Bindings ─────────────────────

typedef _InitC       = Void Function();
typedef _InitDart    = void Function();

typedef _SetPathC    = Void Function(Pointer<Char> path);
typedef _SetPathDart = void Function(Pointer<Char> path);

typedef _GetSnapshotC    = Void Function(Pointer<HardwareSnapshotFFI> out);
typedef _GetSnapshotDart = void Function(Pointer<HardwareSnapshotFFI> out);

typedef _GetRamC    = Void Function(Pointer<RamSnapshotFFI> out);
typedef _GetRamDart = void Function(Pointer<RamSnapshotFFI> out);

typedef _GetCpuLiveC    = Void Function(Pointer<Long> out, Int32 maxCores);
typedef _GetCpuLiveDart = void Function(Pointer<Long> out, int maxCores);

typedef _GetThermalC    = Void Function(Pointer<ThermalSnapshotFFI> out);
typedef _GetThermalDart = void Function(Pointer<ThermalSnapshotFFI> out);

// ── Resolved Function Pointers ────────────

final _init = _lib
    .lookup<NativeFunction<_InitC>>('pocketlm_init')
    .asFunction<_InitDart>();

final _setPath = _lib
    .lookup<NativeFunction<_SetPathC>>('pocketlm_set_app_path')
    .asFunction<_SetPathDart>();

final _getSnapshot = _lib
    .lookup<NativeFunction<_GetSnapshotC>>('pocketlm_get_snapshot')
    .asFunction<_GetSnapshotDart>();

final _getRam = _lib
    .lookup<NativeFunction<_GetRamC>>('pocketlm_get_ram')
    .asFunction<_GetRamDart>();

final _getCpuLive = _lib
    .lookup<NativeFunction<_GetCpuLiveC>>('pocketlm_get_cpu_live')
    .asFunction<_GetCpuLiveDart>();

final _getThermal = _lib
    .lookup<NativeFunction<_GetThermalC>>('pocketlm_get_thermal')
    .asFunction<_GetThermalDart>();

// ── Public API ────────────────────────────

class HardwareFFI {
  static void init() => _init();

  static void setAppPath(String path) {
    final ptr = path.toNativeChar();
    _setPath(ptr);
    calloc.free(ptr);
  }

  static Pointer<HardwareSnapshotFFI> getSnapshot() {
    final ptr = calloc<HardwareSnapshotFFI>();
    _getSnapshot(ptr);
    return ptr;
  }

  static Pointer<RamSnapshotFFI> getRam() {
    final ptr = calloc<RamSnapshotFFI>();
    _getRam(ptr);
    return ptr;
  }

  static List<int> getCpuLiveFreqs(int coreCount) {
    final ptr = calloc<Long>(coreCount);
    _getCpuLive(ptr, coreCount);
    final freqs = List<int>.generate(coreCount, (i) => ptr[i]);
    calloc.free(ptr);
    return freqs;
  }

  static Pointer<ThermalSnapshotFFI> getThermal() {
    final ptr = calloc<ThermalSnapshotFFI>();
    _getThermal(ptr);
    return ptr;
  }
}

// Helper extension
extension StringFFI on String {
  Pointer<Char> toNativeChar() {
    final units = codeUnits;
    final ptr = calloc<Char>(units.length + 1);
    for (int i = 0; i < units.length; i++) {
      ptr[i] = units[i];
    }
    ptr[units.length] = 0;
    return ptr;
  }
}