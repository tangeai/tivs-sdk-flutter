package com.tange.ai.rapid_kit

import org.junit.Assert.assertEquals
import org.junit.Test

class WifiNetworkStateTrackerTest {
    @Test
    fun formatRecordsInitialSsidWithoutSwitch() {
        val tracker = WifiNetworkStateTracker()

        val message = tracker.format("initial", "\"Office\"", "1", "transport=wifi")

        assertEquals(
            "[wifi_network_change] event=initial, ssid=Office, previousSsid=<none>, ssidChanged=false, network=1, capabilities=transport=wifi",
            message
        )
    }

    @Test
    fun formatRecordsSsidSwitch() {
        val tracker = WifiNetworkStateTracker()

        tracker.format("initial", "Office", "1", "transport=wifi")
        val message = tracker.format("capabilities_changed", "CameraAP", "2", "transport=wifi")

        assertEquals(
            "[wifi_network_change] event=capabilities_changed, ssid=CameraAP, previousSsid=Office, ssidChanged=true, network=2, capabilities=transport=wifi",
            message
        )
    }

    @Test
    fun formatNormalizesBlankSsid() {
        val tracker = WifiNetworkStateTracker()

        val message = tracker.format("lost", "", "<none>", "transport=none")

        assertEquals(
            "[wifi_network_change] event=lost, ssid=<unknown>, previousSsid=<none>, ssidChanged=false, network=<none>, capabilities=transport=none",
            message
        )
    }

    @Test
    fun unknownSsidDoesNotReplacePreviousKnownSsid() {
        val tracker = WifiNetworkStateTracker()

        tracker.format("initial", "Office", "1", "transport=wifi")
        tracker.format("lost", "", "<none>", "transport=none")
        val message = tracker.format("available", "CameraAP", "2", "transport=wifi")

        assertEquals(
            "[wifi_network_change] event=available, ssid=CameraAP, previousSsid=Office, ssidChanged=true, network=2, capabilities=transport=wifi",
            message
        )
    }
}
