package de.anesda.speedphone_dialer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class IncomingCallReceiverTest {
    @Test
    fun normalisiertEingehendeTelefonnummer() {
        assertEquals(
            "+493312882214",
            IncomingCallReceiver.normalizePhone("+49 (331) 288-2214"),
        )
    }

    @Test
    fun lehntSteuercodesAb() {
        assertNull(IncomingCallReceiver.normalizePhone("*21*123#"))
    }
}
