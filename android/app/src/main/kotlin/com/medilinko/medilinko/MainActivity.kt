package com.medilinko.medilinko

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.medilinko/lockscreen"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableLockScreenFlags" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
                            window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            @Suppress("DEPRECATION")
                            window.addFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCK_SCREEN_ERROR", e.message, null)
                    }
                }
                "disableLockScreenFlags" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
                            window.clearFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            @Suppress("DEPRECATION")
                            window.clearFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCK_SCREEN_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
