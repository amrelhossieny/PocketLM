#include "thermal_reader.h"
#include <fstream>
#include <string>
#include <cstring>
#include <dirent.h>
#include <android/log.h>

#define TAG "PocketLM_Thermal"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// Thresholds in Celsius
static constexpr float TEMP_THROTTLE_C  = 75.0f;
static constexpr float TEMP_CRITICAL_C  = 85.0f;

// Keywords that indicate SoC/CPU thermal zones
static const char* SOC_KEYWORDS[] = {
    "cpu",
    "soc",
    "cpu-1-0",
    "tsens_tz_sensor",
    "skin",
    nullptr
};

static bool isSocZone(const std::string& type) {
    for (int i = 0; SOC_KEYWORDS[i] != nullptr; i++) {
        if (type.find(SOC_KEYWORDS[i]) != std::string::npos) {
            return true;
        }
    }
    return false;
}

static float readThermalZone(const std::string& zonePath) {
    std::ifstream tempFile(zonePath + "/temp");
    if (!tempFile.is_open()) return -1.0f;

    long rawTemp = 0;
    tempFile >> rawTemp;

    // Android thermal zone temps are in millidegrees
    return (float)rawTemp / 1000.0f;
}

static std::string readThermalType(const std::string& zonePath) {
    std::ifstream typeFile(zonePath + "/type");
    if (!typeFile.is_open()) return "";

    std::string type;
    std::getline(typeFile, type);
    return type;
}

namespace PocketLM {

void readThermal(ThermalSnapshot* out) {
    memset(out, 0, sizeof(ThermalSnapshot));

    float highestSocTemp = -1.0f;

    // Scan all thermal zones
    DIR* dir = opendir("/sys/class/thermal");
    if (!dir) {
        LOGE("Cannot open /sys/class/thermal");
        out->socTemperatureCelsius = -1.0f;
        return;
    }

    struct dirent* entry;
    while ((entry = readdir(dir)) != nullptr) {
        std::string name(entry->d_name);

        // Only look at thermal_zone folders
        if (name.rfind("thermal_zone", 0) != 0) continue;

        std::string zonePath = std::string("/sys/class/thermal/") + name;
        std::string type = readThermalType(zonePath);

        if (!isSocZone(type)) continue;

        float temp = readThermalZone(zonePath);

        LOGI("Thermal zone: %s | type: %s | temp: %.1f°C",
             name.c_str(), type.c_str(), temp);

        if (temp > highestSocTemp) {
            highestSocTemp = temp;
        }
    }

    closedir(dir);

    out->socTemperatureCelsius = highestSocTemp;
    out->isThrottling = (highestSocTemp >= TEMP_THROTTLE_C) ? 1 : 0;
    out->isCritical   = (highestSocTemp >= TEMP_CRITICAL_C) ? 1 : 0;

    LOGI("Thermal -> SoC: %.1f°C | Throttling: %d | Critical: %d",
         out->socTemperatureCelsius,
         out->isThrottling,
         out->isCritical);
}

} // namespace PocketLM