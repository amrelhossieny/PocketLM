package com.example.pocketlm.hardware

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.RandomAccessFile

class CpuInfo(
    private val context: Context,
    private val messenger: io.flutter.plugin.common.BinaryMessenger,
) {
    companion object {
        const val METHOD_CHANNEL = "pocketlm/cpu"
        const val EVENT_CHANNEL = "pocketlm/cpu/realtime"
        const val INTERVAL_MS = 1000L

        private const val CPU_BASE = "/sys/devices/system/cpu"
        private const val FREQ_CUR = "cpufreq/scaling_cur_freq"
        private const val FREQ_MAX = "cpufreq/cpuinfo_max_freq"
        private const val FREQ_MIN = "cpufreq/cpuinfo_min_freq"
    }

    init {
        // Warm up CPU usage — first read is always bogus (compares against 0 baseline),
        // so we discard it immediately on construction.
        getCpuUsage()
    }

    fun register() {
        registerMethodChannel()
        registerEventChannel()
    }

    private fun registerMethodChannel() {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCpuInfo" -> result.success(getCpuInfo())
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
                            events.success(getRealtimeCpuInfo())
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

    private fun getCpuInfo(): Map<String, Any> {
        return mapOf(
            "coreCount"      to getCoreCount(),
            "architecture"   to getArchitecture(),
            "chipName"       to getChipName(),
            "minFreqMhz"     to getFreqMhz(0, FREQ_MIN),
            "maxFreqMhz"     to getFreqMhz(0, FREQ_MAX),
            "clockSpeedsMhz" to getAllCoreFrequencies(),
            "usagePercent"   to getCpuUsage(),
        )
    }

    private fun getRealtimeCpuInfo(): Map<String, Any> {
        return mapOf(
            "clockSpeedsMhz" to getAllCoreFrequencies(),
            "usagePercent"   to getCpuUsage(),
        )
    }

    private fun getCoreCount(): Int =
        Runtime.getRuntime().availableProcessors()

    private fun getArchitecture(): String =
        System.getProperty("os.arch") ?: "unknown"

    /**
     * Chip name resolution order:
     *  1. ro.product.board  — most reliable on Qualcomm (e.g. "lahaina", "taro")
     *  2. ro.hardware       — often "qcom" but still useful
     *  3. /proc/cpuinfo "Hardware" line — rarely populated on modern kernels
     */
    private fun getChipName(): String {
        return readBuildProp("ro.product.board")?.takeIf { it.isNotBlank() }
            ?: readBuildProp("ro.hardware")?.takeIf { it.isNotBlank() }
            ?: try {
                File("/proc/cpuinfo")
                    .readLines()
                    .firstOrNull { it.startsWith("Hardware") }
                    ?.substringAfter(":")
                    ?.trim()
            } catch (_: Exception) { null }
            ?: "Unknown"
    }

    private fun getAllCoreFrequencies(): List<Long> {
        val coreCount = getCoreCount()
        return (0 until coreCount).map { core -> getFreqMhz(core, FREQ_CUR) }
    }

    private fun getFreqMhz(core: Int, freqFile: String): Long {
        return try {
            val path = "$CPU_BASE/cpu$core/$freqFile"
            val khz = File(path).readText().trim().toLong()
            khz / 1000
        } catch (_: Exception) {
            0L
        }
    }

    // Guarded by the fact that getCpuUsage() is only ever called from the main/handler thread.
    private var lastIdle = 0L
    private var lastTotal = 0L

    private fun getCpuUsage(): Double {
    return try {
        if (lastTotal == 0L) {
            // First ever call — seed the baseline and wait for a real diff
            readCpuStat()
            Thread.sleep(500)
        }
        val (idle, total) = readCpuStat()
        val diffIdle = idle - lastIdle
        val diffTotal = total - lastTotal
        lastIdle = idle
        lastTotal = total
        if (diffTotal == 0L) 0.0
        else ((diffTotal - diffIdle).toDouble() / diffTotal) * 100.0
    } catch (_: Exception) { 0.0 }
}

private fun readCpuStat(): Pair<Long, Long> {
    val stats = RandomAccessFile("/proc/stat", "r")
    val line = stats.readLine()
    stats.close()
    val parts = line.split(" ").filter { it.isNotEmpty() }
    val idle = parts[4].toLong()
    val total = parts.drop(1).sumOf { it.toLong() }
    lastIdle = idle
    lastTotal = total
    return Pair(idle, total)
}

    private fun readBuildProp(key: String): String? {
        return try {
            val process = Runtime.getRuntime().exec("getprop $key")
            process.inputStream.bufferedReader().readLine()?.trim()?.takeIf { it.isNotBlank() }
        } catch (_: Exception) {
            null
        }
    }
}