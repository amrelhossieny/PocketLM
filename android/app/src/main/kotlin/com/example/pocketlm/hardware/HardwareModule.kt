package com.example.pocketlm.hardware

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine

class HardwareModule(
    private val context: Context,
    private val flutterEngine: FlutterEngine,
) {
    private val messenger get() = flutterEngine.dartExecutor.binaryMessenger

    fun register() {
        RamInfo(context, messenger).register()
        CpuInfo(context, messenger).register()
        GpuInfo(context, messenger).register()
        DeviceInfo(context, messenger).register()
    }
}