package com.tange.ai.rapid_kit

import android.Manifest
import android.Manifest.permission
import android.Manifest.permission.RECORD_AUDIO
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.view.Surface
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.tange.ai.rapid.kit.Logging
import com.netease.nis.captcha.Captcha
import com.netease.nis.captcha.CaptchaConfiguration
import com.netease.nis.captcha.CaptchaListener
import com.tange.ai.rapid.kit.Core
import com.tange.ai.rapid.kit.media.AoutAudioTrackProxy
import com.tange.ai.rapid.kit.media.MediaChat
import com.tange.ai.rapid.kit.media.MediaPlayer
import com.tange.ai.rapid.kit.media.SDL
import com.tange.ai.rapid.kit.media.VoiceCommunicationAudioMode
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.util.concurrent.atomic.AtomicLong

class RapidKitPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val TAG = "_RapidKitPlugin_"
        private val pathCounter = AtomicLong(0)
        private const val METHOD_EXPORT_CAPTURED_PICTURE = "exportCapturedPicture"
        private const val METHOD_ATTACH_PLAYER_TEXTURE = "attachPlayerTexture"
        private const val METHOD_DETACH_PLAYER_TEXTURE = "detachPlayerTexture"
        private const val METHOD_SET_ANDROID_GLES_VIDEO_RENDER = "setAndroidGlesVideoRender"
        private const val METHOD_UPDATE_PLAYER_TEXTURE_SIZE = "updatePlayerTextureSize"
        private const val METHOD_ATTACH_MEDIA_CHAT = "attachMediaChat"
        private const val METHOD_SET_PLAYER_VOICE_COMMUNICATION = "setAndroidPlayerVoiceCommunication"
        private const val METHOD_CHECK_MICROPHONE = "isMicrophoneRequired"
        private const val METHOD_EXPORT_CAPTURED_VIDEO = "exportCapturedVideo"
        private const val METHOD_REQUEST_WRITEABLE_CACHE_PATH = "requireWriteableCachePath"
        private const val METHOD_IS_FILE_ACCESS_PERMISSION_GRANTED = "isFileAccessPermissionGranted"
        private const val METHOD_REQUIRE_LOCATION_PERMISSION = "requireLocationPermission"
        private const val METHOD_CHECK_LOCATION_PERMISSION = "isLocationPermissionRequired"
        private const val METHOD_GET_CURRENT_WIFI = "currentWifi"
        private const val METHOD_ENSURE_TRANSPORT_WIFI = "ensureTransportByWifi"
        private const val METHOD_REQUEST_LOGGING_CACHE_DIR = "requireLoggingCacheDirectory"

        private const val PARAM_PLAYER_PTR = "playerPtr"
        private const val PARAM_PLAYER_OUTPUT_TOKEN = "playerOutputToken"
        private const val PARAM_TEXTURE_ID = "textureId"
        private const val PARAM_CHAT_PTR = "mediaChatPtr"
        private const val PARAM_HARDWARE_AEC = "hardwareAec"
        private const val PARAM_HARDWARE_NS = "hardwareNs"
        private const val PARAM_HARDWARE_AGC = "hardwareAgc"
        private const val PARAM_ENABLE = "enable"
        private const val PARAM_CONTAINER_WIDTH = "containerWidth"
        private const val PARAM_CONTAINER_HEIGHT = "containerHeight"

        private const val REQUEST_CODE_PERMISSION_BLUETOOTH = 0x211
        private const val REQUEST_CODE_PERMISSION_MICROPHONE = 0x212
        private const val REQUEST_CODE_PERMISSION_LOCATION = 0x213
        private const val REQUEST_CODE_PERMISSION_FILE_ACCESS = 0x214

        private const val RESULT_PERMISSION_GRANTED = 1
        private const val RESULT_PERMISSION_DENIED = 2
    }

    private var activity: Activity? = null
    private lateinit var channel: MethodChannel
    private lateinit var flutterEngine: FlutterPlugin.FlutterPluginBinding
    private val playerPtrToCapturedPicturePath = HashMap<Long, String>()
    private val textureEntryMap: HashMap<Long, TextureRegistry.SurfaceTextureEntry> = HashMap()
    private data class PlayerOutputBinding(val playerPtr: Long, val outputToken: Long)
    private val texturePlayerBindingMap = HashMap<Long, PlayerOutputBinding>()
    private val playerAoutProxyMap = HashMap<PlayerOutputBinding, AoutAudioTrackProxy>()
    private val voiceCommunicationPlayerSet = HashSet<PlayerOutputBinding>()
    private var rapidKitBleContext: RapidKitBleContext? = null
    private var androidGlesVideoRenderEnabled = false

    private var pendingBluetoothPermissionResult: Result? = null
    private var pendingLocationPermissionResult: Result? = null
    private var pendingFileAccessPermissionResult: Result? = null
    private var pendingMicrophonePermissionResult: Result? = null
    
    private var currentNetworkCallback: ConnectivityManager.NetworkCallback? = null
    private var connectivityManager: ConnectivityManager? = null
    private var wifiNetworkCallback: ConnectivityManager.NetworkCallback? = null
    private var wifiNetworkConnectivityManager: ConnectivityManager? = null
    private val wifiNetworkStateTracker = WifiNetworkStateTracker()
    @Volatile private var _wifi_network_logging_enabled = false

    private val permissionListener =
        PluginRegistry.RequestPermissionsResultListener { requestCode, _, grantResults ->
            if (REQUEST_CODE_PERMISSION_BLUETOOTH == requestCode) {
                if (grantResults.isNotEmpty()) {
                    Logging.i(TAG, "[permissionListener] REQUEST_CODE_PERMISSION_BLUETOOTH: ${grantResults[0]}")
                    val granted = grantResults[0] == PackageManager.PERMISSION_GRANTED
                    val permissionResult =
                        if (granted) RESULT_PERMISSION_GRANTED else RESULT_PERMISSION_DENIED
                    pendingBluetoothPermissionResult?.success(permissionResult)
                } else {
                    Logging.i(TAG, "[permissionListener] REQUEST_CODE_PERMISSION_BLUETOOTH: empty")
                    pendingBluetoothPermissionResult?.success(RESULT_PERMISSION_DENIED)
                }

                pendingBluetoothPermissionResult = null
                true
            } else if (REQUEST_CODE_PERMISSION_MICROPHONE == requestCode) {
                if (grantResults.isNotEmpty()) {
                    Logging.i(TAG, "[permissionListener] REQUEST_CODE_PERMISSION_MICROPHONE: ${grantResults[0]}")
                    val granted = grantResults[0] == PackageManager.PERMISSION_GRANTED
                    val permissionResult =
                        if (granted) RESULT_PERMISSION_GRANTED else RESULT_PERMISSION_DENIED
                    pendingMicrophonePermissionResult?.success(permissionResult)
                }
                pendingMicrophonePermissionResult = null
                true
            } else if (REQUEST_CODE_PERMISSION_LOCATION == requestCode) {
                if (grantResults.isNotEmpty()) {
                    Logging.i(TAG, "[permissionListener] REQUEST_CODE_PERMISSION_LOCATION: ${grantResults[0]}")
                    val granted = grantResults[0] == PackageManager.PERMISSION_GRANTED
                    val permissionResult =
                        if (granted) RESULT_PERMISSION_GRANTED else RESULT_PERMISSION_DENIED
                    pendingLocationPermissionResult?.success(permissionResult)
                    if (granted) {
                        activity?.applicationContext?.let { startWifiNetworkLoggingIfPermitted(it) }
                    }
                }
                pendingLocationPermissionResult = null
                true
            } else if (REQUEST_CODE_PERMISSION_FILE_ACCESS == requestCode) {
                if (grantResults.isNotEmpty()) {
                    val granted = grantResults[0] == PackageManager.PERMISSION_GRANTED
                    val permissionResult =
                        if (granted) RESULT_PERMISSION_GRANTED else RESULT_PERMISSION_DENIED
                    pendingFileAccessPermissionResult?.success(permissionResult)
                }
                pendingFileAccessPermissionResult = null
                true
            } else {
                false
            }
        }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Logging.i(TAG, "[onAttachedToActivity] ${binding.activity}")
        rapidKitBleContext?.disconnect()
        rapidKitBleContext = null
        activity = binding.activity
        createBleContextIfNeeded()
        binding.addRequestPermissionsResultListener(permissionListener)
    }

    private fun createBleContextIfNeeded() {
        if (rapidKitBleContext != null) return
        Logging.i(TAG, "[createBleContextIfNeeded] rapidKitBleContext is null, create new one")
        rapidKitBleContext = RapidKitBleContext(activity!!).apply {
            prepare()
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        flutterEngine = flutterPluginBinding
        Core.enableActivityLifecycleLogging(flutterPluginBinding.applicationContext)
        Logging.i(TAG, "[onAttachedToEngine] ${flutterEngine.applicationContext}, native-version = ${Core.versionName}")
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.tange.ai/rapid_kit/method.channel"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            "setWifiNetworkLoggingEnabled" -> {
                val enabled = call.argument<Boolean>("enabled")
                if (enabled == null) {
                    result.error("INVALID_ARGUMENT", "enabled is required", null)
                    return
                }
                _wifi_network_logging_enabled = enabled
                if (enabled) {
                    startWifiNetworkLoggingIfPermitted(flutterEngine.applicationContext)
                } else {
                    stopWifiNetworkLogging()
                }
                result.success(null)
            }

            "accountRobotCheck" -> {
                val methodResult = result
                activity?.let {
                    val captchaConfiguration =
                        CaptchaConfiguration.Builder().captchaId("f9c76200db674493a1319a4a3b6cb99e")
                            .listener(object : CaptchaListener {
                                override fun onValidate(
                                    result: String?,
                                    validate: String?,
                                    msg: String?,
                                    captchaType: String?,
                                    error: String?
                                ) {
                                    Logging.i(
                                        TAG,
                                        "[onMethodCall] onValidate: $result, $validate, $msg, $captchaType, $error"
                                    )
                                    if (result == "true") {
                                        methodResult.success(validate ?: "")
                                    } else {
                                        methodResult.success("ERROR:UNKNOWN")
                                    }
                                }

                                override fun onError(code: Int, msg: String?) =
                                    methodResult.success("ERROR:${code}:${msg}")

                                override fun onClose(p0: Captcha.CloseType?) {
                                }

                                override fun onCaptchaShow() {
                                }

                            }).build(it)

                    Captcha.getInstance().init(captchaConfiguration)
                    Captcha.getInstance().validate()
                }
            }

            "writeBluetoothData" -> {
                val data = call.arguments as ByteArray
                data?.let {
                    createBleContextIfNeeded()
                    rapidKitBleContext?.write(data) { ret ->
                        result.success(ret)
                    }
                } ?: run {
                    result.success(false)
                }
            }

            "disconnectBluetoothDevice" -> {
                val mac = call.argument<String>("mac")
                mac?.let {
                    createBleContextIfNeeded()
                    rapidKitBleContext?.disconnect()
                    result.success(null)
                }
            }

            "connectBluetoothDevice" -> {
                val mac = call.argument<String>("mac")
                val characteristics = call.argument<List<String>>("characteristics")
                mac?.let {
                    createBleContextIfNeeded()
                    val connected = rapidKitBleContext?.isConnected(it) == true
                    if (connected) {
                        result.success(true)
                    } else {
                        rapidKitBleContext?.connect(it, characteristics) { ret ->
                            result.success(ret)
                        }
                    }
                }
            }

            "isBluetoothPermissionGranted" -> {
                createBleContextIfNeeded()
                result.success(rapidKitBleContext?.permissionGranted() == true)
            }

            "acquireBluetoothPermission" -> {
                acquireBluetoothPermission(result)
            }

            "getBluetoothDevices" -> {
                createBleContextIfNeeded()
                rapidKitBleContext?.let {
                    val devices = it.nearbyDevices().map {
                        mapOf(
                            "name" to (it.name), "address" to it.address
                        )
                    }
                    result.success(devices)
                } ?: run {
                    result.success(emptyList<Map<String, String>>())
                }
            }

            "startBluetoothDiscovery" -> {
                createBleContextIfNeeded()
                rapidKitBleContext?.startDiscovery() ?: run {
                    Logging.i(
                        TAG,
                        "[onMethodCall] startBluetoothDiscovery failed: rapidKitBleContext NULL"
                    )
                }
                result.success(null)
            }

            "stopBluetoothDiscovery" -> {
                createBleContextIfNeeded()
                rapidKitBleContext?.stopDiscovery()
                result.success(null)
            }

            "isBluetoothEnabled" -> {
                val enabled = BluetoothAdapter.getDefaultAdapter().isEnabled
                Logging.i(TAG, "[onMethodCall] isBluetoothEnabled: $enabled")
                result.success(enabled)
            }

            METHOD_EXPORT_CAPTURED_VIDEO -> {
                val args = call.arguments as? Map<*, *>
                val path = args?.get("cachePath") as? String ?: run {
                    result.success(false)
                    return
                }
                val galleryName = args?.get("galleryName") as? String

                if (activity == null) {
                    result.success(false)
                    return
                }

                val ret = addVideoToGallery(activity!!, path, galleryName)

                File(path).delete()

                result.success(ret)
            }

            METHOD_REQUEST_WRITEABLE_CACHE_PATH -> {
                var path = ""
                activity?.let {
                    path = File(
                        it.filesDir, "rapid_writeable_cache_${System.currentTimeMillis()}_${pathCounter.incrementAndGet()}"
                    ).absolutePath
                }
                result.success(path)
            }

            METHOD_REQUEST_LOGGING_CACHE_DIR -> {
                var path = ""
                Logging.i(TAG, "[onMethodCall] $METHOD_REQUEST_LOGGING_CACHE_DIR ... $activity")
                flutterEngine.applicationContext?.let {
                    path = File(it.filesDir, "rapid_logging").absolutePath
                    Logging.i(TAG, "[onMethodCall] $METHOD_REQUEST_LOGGING_CACHE_DIR path = $path")
                }

                result.success(path)
            }

            "requestFileAccessPermission" -> {
               acquireFileAccessPermission(result)
            }

            METHOD_IS_FILE_ACCESS_PERMISSION_GRANTED -> {
                activity?.let {
                    result.success(isFileAccessPermissionGranted(it))
                } ?: run {
                    result.success(false)
                }
            }

            METHOD_ENSURE_TRANSPORT_WIFI -> {
                activity?.let {
                    ensureTransportWiFi(it, result)
                } ?: run {
                    result.success(false)
                }
            }

            "releaseTransportWiFi" -> {
                val success = releaseTransportWiFi()
                result.success(success)
            }

            METHOD_GET_CURRENT_WIFI -> {
                activity?.let {
                    val ssid = currentWiFiName(it)
                    result.success(ssid)
                } ?: run {
                    result.success("")
                }
            }

            METHOD_REQUIRE_LOCATION_PERMISSION -> {
                acquireLocationPermission(result)
            }

            METHOD_CHECK_LOCATION_PERMISSION -> {
                activity?.let {
                    val granted = ContextCompat.checkSelfPermission(
                        it, android.Manifest.permission.ACCESS_FINE_LOCATION
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                } ?: run {
                    result.success(false)
                }
            }

            "launchWiFiSettings" -> {
                activity?.let {
                    try {
                        it.startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        Logging.i(TAG, "[onMethodCall] launchWiFiSettings error: $e")
                        result.success(false)
                    }
                } ?: run {
                    Logging.i(TAG, "[onMethodCall] launchWiFiSettings error: activity is null")
                    result.success(false)
                }
            }

            METHOD_ATTACH_MEDIA_CHAT -> {
                val args = call.arguments as? Map<*, *>
                val chatPtr = args?.get(PARAM_CHAT_PTR) as? Long ?: run {
                    result.error("INVALID_ARGUMENT", "Could not extract $PARAM_CHAT_PTR", null)
                    return
                }
                val hardwareAec = args[PARAM_HARDWARE_AEC] as? Boolean ?: false
                val hardwareNs = args[PARAM_HARDWARE_NS] as? Boolean ?: false
                val hardwareAgc = args[PARAM_HARDWARE_AGC] as? Boolean ?: false

                MediaChat.attachAin(chatPtr, hardwareAec, hardwareNs, hardwareAgc)

                result.success(true)
            }

            METHOD_SET_PLAYER_VOICE_COMMUNICATION -> {
                val args = call.arguments as? Map<*, *>
                val playerPtr = args?.get(PARAM_PLAYER_PTR) as? Long ?: run {
                    result.error(
                        "INVALID_ARGUMENT",
                        "${METHOD_SET_PLAYER_VOICE_COMMUNICATION} Could not extract $PARAM_PLAYER_PTR",
                        null
                    )
                    return
                }
                val enable = args[PARAM_ENABLE] as? Boolean ?: false

                val outputToken = (args[PARAM_PLAYER_OUTPUT_TOKEN] as? Number)?.toLong() ?: 0L
                if (outputToken == 0L || (enable && MediaPlayer.getOutputToken(playerPtr) != outputToken)) {
                    result.success(false)
                    return
                }
                setPlayerVoiceCommunication(PlayerOutputBinding(playerPtr, outputToken), enable)

                result.success(true)
            }


            "requireMicrophone" -> {
                acquireMicrophonePermission(result)
            }

            METHOD_CHECK_MICROPHONE -> {
                activity?.let {
                    val hasPermission = ContextCompat.checkSelfPermission(
                        it, RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(hasPermission)
                } ?: run {
                    result.success(false)
                }
            }

            METHOD_EXPORT_CAPTURED_PICTURE -> {

                val args = call.arguments as? Map<*, *>
                val path = args?.get("cachePath") as? String ?: run {
                    result.success(false)
                    return
                }

                Logging.i(TAG, "[onMethodCall] $METHOD_EXPORT_CAPTURED_PICTURE path = $path")

                if (activity == null) {
                    Logging.i(TAG, "[onMethodCall] $METHOD_EXPORT_CAPTURED_PICTURE activity null")
                    result.success(false)
                    return
                }

                val ret = addImageToGallery(activity!!, path)
                File(path).delete()
                Logging.i(TAG, "[onMethodCall] $METHOD_EXPORT_CAPTURED_PICTURE ret = $ret")
                result.success(ret)
            }

            METHOD_ATTACH_PLAYER_TEXTURE -> {
                val args = call.arguments as? Map<*, *>
                val playerPtr = args?.get(PARAM_PLAYER_PTR) as? Long ?: run {
                    result.error(
                        "INVALID_ARGUMENT",
                        "${METHOD_ATTACH_PLAYER_TEXTURE} Could not extract playerPtr",
                        null
                    )
                    return
                }

                val outputToken = (args[PARAM_PLAYER_OUTPUT_TOKEN] as? Number)?.toLong() ?: 0L
                if (outputToken == 0L) {
                    result.error("INVALID_ARGUMENT", "Missing player output token", null)
                    return
                }
                val playerBinding = PlayerOutputBinding(playerPtr, outputToken)
                val registry = flutterEngine.textureRegistry
                val textureEntry = registry.createSurfaceTexture()
                val textureId = textureEntry.id()

                val texture = textureEntry.surfaceTexture()
                val containerWidth = (args[PARAM_CONTAINER_WIDTH] as? Number)?.toInt() ?: 0
                val containerHeight = (args[PARAM_CONTAINER_HEIGHT] as? Number)?.toInt() ?: 0
                if (containerWidth > 0 && containerHeight > 0) {
                    texture.setDefaultBufferSize(containerWidth, containerHeight)
                }
                val surface = Surface(texture)

                val voutPtr = try {
                    MediaPlayer.attachSDLForToken(
                        flutterEngine.applicationContext,
                        playerPtr,
                        outputToken,
                        surface
                    ) { proxy ->
                        playerAoutProxyMap[playerBinding] = proxy
                        if (voiceCommunicationPlayerSet.contains(playerBinding)) {
                            proxy.setVoiceCommunicationEnabled(true)
                        }
                    }
                } catch (error: Throwable) {
                    textureEntry.release()
                    throw error
                } finally {
                    surface.release()
                }
                if (voutPtr == 0L) {
                    textureEntry.release()
                    result.error("PLAYER_OUTPUT_ATTACH_FAILED", "Player output attachment failed", null)
                    return
                }
                textureEntryMap[textureId] = textureEntry
                texturePlayerBindingMap[textureId] = playerBinding

                Logging.i(
                    TAG,
                    "[attachPlayerTexture] textureId: $textureId -> ${textureEntry.hashCode()}, vout=$voutPtr, size=${containerWidth}x${containerHeight}, gles=$androidGlesVideoRenderEnabled"
                )

                result.success(textureId)
            }

            METHOD_DETACH_PLAYER_TEXTURE -> {
                val args = call.arguments as? Map<*, *>
                val textureIdInt = args?.get(PARAM_TEXTURE_ID) as? Int ?: run {
                    result.error(
                        "INVALID_ARGUMENT",
                        "${METHOD_DETACH_PLAYER_TEXTURE} Could not extract textureId",
                        null
                    )
                    return
                }

                val textureId = textureIdInt.toLong()

                val playerBinding = texturePlayerBindingMap.remove(textureId)
                if (playerBinding != null) {
                    playerAoutProxyMap.remove(playerBinding)
                    if (voiceCommunicationPlayerSet.remove(playerBinding)) {
                        VoiceCommunicationAudioMode.disable(
                            flutterEngine.applicationContext,
                            playerVoiceCommunicationOwner(playerBinding)
                        )
                    }
                }
                val textureEntry = textureEntryMap.remove(textureId)
                if (textureEntry != null) {
                    textureEntry.release()
                    Logging.i(TAG, "[detachPlayerTexture] textureEntry released for textureId: $textureId -> ${textureEntry.hashCode()}")
                } else {
                    Logging.i(TAG, "[detachPlayerTexture] textureEntry not found for textureId: $textureId")
                }

                result.success(null)
            }

            METHOD_UPDATE_PLAYER_TEXTURE_SIZE -> {
                val args = call.arguments as? Map<*, *>
                val textureId = (args?.get(PARAM_TEXTURE_ID) as? Number)?.toLong() ?: run {
                    result.error(
                        "INVALID_ARGUMENT",
                        "${METHOD_UPDATE_PLAYER_TEXTURE_SIZE} Could not extract textureId",
                        null
                    )
                    return
                }
                val containerWidth = (args[PARAM_CONTAINER_WIDTH] as? Number)?.toInt() ?: 0
                val containerHeight = (args[PARAM_CONTAINER_HEIGHT] as? Number)?.toInt() ?: 0
                val textureEntry = textureEntryMap[textureId]
                if (textureEntry != null && containerWidth > 0 && containerHeight > 0) {
                    textureEntry.surfaceTexture().setDefaultBufferSize(containerWidth, containerHeight)
                    val playerBinding = texturePlayerBindingMap[textureId]
                    val ret = playerBinding?.let {
                        MediaPlayer.notifyVideoOutputSizeChangedForToken(
                            it.playerPtr, it.outputToken, containerWidth, containerHeight)
                    } ?: 0
                    Logging.i(
                        TAG,
                        "[updatePlayerTextureSize] textureId: $textureId, size=${containerWidth}x${containerHeight}, player=$playerBinding, redraw=$ret, gles=$androidGlesVideoRenderEnabled"
                    )
                } else {
                    Logging.i(TAG, "[updatePlayerTextureSize] ignored, textureId=$textureId, size=${containerWidth}x${containerHeight}, found=${textureEntry != null}, gles=$androidGlesVideoRenderEnabled")
                }
                result.success(null)
            }

            METHOD_SET_ANDROID_GLES_VIDEO_RENDER -> {
                val args = call.arguments as? Map<*, *>
                val enable = args?.get(PARAM_ENABLE) as? Boolean ?: false
                androidGlesVideoRenderEnabled = enable
                SDL.setVoutAndroidUseGles(enable)
                Logging.i(TAG, "[setAndroidGlesVideoRender] enable=$enable")
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun currentWiFiName(context: Context): String {
        return WifiSsidAccess.readIfAllowed(hasFineLocationPermission(context), "") {
            readCurrentWiFiName(context)
        }
    }

    private fun readCurrentWiFiName(context: Context): String {
        val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val wifiInfo: WifiInfo = wifiManager.connectionInfo
        return wifiInfo.ssid.removePrefix("\"").removeSuffix("\"")
    }

    private fun currentWiFiNameForLog(
        context: Context,
        capabilities: NetworkCapabilities? = null
    ): String {
        return WifiSsidAccess.readIfAllowed(
            hasFineLocationPermission(context),
            WifiNetworkStateTracker.UNKNOWN_SSID
        ) {
            val ssidFromCapabilities = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                (capabilities?.transportInfo as? WifiInfo)?.ssid
            } else {
                null
            }
            WifiNetworkStateTracker.normalizeSsid(
                ssidFromCapabilities ?: readCurrentWiFiName(context)
            )
        }
    }

    private fun hasFineLocationPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun startWifiNetworkLoggingIfPermitted(context: Context) {
        if (!_wifi_network_logging_enabled) return
        if (!hasFineLocationPermission(context)) {
            Logging.i(TAG, "[wifi_network_monitor] skipped: location_permission_denied")
            return
        }
        startWifiNetworkLogging(context)
    }

    private fun startWifiNetworkLogging(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            Logging.i(TAG, "[wifi_network_monitor] unsupported_api, sdk=${Build.VERSION.SDK_INT}")
            return
        }
        if (wifiNetworkCallback != null) {
            Logging.i(TAG, "[wifi_network_monitor] already_started")
            return
        }

        val appContext = context.applicationContext
        val manager = appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        wifiNetworkConnectivityManager = manager

        val activeNetwork = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) manager.activeNetwork else null
        val activeCapabilities = activeNetwork?.let { manager.getNetworkCapabilities(it) }
        logWifiNetworkChange(appContext, "initial", activeNetwork, activeCapabilities)

        val networkRequest = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .build()
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)
                logWifiNetworkChange(
                    appContext,
                    "available",
                    network,
                    wifiNetworkConnectivityManager?.getNetworkCapabilities(network)
                )
            }

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                super.onCapabilitiesChanged(network, networkCapabilities)
                logWifiNetworkChange(appContext, "capabilities_changed", network, networkCapabilities)
            }

            override fun onLost(network: Network) {
                super.onLost(network)
                logWifiNetworkChange(appContext, "lost", network, null)
            }

            override fun onUnavailable() {
                super.onUnavailable()
                logWifiNetworkChange(appContext, "unavailable", null, null)
            }
        }

        try {
            manager.registerNetworkCallback(networkRequest, callback)
            wifiNetworkCallback = callback
            Logging.i(TAG, "[wifi_network_monitor] started")
        } catch (ex: SecurityException) {
            Logging.i(TAG, "[wifi_network_monitor] SecurityException: $ex")
            wifiNetworkConnectivityManager = null
        } catch (ex: RuntimeException) {
            Logging.i(TAG, "[wifi_network_monitor] RuntimeException: $ex")
            wifiNetworkConnectivityManager = null
        }
    }

    private fun stopWifiNetworkLogging() {
        val callback = wifiNetworkCallback ?: return
        try {
            wifiNetworkConnectivityManager?.unregisterNetworkCallback(callback)
            Logging.i(TAG, "[wifi_network_monitor] stopped")
        } catch (ex: RuntimeException) {
            Logging.i(TAG, "[wifi_network_monitor] stop failed: $ex")
        } finally {
            wifiNetworkCallback = null
            wifiNetworkConnectivityManager = null
        }
    }

    private fun logWifiNetworkChange(
        context: Context,
        event: String,
        network: Network?,
        capabilities: NetworkCapabilities?
    ) {
        if (!_wifi_network_logging_enabled) return
        val ssid = currentWiFiNameForLog(context, capabilities)
        val networkName = network?.toString() ?: WifiNetworkStateTracker.NONE
        val capabilitiesSummary = describeNetworkCapabilities(capabilities)
        Logging.i(TAG, wifiNetworkStateTracker.format(event, ssid, networkName, capabilitiesSummary))
    }

    private fun describeNetworkCapabilities(capabilities: NetworkCapabilities?): String {
        if (capabilities == null) return "transport=none"

        val transports = mutableListOf<String>()
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) transports.add("wifi")
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) transports.add("cellular")
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) transports.add("ethernet")
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) transports.add("vpn")

        val transport = if (transports.isEmpty()) "unknown" else transports.joinToString("+")
        val internet = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        val validated = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        val notMetered = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
        return "transport=$transport, internet=$internet, validated=$validated, notMetered=$notMetered"
    }

    private fun ensureTransportWiFi(context: Context, result: Result) {
        Logging.i(TAG, "[ensureTransportWiFi] start, currentWiFi: ${currentWiFiName(context)}")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            Logging.i(TAG, "[ensureTransportWiFi] API level too low")
            result.success(false)
            return
        }
        
        releaseTransportWiFi()
        
        connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        
        val networkRequest = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
            .build()
        
        currentNetworkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)
                Logging.i(TAG, "[ensureTransportWiFi] onAvailable")
                
                val currentWiFi = currentWiFiName(context)
                Logging.i(TAG, "[ensureTransportWiFi] current WiFi: $currentWiFi")
                
                connectivityManager?.unregisterNetworkCallback(this)
                
                val bindSuccess = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    connectivityManager?.bindProcessToNetwork(network) ?: false
                } else {
                    ConnectivityManager.setProcessDefaultNetwork(network)
                    true
                }
                
                Logging.i(TAG, "[ensureTransportWiFi] bindSuccess: $bindSuccess")
                result.success(bindSuccess)
            }
            
            override fun onUnavailable() {
                super.onUnavailable()
                Logging.i(TAG, "[ensureTransportWiFi] onUnavailable")
                connectivityManager?.unregisterNetworkCallback(this)
                result.success(false)
            }
        }
        
                 try {
             connectivityManager?.requestNetwork(networkRequest, currentNetworkCallback!!)
                 } catch (ex: SecurityException) {
            Logging.i(TAG, "[ensureTransportWiFi] SecurityException: $ex")
            result.success(false)
        }
    }

    private fun releaseTransportWiFi(): Boolean {
        return try {
            Logging.i(TAG, "[releaseTransportWiFi] start")
            
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                connectivityManager?.bindProcessToNetwork(null)
            } else {
                ConnectivityManager.setProcessDefaultNetwork(null)
            }
            
            
            currentNetworkCallback = null
            connectivityManager = null
            
            Logging.i(TAG, "[releaseTransportWiFi] success")
            true
        } catch (ex: Exception) {
            Logging.i(TAG, "[releaseTransportWiFi] Exception: $ex")
            false
        }
    }

    private fun setPlayerVoiceCommunication(player: PlayerOutputBinding, enable: Boolean) {
        if (enable) {
            voiceCommunicationPlayerSet.add(player)
            VoiceCommunicationAudioMode.enable(
                flutterEngine.applicationContext,
                playerVoiceCommunicationOwner(player)
            )
        } else if (voiceCommunicationPlayerSet.remove(player)) {
            VoiceCommunicationAudioMode.disable(
                flutterEngine.applicationContext,
                playerVoiceCommunicationOwner(player)
            )
        }

        playerAoutProxyMap[player]?.setVoiceCommunicationEnabled(enable)
        Logging.i(
            TAG,
            "[setPlayerVoiceCommunication] player=$player enable=$enable " +
                "hasAout=${playerAoutProxyMap.containsKey(player)}"
        )
    }

    private fun clearPlayerVoiceCommunication() {
        val activePlayers = voiceCommunicationPlayerSet.toList()
        voiceCommunicationPlayerSet.clear()
        activePlayers.forEach { player ->
            VoiceCommunicationAudioMode.disable(
                flutterEngine.applicationContext,
                playerVoiceCommunicationOwner(player)
            )
        }
        playerAoutProxyMap.clear()
        texturePlayerBindingMap.clear()
    }

    private fun playerVoiceCommunicationOwner(player: PlayerOutputBinding): String =
        "FlutterPlayer:${player.playerPtr}:${player.outputToken}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        _wifi_network_logging_enabled = false
        clearPlayerVoiceCommunication()
        stopWifiNetworkLogging()
        channel.setMethodCallHandler(null)
    }

     fun addImageToGallery(context: Context, imagePath: String): Boolean {
        val file = File(imagePath)
        if (!file.exists() || !file.isFile) {
            Logging.i(TAG, "[addImageToGallery] file not exist, $imagePath")
            return false
        }

        val filename = "IMG_${System.currentTimeMillis()}.jpg"
        val contentValues = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, filename)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
        }

        val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            contentValues.put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/")
            context.contentResolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues
            )
        } else {
            context.contentResolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues
            )
        }

        Logging.i(TAG, "[addImageToGallery] uri = $uri")

        if (uri != null) {
            try {
                context.contentResolver.openOutputStream(uri).use { outputStream ->
                    if (outputStream != null) {
                        FileInputStream(file).use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    } else {
                        throw IOException("Failed to get output stream")
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentValues.clear()
                    contentValues.put(MediaStore.Images.Media.IS_PENDING, false)
                    context.contentResolver.update(uri, contentValues, null, null)
                }

                Logging.i(TAG, "[addImageToGallery] success")
                return true
            } catch (e: IOException) {
                e.printStackTrace()
                Logging.i(TAG, "[addImageToGallery] Err = $e")
                context.contentResolver.delete(uri, null, null)
                return false
            }
        }

        return false
    }

    private fun addVideoToGallery(context: Context, videoPath: String, galleryName: String?): Boolean {
        val file = File(videoPath)
        if (!file.exists() || !file.isFile) {
            Logging.i(TAG, "[addVideoToGallery] file not exist, $videoPath")
            return false
        }

        val filename = if (galleryName != null) {
            if (galleryName.endsWith(".mp4")) galleryName else "$galleryName.mp4"
        } else {
            "VID_${System.currentTimeMillis()}.mp4"
        }
        val contentValues = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, filename)
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.DATE_TAKEN, System.currentTimeMillis())
        }

        val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            contentValues.put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/")
            contentValues.put(MediaStore.Video.Media.IS_PENDING, true)
            context.contentResolver.insert(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI, contentValues
            )
        } else {
            context.contentResolver.insert(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI, contentValues
            )
        }

        Logging.i(TAG, "[addVideoToGallery] uri = $uri")

        if (uri != null) {
            try {
                context.contentResolver.openOutputStream(uri).use { outputStream ->
                    if (outputStream != null) {
                        FileInputStream(file).use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    } else {
                        throw IOException("Failed to get output stream")
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentValues.clear()
                    contentValues.put(MediaStore.Video.Media.IS_PENDING, false)
                    context.contentResolver.update(uri, contentValues, null, null)
                }

                Logging.i(TAG, "[addVideoToGallery] success")
                return true
            } catch (e: IOException) {
                e.printStackTrace()
                Logging.i(TAG, "[addVideoToGallery] Err = $e")
                context.contentResolver.delete(uri, null, null)
                return false
            }
        }

        return false
    }

    private fun isFileAccessPermissionGranted(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10 and above does not require WRITE_EXTERNAL_STORAGE permission to save images in gallery
            true
        } else {
            // Check permission for Android 9 and below
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun acquireMicrophonePermission(result: Result) {
        activity?.let {
            Logging.i(TAG, "[acquireMicrophonePermission] try to get ...")
            pendingMicrophonePermissionResult = result
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                ActivityCompat.requestPermissions(it, arrayOf(RECORD_AUDIO), REQUEST_CODE_PERMISSION_MICROPHONE)
            } else {
                result.success(RESULT_PERMISSION_GRANTED)
            }
        }
    }

    private fun acquireBluetoothPermission(result: Result) {
        activity?.let {
            Logging.i(TAG, "[acquireBluetoothPermission] try to get ...")
            pendingBluetoothPermissionResult = result
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                ActivityCompat.requestPermissions(
                    it, arrayOf(
                        permission.BLUETOOTH_SCAN, permission.BLUETOOTH_CONNECT
                    ), REQUEST_CODE_PERMISSION_BLUETOOTH
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                ActivityCompat.requestPermissions(
                    it, arrayOf(permission.ACCESS_FINE_LOCATION), REQUEST_CODE_PERMISSION_BLUETOOTH
                )
            }
        } ?: run {
            result.success(RESULT_PERMISSION_DENIED)
        }
    }

    private fun acquireLocationPermission(result: Result) {
        activity?.let {
            Logging.i(TAG, "[acquireLocationPermission] try to get ...")
            pendingLocationPermissionResult = result
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                ActivityCompat.requestPermissions(
                    it, arrayOf(permission.ACCESS_FINE_LOCATION), REQUEST_CODE_PERMISSION_LOCATION
                )
            }
        } ?: run {
            result.success(RESULT_PERMISSION_DENIED)
        }
    }

    private fun acquireFileAccessPermission(result: Result) {
        activity?.let {
            Logging.i(TAG, "[acquireFileAccessPermission] try to get ...")
            pendingFileAccessPermissionResult = result
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                ActivityCompat.requestPermissions(
                    it, arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), REQUEST_CODE_PERMISSION_FILE_ACCESS
                )
            } else {
                Logging.i(TAG, "[acquireFileAccessPermission] Android 10+ does not require WRITE_EXTERNAL_STORAGE permission")
                result.success(RESULT_PERMISSION_GRANTED)
            }
        } ?: run {
            result.success(RESULT_PERMISSION_DENIED)
        }
    }
}
