package com.tange.ai.rapid_kit

import org.junit.Assert.assertEquals
import org.junit.Test

class RapidKitBleCharacteristicSelectorTest {
    private companion object {
        const val PropertyRead = 0x02
        const val PropertyWriteNoResponse = 0x04
        const val PropertyWrite = 0x08
        const val PropertyNotify = 0x10
    }

    @Test
    fun selectUsesWritableCharacteristicWhenPreferredUuidsDoNotMatch() {
        val candidates = listOf(
            RapidKitBleCharacteristicSelector.Candidate("00002b10-0000-1000-8000-00805f9b34fb", PropertyNotify),
            RapidKitBleCharacteristicSelector.Candidate("00002b11-0000-1000-8000-00805f9b34fb", PropertyWrite)
        )

        val selection = RapidKitBleCharacteristicSelector.select(
            candidates,
            listOf("0000fff1-0000-1000-8000-00805f9b34fb", "0000fec8-0000-1000-8000-00805f9b34fb")
        )

        assertEquals("00002b11-0000-1000-8000-00805f9b34fb", selection?.candidate?.uuid)
        assertEquals(100, selection?.score)
        assertEquals(RapidKitBleCharacteristicSelector.SelectionReason.Automatic, selection?.reason)
    }

    @Test
    fun selectPrefersMatchingWritableUuidOverHigherScoredAutoCandidate() {
        val candidates = listOf(
            RapidKitBleCharacteristicSelector.Candidate("00002b11-0000-1000-8000-00805f9b34fb", PropertyWrite),
            RapidKitBleCharacteristicSelector.Candidate("0000fff1-0000-1000-8000-00805f9b34fb", PropertyWrite or PropertyNotify or PropertyRead)
        )

        val selection = RapidKitBleCharacteristicSelector.select(
            candidates,
            listOf("00002b11-0000-1000-8000-00805f9b34fb")
        )

        assertEquals("00002b11-0000-1000-8000-00805f9b34fb", selection?.candidate?.uuid)
        assertEquals(RapidKitBleCharacteristicSelector.SelectionReason.Preferred, selection?.reason)
    }

    @Test
    fun writeNoResponseIsWritableAndUsesNoResponseWriteTypeOnlyWhenWriteIsMissing() {
        assertEquals(100, RapidKitBleCharacteristicSelector.calculateScore(PropertyWriteNoResponse))
        assertEquals(true, RapidKitBleCharacteristicSelector.prefersWriteNoResponse(PropertyWriteNoResponse))
        assertEquals(false, RapidKitBleCharacteristicSelector.prefersWriteNoResponse(PropertyWrite or PropertyWriteNoResponse))
    }

    @Test
    fun selectExcludesSigAssignedServicesFromAutomaticSelection() {
        val candidates = listOf(
            RapidKitBleCharacteristicSelector.Candidate(
                "00002a00-0000-1000-8000-00805f9b34fb",
                PropertyWrite or PropertyRead,
                "00001800-0000-1000-8000-00805f9b34fb"
            ),
            RapidKitBleCharacteristicSelector.Candidate(
                "00002b11-0000-1000-8000-00805f9b34fb",
                PropertyWriteNoResponse,
                "00001910-0000-1000-8000-00805f9b34fb"
            )
        )

        val selection = RapidKitBleCharacteristicSelector.select(
            candidates,
            listOf("0000fff1-0000-1000-8000-00805f9b34fb")
        )

        assertEquals("00002b11-0000-1000-8000-00805f9b34fb", selection?.candidate?.uuid)
        assertEquals(100, selection?.score)
        assertEquals(RapidKitBleCharacteristicSelector.SelectionReason.Automatic, selection?.reason)
    }

    @Test
    fun selectAllowsPreferredCharacteristicFromSigAssignedService() {
        val candidates = listOf(
            RapidKitBleCharacteristicSelector.Candidate("2A00", PropertyWrite or PropertyRead, "1800"),
            RapidKitBleCharacteristicSelector.Candidate("FFF2", PropertyWrite or PropertyNotify, "FFF0")
        )

        val selection = RapidKitBleCharacteristicSelector.select(
            candidates,
            listOf("00002a00-0000-1000-8000-00805f9b34fb")
        )

        assertEquals("2A00", selection?.candidate?.uuid)
        assertEquals(RapidKitBleCharacteristicSelector.SelectionReason.Preferred, selection?.reason)
    }

    @Test
    fun selectReturnsNullWhenOnlySigAssignedServiceIsWritable() {
        val selection = RapidKitBleCharacteristicSelector.select(
            listOf(RapidKitBleCharacteristicSelector.Candidate("2A00", PropertyWrite, "1800")),
            emptyList()
        )

        assertEquals(null, selection)
    }

    @Test
    fun sigAssignedServiceDetectionUsesExactAssignedRanges() {
        assertEquals(true, RapidKitBleCharacteristicSelector.isSigAssignedServiceUuid("1800"))
        assertEquals(true, RapidKitBleCharacteristicSelector.isSigAssignedServiceUuid("00001860-0000-1000-8000-00805f9b34fb"))
        assertEquals(false, RapidKitBleCharacteristicSelector.isSigAssignedServiceUuid("1910"))
        assertEquals(false, RapidKitBleCharacteristicSelector.isSigAssignedServiceUuid("12345678-1234-5678-1234-56789abcdef0"))
    }
}
