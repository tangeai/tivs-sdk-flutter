package com.tange.ai.rapid_kit

internal object RapidKitBleCharacteristicSelector {
    private const val BLUETOOTH_BASE_UUID_SUFFIX = "-0000-1000-8000-00805f9b34fb"
    private const val PROPERTY_READ = 0x02
    private const val PROPERTY_WRITE_NO_RESPONSE = 0x04
    private const val PROPERTY_WRITE = 0x08
    private const val PROPERTY_NOTIFY = 0x10
    private const val PROPERTY_INDICATE = 0x20

    // Source snapshot: Bluetooth SIG assigned_numbers/uuids/service_uuids.yaml through 0x1860.
    private val SIG_ASSIGNED_SERVICE_UUID_RANGES = listOf(
        0x1800..0x180a,
        0x180d..0x1816,
        0x1818..0x1829,
        0x183a..0x1840,
        0x1843..0x1860
    )

    enum class SelectionReason {
        Preferred,
        Automatic
    }

    data class Candidate(
        val uuid: String,
        val properties: Int,
        val serviceUuid: String = "",
        val index: Int = -1
    )

    data class Selection(
        val candidate: Candidate,
        val score: Int,
        val reason: SelectionReason
    )

    fun select(candidates: List<Candidate>, preferredUuids: Collection<String>?): Selection? {
        val preferred = preferredUuids?.map(::normalizeUuid)?.toSet().orEmpty()
        var preferredSelection: Selection? = null
        var automaticSelection: Selection? = null

        candidates.forEach { candidate ->
            val score = calculateScore(candidate.properties)
            if (score <= 0) return@forEach

            val normalizedUuid = normalizeUuid(candidate.uuid)
            if (preferred.contains(normalizedUuid) && score > (preferredSelection?.score ?: -1)) {
                preferredSelection = Selection(candidate, score, SelectionReason.Preferred)
            }
            if (!isSigAssignedServiceUuid(candidate.serviceUuid) && score > (automaticSelection?.score ?: -1)) {
                automaticSelection = Selection(candidate, score, SelectionReason.Automatic)
            }
        }

        return preferredSelection ?: automaticSelection
    }

    fun isSigAssignedServiceUuid(uuid: String): Boolean {
        val normalizedUuid = normalizeUuid(uuid)
        if (normalizedUuid.length != 36 ||
            !normalizedUuid.startsWith("0000") ||
            !normalizedUuid.endsWith(BLUETOOTH_BASE_UUID_SUFFIX)
        ) {
            return false
        }

        val shortUuid = normalizedUuid.substring(4, 8).toIntOrNull(16) ?: return false
        return SIG_ASSIGNED_SERVICE_UUID_RANGES.any { shortUuid in it }
    }

    private fun normalizeUuid(uuid: String): String {
        val normalizedUuid = uuid.lowercase()
        return when (normalizedUuid.length) {
            4 -> "0000$normalizedUuid$BLUETOOTH_BASE_UUID_SUFFIX"
            8 -> "$normalizedUuid$BLUETOOTH_BASE_UUID_SUFFIX"
            else -> normalizedUuid
        }
    }

    fun calculateScore(properties: Int): Int {
        if (!supportsWrite(properties)) return 0

        var score = 100
        if ((properties and PROPERTY_NOTIFY) > 0) score += 50
        if ((properties and PROPERTY_INDICATE) > 0) score += 40
        if ((properties and PROPERTY_READ) > 0) score += 10
        return score
    }

    fun supportsWrite(properties: Int): Boolean {
        return (properties and PROPERTY_WRITE) > 0 || (properties and PROPERTY_WRITE_NO_RESPONSE) > 0
    }

    fun prefersWriteNoResponse(properties: Int): Boolean {
        return (properties and PROPERTY_WRITE) == 0 && (properties and PROPERTY_WRITE_NO_RESPONSE) > 0
    }

    fun formatProperties(properties: Int): String {
        val flags = mutableListOf<String>()
        if ((properties and PROPERTY_WRITE) > 0) flags.add("W")
        if ((properties and PROPERTY_WRITE_NO_RESPONSE) > 0) flags.add("WNR")
        if ((properties and PROPERTY_NOTIFY) > 0) flags.add("N")
        if ((properties and PROPERTY_INDICATE) > 0) flags.add("I")
        if ((properties and PROPERTY_READ) > 0) flags.add("R")
        return if (flags.isEmpty()) "-" else flags.joinToString("+")
    }
}
