package com.example.pocketlm.hardware

import android.app.ActivityManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class RamInfo(
    private val context: Context,
    private val messenger: io.flutter.plugin.common.BinaryMessenger,
) {
    companion object {
        const val METHOD_CHANNEL = "pocketlm/ram"
        const val EVENT_CHANNEL = "pocketlm/ram/realtime"
        const val INTERVAL_MS = 1000L
    }

    private val activityManager by lazy {
        context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    }

    fun register() {
        registerMethodChannel()
        registerEventChannel()
    }

    private fun registerMethodChannel() {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRamInfo" -> result.success(getRamInfo())
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
                            // Only send the values that actually change every second.
                            // Static fields (totalRam, lowMemThreshold) are fetched once
                            // via getRamInfo() and don't need to ride every tick.
                            events.success(getRealtimeRamInfo())
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

    /** Full snapshot — call once on init. */
    private fun getRamInfo(): Map<String, Any> {
        val memInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)

        return mapOf(
            "totalRam"        to memInfo.totalMem,
            "availableRam"    to memInfo.availMem,
            "usedRam"         to (memInfo.totalMem - memInfo.availMem),
            "isLowMemory"     to memInfo.lowMemory,
            "lowMemThreshold" to memInfo.threshold,
        )
    }

    /** Lightweight tick — only the fields that change. */
    private fun getRealtimeRamInfo(): Map<String, Any> {
        val memInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)

        return mapOf(
            "availableRam" to memInfo.availMem,
            "usedRam"      to (memInfo.totalMem - memInfo.availMem),
            "isLowMemory"  to memInfo.lowMemory,
        )
    }
}