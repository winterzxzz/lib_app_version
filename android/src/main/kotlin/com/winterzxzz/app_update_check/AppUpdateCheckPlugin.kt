package com.winterzxzz.app_update_check

import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native side of `app_update_check`.
 *
 * Methods:
 *  - `getAppInfo`  -> map(version, buildNumber, packageName, installSource, installerPackage)
 *  - `openUrl(url)` -> true when an activity handled the intent
 */
class AppUpdateCheckPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAppInfo" -> {
                try {
                    result.success(getAppInfo())
                } catch (e: Exception) {
                    result.error("APP_INFO_FAILED", e.message, null)
                }
            }
            "openUrl" -> {
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "Missing 'url' argument", null)
                } else {
                    result.success(openUrl(url))
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getAppInfo(): Map<String, Any?> {
        val packageManager = context.packageManager
        val packageName = context.packageName
        val info: PackageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
        }
        val versionCode: Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        val installer = installerPackage(packageManager, packageName)
        return mapOf(
            "version" to (info.versionName ?: ""),
            "buildNumber" to versionCode.toString(),
            "packageName" to packageName,
            "installSource" to installSource(installer),
            "installerPackage" to installer,
        )
    }

    private fun installerPackage(packageManager: PackageManager, packageName: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                packageManager.getInstallSourceInfo(packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName)
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Google Play installs (every track, including internal testing) report
     * `com.android.vending`. `adb install` / IDE runs report no installer at all.
     * Anything else (system package installer, third-party stores) is a sideload.
     */
    private fun installSource(installer: String?): String = when (installer) {
        PLAY_STORE_PACKAGE -> "playstore"
        null -> "development"
        else -> "sideload"
    }

    private fun openUrl(url: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            // ActivityNotFoundException, SecurityException, ...
            false
        }
    }

    private companion object {
        const val CHANNEL_NAME = "app_update_check"
        const val PLAY_STORE_PACKAGE = "com.android.vending"
    }
}
