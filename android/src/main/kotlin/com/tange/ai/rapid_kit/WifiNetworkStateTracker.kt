package com.tange.ai.rapid_kit

internal class WifiNetworkStateTracker {
    private var lastKnownSsid: String? = null

    fun format(event: String, ssid: String?, network: String, capabilities: String): String {
        val currentSsid = normalizeSsid(ssid)
        val previousSsid = lastKnownSsid ?: NONE
        val ssidChanged = lastKnownSsid != null && currentSsid != UNKNOWN_SSID && currentSsid != lastKnownSsid
        if (currentSsid != UNKNOWN_SSID) lastKnownSsid = currentSsid
        return "[wifi_network_change] event=$event, ssid=$currentSsid, previousSsid=$previousSsid, ssidChanged=$ssidChanged, network=$network, capabilities=$capabilities"
    }

    companion object {
        const val NONE = "<none>"
        const val UNKNOWN_SSID = "<unknown>"

        fun normalizeSsid(ssid: String?): String {
            val normalized = ssid.orEmpty().trim().removePrefix("\"").removeSuffix("\"")
            if (normalized.isEmpty() || normalized == "<unknown ssid>") return UNKNOWN_SSID
            return normalized
        }
    }
}
