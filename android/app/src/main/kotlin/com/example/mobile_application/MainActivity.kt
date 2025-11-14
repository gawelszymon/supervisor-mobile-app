package com.example.nadzorca

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "kiosk_controller"

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)

        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when(call.method) {
                    "startLockTask" -> {
                        try { startLockTask() } catch (_:Exception){}
                        result.success(null)
                    }
                    "stopLockTask" -> {
                        try { stopLockTask() } catch (_:Exception){}
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
