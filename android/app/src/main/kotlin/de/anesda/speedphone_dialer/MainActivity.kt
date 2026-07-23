package de.anesda.speedphone_dialer

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "de.anesda.crmspeedphone.dialer/call"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCall" -> startCall(call.argument<String>("phone"), result)
                "configureIncomingCalls" -> {
                    try {
                        IncomingPairingStore.save(
                            this,
                            IncomingPairing(
                                server = call.argument<String>("server").orEmpty(),
                                deviceId = call.argument<String>("device_id").orEmpty(),
                                deviceToken = call.argument<String>("device_token").orEmpty(),
                            ),
                        )
                        result.success(null)
                    } catch (exception: Exception) {
                        result.error("PAIRING_CONFIG", exception.message, null)
                    }
                }
                "clearIncomingCalls" -> {
                    IncomingPairingStore.clear(this)
                    result.success(null)
                }
                "incomingCallPermission" -> result.success(
                    ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) ==
                        PackageManager.PERMISSION_GRANTED &&
                        ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) ==
                        PackageManager.PERMISSION_GRANTED,
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun startCall(phoneValue: String?, result: MethodChannel.Result) {
        val phone = phoneValue?.trim().orEmpty()
        if (!Regex("^\\+?[0-9]{5,20}$").matches(phone)) {
            result.error("INVALID_PHONE", "Die Telefonnummer ist ungültig.", null)
            return
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("CALL_PERMISSION", "Die Telefonberechtigung fehlt.", null)
            return
        }
        try {
            startActivity(Intent(Intent.ACTION_CALL, Uri.parse("tel:$phone")))
            result.success(null)
        } catch (exception: Exception) {
            result.error("CALL_FAILED", exception.message ?: "Anruf konnte nicht gestartet werden.", null)
        }
    }
}
