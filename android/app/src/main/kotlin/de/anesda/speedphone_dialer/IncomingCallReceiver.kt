package de.anesda.speedphone_dialer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class IncomingCallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            return
        }
        if (intent.getStringExtra(TelephonyManager.EXTRA_STATE) !=
            TelephonyManager.EXTRA_STATE_RINGING
        ) {
            return
        }
        if (!intent.hasExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)) {
            return
        }

        val phone = normalizePhone(
            intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER).orEmpty(),
        ) ?: return
        if (IncomingPairingStore.load(context) == null) {
            return
        }

        val request = OneTimeWorkRequestBuilder<IncomingCallWorker>()
            .setInputData(Data.Builder().putString(IncomingCallWorker.PHONE, phone).build())
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS)
            .build()
        val minute = System.currentTimeMillis() / 60_000L
        WorkManager.getInstance(context).enqueueUniqueWork(
            "speedphone-incoming-${phone.hashCode()}-$minute",
            ExistingWorkPolicy.KEEP,
            request,
        )
    }

    companion object {
        fun normalizePhone(value: String): String? {
            if (value.any { it in "*#;," }) {
                return null
            }
            val normalized = value.trim().filterIndexed { index, character ->
                character.isDigit() || (character == '+' && index == 0)
            }
            return normalized.takeIf { Regex("^\\+?[0-9]{5,20}$").matches(it) }
        }
    }
}
