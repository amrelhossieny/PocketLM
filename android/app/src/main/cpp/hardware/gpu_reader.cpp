#include "gpu_reader.h"
#include <fstream>
#include <string>
#include <cstring>
#include <android/log.h>

#define TAG "PocketLM_GPU"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// Static GPU sysfs paths to try
static const char* GPU_MODEL_PATHS[] = {
    "/sys/class/kgsl/kgsl-3d0/gpu_model",       // Qualcomm Adreno
    "/sys/class/misc/mali0/device/gpuinfo",      // ARM Mali
    "/sys/kernel/gpu/gpu_model",                 // Generic
    nullptr
};

static std::string tryReadGpuModel() {
    for (int i = 0; GPU_MODEL_PATHS[i] != nullptr; i++) {
        std::ifstream file(GPU_MODEL_PATHS[i]);
        if (!file.is_open()) continue;

        std::string value;
        std::getline(file, value);

        if (!value.empty()) return value;
    }
    return "Unknown";
}

static std::string detectVendor(const std::string& renderer) {
    if (renderer.find("Adreno") != std::string::npos) return "Qualcomm";
    if (renderer.find("Mali")   != std::string::npos) return "ARM";
    if (renderer.find("PowerVR")!= std::string::npos) return "Imagination";
    if (renderer.find("Xclipse")!= std::string::npos) return "Samsung/AMD";
    if (renderer.find("Intel")  != std::string::npos) return "Intel";
    return "Unknown";
}

namespace PocketLM {

void readGpu(GpuSnapshot* out) {
    memset(out, 0, sizeof(GpuSnapshot));

    std::string model = tryReadGpuModel();

    strncpy(out->renderer, model.c_str(),  sizeof(out->renderer)  - 1);
    strncpy(out->vendor,   detectVendor(model).c_str(),
                                           sizeof(out->vendor)    - 1);

    LOGI("GPU -> Renderer: %s | Vendor: %s",
         out->renderer, out->vendor);
}

} // namespace PocketLM