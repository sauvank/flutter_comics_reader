package com.sauvank.comicstream

import android.content.Intent
import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private var storagePermissionResult: MethodChannel.Result? = null

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "comicstream/device_files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasAllFilesAccess" -> result.success(hasDeviceFilesAccess())
                    "requestAllFilesAccess" -> requestDeviceFilesAccess(result)
                    "sharedStoragePath" -> result.success(
                        Environment.getExternalStorageDirectory().absolutePath
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasDeviceFilesAccess(): Boolean = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> Environment.isExternalStorageManager()
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        else -> true
    }

    private fun requestDeviceFilesAccess(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            result.success(openAllFilesAccessSettings())
            return
        }
        if (hasDeviceFilesAccess()) {
            result.success(true)
            return
        }
        if (storagePermissionResult != null) {
            result.error("request_in_progress", "Une demande d’accès est déjà en cours.", null)
            return
        }
        storagePermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE), storagePermissionRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != storagePermissionRequestCode) return
        storagePermissionResult?.success(hasDeviceFilesAccess())
        storagePermissionResult = null
    }

    private fun openAllFilesAccessSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        val intent = Intent(
            Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            Uri.parse("package:$packageName")
        )
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private companion object {
        const val storagePermissionRequestCode = 4201
    }

    @Suppress("DEPRECATION")
    private fun signingCertificateSha1(): List<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo?.apkContentsSigners ?: emptyArray()
        } else {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures ?: emptyArray()
        }
        return signatures.map { signature ->
            MessageDigest.getInstance("SHA-1").digest(signature.toByteArray())
                .joinToString(":") { byte -> "%02X".format(byte) }
        }
    }
}
