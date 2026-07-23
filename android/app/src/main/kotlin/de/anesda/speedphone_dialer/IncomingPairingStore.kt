package de.anesda.speedphone_dialer

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

data class IncomingPairing(
    val server: String,
    val deviceId: String,
    val deviceToken: String,
)

object IncomingPairingStore {
    private const val PREFERENCES = "speedphone_incoming_pairing"
    private const val SERVER = "server"
    private const val DEVICE_ID = "device_id"
    private const val DEVICE_TOKEN = "device_token"

    @Suppress("DEPRECATION")
    private fun preferences(context: Context): SharedPreferences {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        return EncryptedSharedPreferences.create(
            context,
            PREFERENCES,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    fun save(context: Context, pairing: IncomingPairing) {
        require(pairing.server.startsWith("https://")) {
            "Die CRM-Adresse muss HTTPS verwenden."
        }
        require(Regex("^[a-f0-9-]{36}$", RegexOption.IGNORE_CASE).matches(pairing.deviceId)) {
            "Die Geräte-ID ist ungültig."
        }
        require(Regex("^[A-Za-z0-9_-]{32,128}$").matches(pairing.deviceToken)) {
            "Das Gerätetoken ist ungültig."
        }
        preferences(context).edit()
            .putString(SERVER, pairing.server)
            .putString(DEVICE_ID, pairing.deviceId)
            .putString(DEVICE_TOKEN, pairing.deviceToken)
            .apply()
    }

    fun load(context: Context): IncomingPairing? {
        val preferences = preferences(context)
        val server = preferences.getString(SERVER, null) ?: return null
        val deviceId = preferences.getString(DEVICE_ID, null) ?: return null
        val deviceToken = preferences.getString(DEVICE_TOKEN, null) ?: return null
        return IncomingPairing(server, deviceId, deviceToken)
    }

    fun clear(context: Context) {
        preferences(context).edit().clear().apply()
    }
}
