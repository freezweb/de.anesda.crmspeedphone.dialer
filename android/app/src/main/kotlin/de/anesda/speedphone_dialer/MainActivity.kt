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
            if (call.method != "startCall") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val phone = call.argument<String>("phone")?.trim().orEmpty()
            if (!Regex("^\\+?[0-9]{5,20}$").matches(phone)) {
                result.error("INVALID_PHONE", "Die Telefonnummer ist ungültig.", null)
                return@setMethodCallHandler
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
                != PackageManager.PERMISSION_GRANTED
            ) {
                result.error("CALL_PERMISSION", "Die Telefonberechtigung fehlt.", null)
                return@setMethodCallHandler
            }
            try {
                startActivity(Intent(Intent.ACTION_CALL, Uri.parse("tel:$phone")))
                result.success(null)
            } catch (exception: Exception) {
                result.error("CALL_FAILED", exception.message ?: "Anruf konnte nicht gestartet werden.", null)
            }
        }
    }
}
