package com.example.pocketlm.hardware

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class GpuInfo(
    private val context: Context,
    private val messenger: io.flutter.plugin.common.BinaryMessenger,
) {
    companion object {
        const val METHOD_CHANNEL = "pocketlm/gpu"
        const val EVENT_CHANNEL = "pocketlm/gpu/realtime"
        const val INTERVAL_MS = 1000L

        private val GPU_FREQ_PATHS = listOf(
            "/sys/class/kgsl/kgsl-3d0/gpuclk",
            "/sys/class/kgsl/kgsl-3d0/devfreq/cur_freq",
            "/sys/class/misc/mali0/device/devfreq/gpufreq/cur_freq",
            "/sys/kernel/gpu/gpu_freq",
            "/sys/kernel/debug/clk/gfx3d_clk/measure",
        )

        private val GPU_MAX_FREQ_PATHS = listOf(
            "/sys/class/kgsl/kgsl-3d0/devfreq/max_freq",
            "/sys/class/misc/mali0/device/devfreq/gpufreq/max_freq",
            "/sys/kernel/gpu/gpu_max_freq",
        )

        // GPU renderer/vendor name sysfs paths, tried in order.
        private val GPU_MODEL_PATHS = listOf(
            "/sys/class/kgsl/kgsl-3d0/gpu_model",       // Qualcomm
            "/sys/class/misc/mali0/device/gpuinfo",      // Mali
            "/sys/kernel/gpu/gpu_model",                 // generic
        )
    }

    fun register() {
        registerMethodChannel()
        registerEventChannel()
    }

    private fun registerMethodChannel() {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getGpuInfo" -> result.success(getGpuInfo())
                else -> result.notImplemented()
            }
        }
    }

    private fun registerEventChannel() {
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var handler: Handler? = null
                private var runnable: Runnable? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    handler = Handler(Looper.getMainLooper())
                    runnable = object : Runnable {
                        override fun run() {
                            events.success(getRealtimeGpuInfo())
                            handler?.postDelayed(this, INTERVAL_MS)
                        }
                    }
                    handler?.post(runnable!!)
                }

                override fun onCancel(arguments: Any?) {
                    handler?.removeCallbacks(runnable!!)
                    handler = null
                    runnable = null
                }
            }
        )
    }

    private fun getGpuInfo(): Map<String, Any> {
        return mapOf(
            "renderer"       to getGpuRenderer(),
            "vendor"         to getGpuVendor(),
            "version"        to "Unknown",   // requires EGL context; omitted to avoid null/crash
            "maxFreqMhz"     to getGpuMaxFreqMhz(),
            "currentFreqMhz" to getGpuCurrentFreqMhz(),
            "usagePercent"   to getGpuUsage(),
        )
    }

    private fun getRealtimeGpuInfo(): Map<String, Any> {
        return mapOf(
            "currentFreqMhz" to getGpuCurrentFreqMhz(),
            "usagePercent"   to getGpuUsage(),
        )
    }

    /**
     * GLES20.glGetString() requires an active EGL context and must be called on a GL thread.
     * Calling it here (outside any surface/thread) always returns null and may throw on some
     * devices. We go straight to sysfs instead, which is reliable for Qualcomm (kgsl) and Mali.
     */
    private fun getGpuRenderer(): String = readFromSysfs() ?: "Unknown"

    private fun getGpuVendor(): String {
        // Derive vendor from renderer name so we don't need an EGL context.
        val renderer = getGpuRenderer().lowercase()
        return when {
            renderer.contains("adreno") -> "Qualcomm"
            renderer.contains("mali")   -> "ARM"
            renderer.contains("powervr") -> "Imagination Technologies"
            renderer.contains("apple")  -> "Apple"
            renderer.contains("intel")  -> "Intel"
            else                        -> "Unknown"
        }
    }

    private fun getGpuCurrentFreqMhz(): Long {
        GPU_FREQ_PATHS.forEach { path ->
            try {
                val hz = File(path).readText().trim().toLong()
                return hz / 1_000_000
            } catch (_: Exception) {}
        }
        return 0L
    }

    private fun getGpuMaxFreqMhz(): Long {
        GPU_MAX_FREQ_PATHS.forEach { path ->
            try {
                val hz = File(path).readText().trim().toLong()
                return hz / 1_000_000
            } catch (_: Exception) {}
        }
        return 0L
    }

    private fun getGpuUsage(): Double {
        // Qualcomm kgsl busy percentage
        try {
            val raw = File("/sys/class/kgsl/kgsl-3d0/gpu_busy_percentage").readText().trim()
            return raw.replace("%", "").trim().toDouble()
        } catch (_: Exception) {}

        // Generic kernel path
        try {
            return File("/sys/kernel/gpu/gpu_utilization").readText().trim().toDouble()
        } catch (_: Exception) {}

        return 0.0
    }

    private fun readFromSysfs(): String? {
        GPU_MODEL_PATHS.forEach { path ->
            try {
                val value = File(path).readText().trim()
                if (value.isNotBlank()) return value
            } catch (_: Exception) {}
        }
        return null
    }
}