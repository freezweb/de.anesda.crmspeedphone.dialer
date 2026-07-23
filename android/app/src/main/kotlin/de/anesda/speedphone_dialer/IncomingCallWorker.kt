package de.anesda.speedphone_dialer

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import java.net.URLEncoder

class IncomingCallWorker(
    appContext: Context,
    parameters: WorkerParameters,
) : CoroutineWorker(appContext, parameters) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val phone = inputData.getString(PHONE)
            ?.takeIf { Regex("^\\+?[0-9]{5,20}$").matches(it) }
            ?: return@withContext Result.failure()
        val pairing = IncomingPairingStore.load(applicationContext)
            ?: return@withContext Result.failure()

        try {
            val endpoint = URI(pairing.server).toURL()
            if (endpoint.protocol != "https") {
                return@withContext Result.failure()
            }
            val body = formBody(
                mapOf(
                    "operation" to "incoming_call",
                    "device_id" to pairing.deviceId,
                    "device_token" to pairing.deviceToken,
                    "phone" to phone,
                ),
            )
            val connection = (endpoint.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 8_000
                readTimeout = 8_000
                doOutput = true
                setRequestProperty("Accept", "application/json")
                setRequestProperty("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
                setRequestProperty("X-SpeedPhone-Dialer", "1")
            }
            connection.outputStream.use { output ->
                output.write(body.toByteArray(Charsets.UTF_8))
            }
            val status = connection.responseCode
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val response = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
            val success = runCatching { JSONObject(response).optBoolean("success", false) }
                .getOrDefault(false)
            connection.disconnect()

            when {
                status in 200..299 && success -> Result.success()
                status >= 500 -> Result.retry()
                else -> Result.failure()
            }
        } catch (_: Exception) {
            if (runAttemptCount < 5) Result.retry() else Result.failure()
        }
    }

    private fun formBody(values: Map<String, String>): String =
        values.entries.joinToString("&") { (key, value) ->
            "${URLEncoder.encode(key, Charsets.UTF_8.name())}=" +
                URLEncoder.encode(value, Charsets.UTF_8.name())
        }

    companion object {
        const val PHONE = "phone"
    }
}
