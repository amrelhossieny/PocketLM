#include "storage_reader.h"
#include <sys/statvfs.h>
#include <cstring>
#include <android/log.h>

#define TAG "PocketLM_Storage"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

namespace PocketLM {

void readStorage(StorageSnapshot* out, const char* appDataPath) {
    memset(out, 0, sizeof(StorageSnapshot));

    struct statvfs stat;

    // Use app data path passed from Flutter
    const char* path = (appDataPath && strlen(appDataPath) > 0)
                        ? appDataPath
                        : "/data"; // Fallback

    if (statvfs(path, &stat) != 0) {
        LOGE("statvfs failed for path: %s", path);
        return;
    }

    long long blockSize  = stat.f_frsize;       // Bytes per block
    long long totalBlocks = stat.f_blocks;
    long long freeBlocks  = stat.f_bavail;       // Available to app

    out->totalStorageBytes = blockSize * totalBlocks;
    out->freeStorageBytes  = blockSize * freeBlocks;
    out->usedStorageBytes  = out->totalStorageBytes - out->freeStorageBytes;

    LOGI("Storage -> Total: %lld GB | Free: %lld GB",
         out->totalStorageBytes / (1024*1024*1024),
         out->freeStorageBytes  / (1024*1024*1024));
}

} // namespace PocketLM