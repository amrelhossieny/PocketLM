#include "cpu_reader.h"
#include <fstream>
#include <string>
#include <cstring>
#include <unistd.h>
#include <sys/utsname.h>
#include <sys/system_properties.h>
#include <android/log.h>

#define TAG "PocketLM_CPU"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// Read a single long from a sysfs file
static long readSysfsLong(const std::string& path) {
    std::ifstream file(path);
    if (!file.is_open()) return 0L;
    long value = 0;
    file >> value;
    return value;
}

namespace PocketLM {

void readCpu(CpuSnapshot* out) {
    memset(out, 0, sizeof(CpuSnapshot));

    // ── Core Count ──────────────────────────
    out->coreCount = (int)sysconf(_SC_NPROCESSORS_CONF);
    if (out->coreCount <= 0) out->coreCount = 1;

    // ── Architecture ────────────────────────
    struct utsname uts;
    if (uname(&uts) == 0) {
        strncpy(out->architecture, uts.machine, sizeof(out->architecture) - 1);
    } else {
        strncpy(out->architecture, "unknown", sizeof(out->architecture) - 1);
    }

    // ── Chipset Name ─────────────────────────
    // Try multiple properties - different OEMs use different ones
    char chipset[64] = {};
    const char* props[] = {
        "ro.board.platform",          // Qualcomm: "lahaina", "kalama"
        "ro.chipname",                // Samsung Exynos
        "ro.hardware",                // Generic fallback
        "ro.product.board",           // Another fallback
    };

    for (const char* prop : props) {
        __system_property_get(prop, chipset);
        if (strlen(chipset) > 0 && strcmp(chipset, "unknown") != 0) break;
    }

    strncpy(out->chipsetName, chipset, sizeof(out->chipsetName) - 1);

    // ── True Max Frequency ──────────────────
    // Loop ALL cores to find the highest (Prime core)
    long trueMaxMhz = 0;
    int cores = out->coreCount > 8 ? 8 : out->coreCount;

    for (int i = 0; i < cores; i++) {
        std::string path = "/sys/devices/system/cpu/cpu"
                         + std::to_string(i)
                         + "/cpufreq/cpuinfo_max_freq";
        long khz = readSysfsLong(path);
        long mhz = khz / 1000;
        if (mhz > trueMaxMhz) trueMaxMhz = mhz;
    }

    out->maxFreqMhz = trueMaxMhz;

    // ── Live Frequencies ────────────────────
    readCpuLiveFreqs(out->liveCoreFreqsMhz, cores);

    LOGI("CPU -> Cores: %d | Arch: %s | Chipset: %s | MaxFreq: %ldMHz",
         out->coreCount,
         out->architecture,
         out->chipsetName,
         out->maxFreqMhz);
}

void readCpuLiveFreqs(long* outFreqsMhz, int maxCores) {
    // Zero out array first
    memset(outFreqsMhz, 0, sizeof(long) * maxCores);

    for (int i = 0; i < maxCores; i++) {
        // Try scaling_cur_freq first (live governor freq)
        std::string curPath = "/sys/devices/system/cpu/cpu"
                            + std::to_string(i)
                            + "/cpufreq/scaling_cur_freq";

        long khz = readSysfsLong(curPath);

        // Gracefully handle offline/blocked cores
        if (khz <= 0) {
            outFreqsMhz[i] = 0; // Core is offline
            continue;
        }

        outFreqsMhz[i] = khz / 1000; // kHz -> MHz
    }
}

} // namespace PocketLM