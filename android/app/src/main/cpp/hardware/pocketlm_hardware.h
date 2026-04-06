#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// ─────────────────────────────────────────
// DATA STRUCTS
// These map 1:1 to Dart FFI structs
// ─────────────────────────────────────────

struct RamSnapshot {
    long long totalRamBytes;
    long long availableRamBytes;
    long long usedRamBytes;
    long long swapTotalBytes;
    long long swapFreeBytes;
    long long swapUsedBytes;        // NEW: Uncompressed data in zRAM
    long long zramCompressedBytes;  // NEW: Actual RAM consumed by compression
    int       isLowMemory;          // 1 = true, 0 = false
};

struct CpuSnapshot {
    int  coreCount;
    long maxFreqMhz;                // True peak (Prime core)
    long liveCoreFreqsMhz[8];       // Per-core live MHz
    char architecture[32];          // "aarch64" or "x86_64"
    char chipsetName[64];           // "lahaina", "gs101" etc
};

struct GpuSnapshot {
    char renderer[128];             // "Adreno (TM) 660"
    char vendor[64];                // "Qualcomm"
};

struct StorageSnapshot {
    long long totalStorageBytes;
    long long freeStorageBytes;
    long long usedStorageBytes;
};

struct ThermalSnapshot {
    float socTemperatureCelsius;    // SoC temp
    int   isThrottling;             // 1 = throttling detected
    int   isCritical;               // 1 = above 85°C - stop LLM!
};

struct HardwareSnapshot {
    RamSnapshot     ram;
    CpuSnapshot     cpu;
    GpuSnapshot     gpu;
    StorageSnapshot storage;
    ThermalSnapshot thermal;
};

// ─────────────────────────────────────────
// EXPORTED FUNCTIONS (Called from Dart FFI)
// ─────────────────────────────────────────

// One-shot full snapshot
void pocketlm_get_snapshot(HardwareSnapshot* out);

// Individual fast-poll functions (for realtime UI)
void pocketlm_get_ram(RamSnapshot* out);
void pocketlm_get_cpu_live(long* outFreqsMhz, int maxCores);
void pocketlm_get_thermal(ThermalSnapshot* out);

// Init / Cleanup
void pocketlm_init();
void pocketlm_cleanup();
void pocketlm_set_app_path(const char* path);

#ifdef __cplusplus
}
#endif