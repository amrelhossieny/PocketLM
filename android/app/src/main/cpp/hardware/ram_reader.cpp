#include "ram_reader.h"
#include <fstream>
#include <string>
#include <sstream>
#include <cstring>
#include <android/log.h>

#define TAG "PocketLM_RAM"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

static long long parseMemInfoValue(const std::string& line) {
    size_t pos = line.find(':');
    if (pos == std::string::npos) return 0LL;

    std::string valueStr = line.substr(pos + 1);
    size_t start = valueStr.find_first_not_of(" \t");
    if (start == std::string::npos) return 0LL;
    valueStr = valueStr.substr(start);

    long long value = std::stoll(valueStr);

    // Convert kB to bytes
    if (valueStr.find("kB") != std::string::npos || valueStr.find("KB") != std::string::npos) {
        value *= 1024LL;
    }
    return value;
}

// Attempts to read the actual physical memory consumed by zRAM
static long long getZramPhysicalUsed() {
    std::ifstream file("/sys/block/zram0/mem_used_total");
    if (!file.is_open()) return -1LL; // Blocked by SELinux on some devices
    
    long long bytes = 0;
    file >> bytes;
    return bytes > 0 ? bytes : -1LL;
}

namespace PocketLM {

void readRam(RamSnapshot* out) {
    if (!out) return;
    memset(out, 0, sizeof(RamSnapshot));

    std::ifstream meminfo("/proc/meminfo");
    if (!meminfo.is_open()) {
        LOGE("Failed to open /proc/meminfo");
        return;
    }

    long long memTotal = 0, memAvailable = 0, memFree = 0, cached = 0;
    long long swapTotal = 0, swapFree = 0;

    std::string line;
    while (std::getline(meminfo, line)) {
        if (line.rfind("MemTotal:", 0) == 0)
            memTotal = parseMemInfoValue(line);
        else if (line.rfind("MemAvailable:", 0) == 0)
            memAvailable = parseMemInfoValue(line);
        else if (line.rfind("MemFree:", 0) == 0)
            memFree = parseMemInfoValue(line);
        else if (line.rfind("Cached:", 0) == 0)
            cached = parseMemInfoValue(line);
        else if (line.rfind("SwapTotal:", 0) == 0)
            swapTotal = parseMemInfoValue(line);
        else if (line.rfind("SwapFree:", 0) == 0)
            swapFree = parseMemInfoValue(line);
    }
    meminfo.close();

    // The Linux kernel provides MemAvailable which is the EXACT amount of memory 
    // available for a new process (like our LLM) without triggering swapping.
    long long trueAvailable = memAvailable > 0 ? memAvailable : (memFree + cached);

    // Calculate Swap (zRAM) usage accurately without needing /proc/swaps
    long long swapUsed = swapTotal - swapFree;
    if (swapUsed < 0) swapUsed = 0;

    // Calculate actual physical RAM consumed by compressed zRAM data
    long long zramPhysicalBytes = getZramPhysicalUsed();
    if (zramPhysicalBytes < 0 && swapUsed > 0) {
        // Fallback: If SELinux blocks reading zram0, use a standard 3:1 Android compression ratio
        zramPhysicalBytes = swapUsed / 3LL; 
    } else if (swapUsed == 0) {
        zramPhysicalBytes = 0;
    }

    // --- Smart Low Memory Threshold for LLM ---
    long long lowThresholdBytes = 1300LL * 1024 * 1024; // 1.3GB base
    if (memTotal > (6LL * 1024 * 1024 * 1024)) {
        lowThresholdBytes = memTotal * 0.18; // ~18% of total RAM on 8GB+ devices
    } else if (memTotal > (4LL * 1024 * 1024 * 1024)) {
        lowThresholdBytes = memTotal * 0.22; // ~22% of total RAM on 6GB devices
    }

    out->totalRamBytes       = memTotal;
    out->availableRamBytes   = trueAvailable;
    out->usedRamBytes        = memTotal - trueAvailable;
    out->swapTotalBytes      = swapTotal;
    out->swapFreeBytes       = swapFree;
    out->swapUsedBytes       = swapUsed;
    out->zramCompressedBytes = zramPhysicalBytes;
    out->isLowMemory         = (trueAvailable < lowThresholdBytes) ? 1 : 0;

    LOGI("RAM -> Total: %.1f GB | Available: %.1f GB | zRAM Used: %.1f GB (Physical: %.1f MB)",
         memTotal / (1024.0*1024*1024),
         trueAvailable / (1024.0*1024*1024),
         swapUsed / (1024.0*1024*1024),
         zramPhysicalBytes / (1024.0*1024));
}

} // namespace PocketLM