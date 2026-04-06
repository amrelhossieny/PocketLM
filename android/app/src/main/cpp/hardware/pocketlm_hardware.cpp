#include "pocketlm_hardware.h"
#include "ram_reader.h"
#include "cpu_reader.h"
#include "gpu_reader.h"
#include "storage_reader.h"
#include "thermal_reader.h"
#include <cstring>
#include <android/log.h>

#define TAG "PocketLM"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)

// App data path set from Flutter on init
static char g_appDataPath[512] = {};

extern "C" {

void pocketlm_init() {
    LOGI("PocketLM Hardware Monitor Initialized");
}

void pocketlm_cleanup() {
    LOGI("PocketLM Hardware Monitor Cleaned Up");
}

void pocketlm_set_app_path(const char* path) {
    if (path) {
        strncpy(g_appDataPath, path, sizeof(g_appDataPath) - 1);
        LOGI("App data path set: %s", g_appDataPath);
    }
}

// ── Full snapshot (called once on app start) ──
void pocketlm_get_snapshot(HardwareSnapshot* out) {
    if (!out) return;
    memset(out, 0, sizeof(HardwareSnapshot));

    PocketLM::readRam(&out->ram);
    PocketLM::readCpu(&out->cpu);
    PocketLM::readGpu(&out->gpu);
    PocketLM::readStorage(&out->storage, g_appDataPath);
    PocketLM::readThermal(&out->thermal);

    LOGI("Full hardware snapshot captured");
}

// ── Fast poll functions (called every 1 second) ──
void pocketlm_get_ram(RamSnapshot* out) {
    if (!out) return;
    PocketLM::readRam(out);
}

void pocketlm_get_cpu_live(long* outFreqsMhz, int maxCores) {
    if (!outFreqsMhz || maxCores <= 0) return;
    PocketLM::readCpuLiveFreqs(outFreqsMhz, maxCores);
}

void pocketlm_get_thermal(ThermalSnapshot* out) {
    if (!out) return;
    PocketLM::readThermal(out);
}

} // extern "C"