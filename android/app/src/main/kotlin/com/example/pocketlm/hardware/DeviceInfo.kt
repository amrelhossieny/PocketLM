package com.example.pocketlm.hardware

import android.content.Context
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import java.io.File

class DeviceInfo(
    private val context: Context,
    private val messenger: io.flutter.plugin.common.BinaryMessenger,
) {
    companion object {
        const val METHOD_CHANNEL = "pocketlm/device"
    }

    fun register() {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> result.success(getDeviceInfo())
                else -> result.notImplemented()
            }
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "brand"          to Build.BRAND,
            "manufacturer"   to Build.MANUFACTURER,
            "model"          to Build.MODEL,
            "device"         to Build.DEVICE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkVersion"     to Build.VERSION.SDK_INT,
            "hardware"       to Build.HARDWARE,
            "abis"           to Build.SUPPORTED_ABIS.toList(),
            "isArm64"        to Build.SUPPORTED_ABIS.contains("arm64-v8a"),
            "totalStorage"   to getTotalStorage(),
            "availStorage"   to getAvailStorage(),
        )
    }

    private fun getTotalStorage(): Long {
        return try {
            val stat = android.os.StatFs(context.filesDir.absolutePath)
            stat.totalBytes
        } catch (e: Exception) { 0L }
    }

    private fun getAvailStorage(): Long {
        return try {
            val stat = android.os.StatFs(context.filesDir.absolutePath)
            stat.availableBytes
        } catch (e: Exception) { 0L }
    }
}