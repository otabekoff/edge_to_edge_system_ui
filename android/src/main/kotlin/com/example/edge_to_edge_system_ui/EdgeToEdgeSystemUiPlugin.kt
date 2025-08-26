package com.example.edge_to_edge_system_ui

import android.app.Activity
import android.content.Context
import android.os.Build
import android.view.View
import android.view.Window
import androidx.annotation.NonNull
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class EdgeToEdgeSystemUiPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "edge_to_edge_system_ui")
    channel.setMethodCallHandler(this)

    // Automatically configure edge-to-edge mode when the plugin is attached
    val activity = binding.applicationContext as? Activity
    activity?.let {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            WindowCompat.setDecorFitsSystemWindows(it.window, false)
        }
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initialize" -> {
        result.success(getSystemInfoMap())
      }
      "getSystemInfo" -> result.success(getSystemInfoMap())
      "enable" -> {
        setEdgeToEdge(true)
        result.success(null)
      }
      "disable" -> {
        setEdgeToEdge(false)
        result.success(null)
      }
      "setStyle" -> {
        val args = call.arguments as? Map<String, Any>
        if (args != null) {
          // For brevity, only apply navigation/status bar colors if provided
          val statusColor = args["statusBarColor"] as? Int
          val navColor = args["navigationBarColor"] as? Int
          val statusLight = args["statusBarLight"] as? Boolean ?: false
          val navLight = args["navigationBarLight"] as? Boolean ?: false
          applyStyle(statusColor, navColor, statusLight, navLight)
        }
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  private fun isEdgeToEdgeSupported(): Boolean {
    return Build.VERSION.SDK_INT >= Build.VERSION_CODES.R // 30+
  }

  private fun getSystemInfoMap(): Map<String, Any?> {
    val activity = this.activity ?: return mapOf()
    val window = activity.window
    val decorView: View = window.decorView

    val rootInsets = ViewCompat.getRootWindowInsets(decorView)
    val systemBars = rootInsets?.getInsets(WindowInsetsCompat.Type.systemBars())
    val statusBars = rootInsets?.getInsets(WindowInsetsCompat.Type.statusBars())
    val navigationBars = rootInsets?.getInsets(WindowInsetsCompat.Type.navigationBars())

    val density = activity.resources.displayMetrics.density
    fun toDp(px: Int?): Int {
      if (px == null) return 0
      return (px / density).toInt()
    }

    val systemTopDp = toDp(systemBars?.top ?: 0)
    val systemBottomDp = toDp(systemBars?.bottom ?: 0)
    val systemLeftDp = toDp(systemBars?.left ?: 0)
    val systemRightDp = toDp(systemBars?.right ?: 0)
    val statusBarDp = toDp(statusBars?.top ?: 0)
    val navBarDp = toDp(navigationBars?.bottom ?: 0)

    val isEdgeToEdgeEnabled = try {
      // Reflectively call getDecorFitsSystemWindows for wide compatibility
      val wm = WindowCompat::class.java.getMethod("getDecorFitsSystemWindows", Window::class.java)
      wm.invoke(null, window) as? Boolean ?: false
    } catch (e: Exception) {
      // Fallback: infer from legacy systemUiVisibility
      val flags = decorView.systemUiVisibility
      (flags and View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN) != 0 ||
        (flags and View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION) != 0
    }

    val resultMap = hashMapOf<String, Any?>(
      "isEdgeToEdgeEnabled" to isEdgeToEdgeEnabled,
      "isEdgeToEdgeSupported" to isEdgeToEdgeSupported(),
      "androidVersion" to Build.VERSION.SDK_INT,
      "androidRelease" to Build.VERSION.RELEASE,
      "systemBarsTop" to systemTopDp,
      "systemBarsBottom" to systemBottomDp,
      "systemBarsLeft" to systemLeftDp,
      "systemBarsRight" to systemRightDp,
      "statusBarsHeight" to statusBarDp,
      "navigationBarsHeight" to navBarDp,
      "hasNavigationBar" to hasNavigationBar(activity)
    )

    return resultMap
  }

  private fun setEdgeToEdge(enabled: Boolean) {
    val activity = this.activity ?: return
    val window = activity.window
    try {
      val method = WindowCompat::class.java.getMethod("setDecorFitsSystemWindows", Window::class.java, Boolean::class.java)
      method.invoke(null, window, enabled)
    } catch (e: Exception) {
      // Legacy fallback: set systemUiVisibility flags
      val decor = window.decorView
      if (!enabled) {
        decor.systemUiVisibility = decor.systemUiVisibility and
          View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN.inv() and
          View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION.inv()
      } else {
        decor.systemUiVisibility = decor.systemUiVisibility or
          View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
          View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
      }
    }
  }

  private fun applyStyle(statusColor: Int?, navColor: Int?, statusLight: Boolean, navLight: Boolean) {
    val activity = this.activity ?: return
    val window = activity.window
    if (statusColor != null) {
      window.statusBarColor = statusColor
    }
    if (navColor != null) {
      window.navigationBarColor = navColor
    }
    val controller = WindowInsetsControllerCompat(window, window.decorView)
    controller.isAppearanceLightStatusBars = statusLight
    controller.isAppearanceLightNavigationBars = navLight
  }

  private fun hasNavigationBar(context: Context): Boolean {
    val id = context.resources.getIdentifier("config_showNavigationBar", "bool", "android")
    return id > 0 && context.resources.getBoolean(id)
  }

  // ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // no-op duplicate handled earlier. Keep to satisfy interface
  }
}
