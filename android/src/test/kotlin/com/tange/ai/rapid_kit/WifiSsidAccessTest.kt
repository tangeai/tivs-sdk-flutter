package com.tange.ai.rapid_kit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WifiSsidAccessTest {
    @Test
    fun readIfAllowedSkipsReaderWhenLocationPermissionDenied() {
        var readerCalled = false

        val ssid = WifiSsidAccess.readIfAllowed(false, "<unknown>") {
            readerCalled = true
            "Office"
        }

        assertEquals("<unknown>", ssid)
        assertFalse(readerCalled)
    }

    @Test
    fun readIfAllowedRunsReaderWhenLocationPermissionGranted() {
        var readerCalled = false

        val ssid = WifiSsidAccess.readIfAllowed(true, "<unknown>") {
            readerCalled = true
            "Office"
        }

        assertEquals("Office", ssid)
        assertTrue(readerCalled)
    }
}
