package com.tange.ai.rapid_kit

internal object WifiSsidAccess {
    fun readIfAllowed(
        locationPermissionGranted: Boolean,
        deniedValue: String,
        reader: () -> String
    ): String {
        return if (locationPermissionGranted) reader() else deniedValue
    }
}
