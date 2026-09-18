package com.sauvank.comicstream

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "comicstream/security")
            .setMethodCallHandler { call, result ->
                if (call.method == "signingCertificateSha1") {
                    result.success(signingCertificateSha1())
                } else {
                    result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun signingCertificateSha1(): List<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo.apkContentsSigners
        } else {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
        }
        return signatures.map { signature ->
            MessageDigest.getInstance("SHA-1").digest(signature.toByteArray())
                .joinToString(":") { byte -> "%02X".format(byte) }
        }
    }
}
