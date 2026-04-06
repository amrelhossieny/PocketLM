#pragma once
#include "pocketlm_hardware.h"

namespace PocketLM {
    void readCpu(CpuSnapshot* out);
    void readCpuLiveFreqs(long* outFreqsMhz, int maxCores);
}