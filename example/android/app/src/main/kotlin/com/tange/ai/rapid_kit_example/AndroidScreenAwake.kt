package com.tange.ai.rapid_kit_example

import android.view.Window
import android.view.WindowManager
import android.util.Log as Logging

internal class AndroidScreenAwake(private val _window: Window) {
    private val _owners = mutableSetOf<String>()
    private var _previous: Boolean? = null
    private var _foreground = true

    private fun is_awake(): Boolean =
        _window.attributes.flags and WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON != 0

    private fun apply_state(reason: String, owner: String = "none", enabled: String = "none"): String? {
        if (reason != "owner" && _owners.isEmpty() && _previous == null) return null
        val previous = _previous ?: is_awake()
        if (_foreground && _owners.isNotEmpty()) {
            if (_previous == null) _previous = previous
            _window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            _previous?.let {
                if (it) _window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                else _window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
            _previous = null
        }
        val awake = is_awake()
        val restored = _previous == null && awake == previous
        val message = "[ScreenAwake] event=$reason, owner=$owner, enabled=$enabled, foreground=$_foreground, owners=${_owners.size}, screen_awake=$awake, previous=$previous, restored=$restored, ts_epoch_ms=${System.currentTimeMillis()}"
        Logging.i("ScreenAwake", message)
        return message
    }

    fun set_enabled(owner: String, enabled: Boolean): String? {
        if (enabled) _owners.add(owner) else _owners.remove(owner)
        return apply_state("owner", owner, enabled.toString())
    }

    fun set_foreground(foreground: Boolean) {
        _foreground = foreground
        apply_state(if (foreground) "foreground" else "background")
    }

    fun close() {
        _owners.clear()
        _foreground = false
        apply_state("destroy")
    }
}
