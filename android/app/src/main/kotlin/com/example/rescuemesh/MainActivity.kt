package com.example.rescuemesh

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.rescuemesh/hardware"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "getTotalRamBytes" -> {
                        try {
                            val am =
                                getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val memInfo = ActivityManager.MemoryInfo()
                            am.getMemoryInfo(memInfo)
                            // totalMem is total physical RAM in bytes
                            result.success(memInfo.totalMem)
                        } catch (e: Exception) {
                            result.error("RAM_ERROR", e.message, null)
                        }
                    }

                    "getPhysicalCoreCount" -> {
                        try {
                            // Runtime.availableProcessors() returns logical cores.
                            // For physical-core estimation we read /sys/devices/system/cpu
                            // and count unique core IDs (works on most Android devices).
                            val coreCount = try {
                                val cpuDir =
                                    java.io.File("/sys/devices/system/cpu")
                                val cpuFiles = cpuDir.listFiles { file ->
                                    file.name.matches(Regex("cpu[0-9]+"))
                                }
                                cpuFiles?.size?.coerceAtLeast(1)
                                    ?: Runtime.getRuntime().availableProcessors()
                            } catch (_: Exception) {
                                Runtime.getRuntime().availableProcessors()
                            }
                            result.success(coreCount)
                        } catch (e: Exception) {
                            result.error("CORE_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
