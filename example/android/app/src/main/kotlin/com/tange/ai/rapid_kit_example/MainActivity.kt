package com.tange.ai.rapid_kit_example

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.tange.ai/rapid_kit_example/method.channel/preference_store"
    private var _screen_awake: AndroidScreenAwake? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        _screen_awake = AndroidScreenAwake(window)
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger,
            "com.tange.ai/rapid_kit_example/method.channel/screen_awake").setMethodCallHandler { call, result ->
            val owner = call.argument<String>("owner")
            val enabled = call.argument<Boolean>("enabled")
            when {
                call.method != "setEnabled" -> result.notImplemented()
                owner.isNullOrEmpty() || enabled == null ->
                    result.error("INVALID_ARGUMENT", "Owner and enabled are required", null)
                else -> {
                    result.success(_screen_awake?.set_enabled(owner, enabled))
                }
            }
        }

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("preferences", Context.MODE_PRIVATE)
            val key = call.argument<String>("key")

            when (call.method) {
                "putPreferencesInt" -> {
                    val value = call.argument<Int>("value")
                    if (key != null && value != null) {
                        prefs.edit().putInt(key, value).apply()
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Arguments are not valid for putPreferencesInt", null)
                    }
                }
                "getPreferencesInt" -> {
                    val defaultValue = call.argument<Int>("defaultValue") ?: 0
                    if (key != null) {
                        val value = prefs.getInt(key, defaultValue)
                        result.success(value)
                    } else {
                        result.error("INVALID_ARGUMENT", "Key is not valid for getPreferencesInt", null)
                    }
                }
                "putPreferencesString" -> {
                    val value = call.argument<String>("value")
                    if (key != null && value != null) {
                        prefs.edit().putString(key, value).apply()
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Arguments are not valid for putPreferencesString", null)
                    }
                }
                "getPreferencesString" -> {
                    val defaultValue = call.argument<String>("defaultValue") ?: ""
                    if (key != null) {
                        val value = prefs.getString(key, defaultValue)
                        result.success(value)
                    } else {
                        result.error("INVALID_ARGUMENT", "Key is not valid for getPreferencesString", null)
                    }
                }
                "putPreferencesBool" -> {
                    val value = call.argument<Boolean>("value")
                    if (key != null && value != null) {
                        prefs.edit().putBoolean(key, value).apply()
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Arguments are not valid for putPreferencesBool", null)
                    }
                }
                "getPreferencesBool" -> {
                    val defaultValue = call.argument<Boolean>("defaultValue") ?: false
                    if (key != null) {
                        val value = prefs.getBoolean(key, defaultValue)
                        result.success(value)
                    } else {
                        result.error("INVALID_ARGUMENT", "Key is not valid for getPreferencesBool", null)
                    }
                }
                "removePreferencesKey" -> {
                    if (key != null) {
                        prefs.edit().remove(key).apply()
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Key is not valid for removePreferencesKey", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        _screen_awake?.set_foreground(true)
    }

    override fun onPause() {
        _screen_awake?.set_foreground(false)
        super.onPause()
    }

    override fun onDestroy() {
        _screen_awake?.close()
        _screen_awake = null
        super.onDestroy()
    }
}
