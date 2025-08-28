// EdgeToEdgeSystemUiPlugin.kt
package com.example.edge_to_edge_system_ui

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.Point
import android.os.Build
import android.util.Log
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.view.ViewGroup
import android.widget.FrameLayout
import android.view.Gravity
import androidx.activity.enableEdgeToEdge
import androidx.activity.ComponentActivity
import androidx.annotation.NonNull
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.engine.FlutterEngine
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

    // Track enabled state explicitly so getSystemInfo can be accurate.
    private var isEdgeToEdgeEnabled: Boolean = false
    // Whether the OS enforces edge-to-edge by default (Android 15+)
    private var isEnforcedBySystem: Boolean = false
    private var initialConfigured: Boolean = false

    // Status bar overlay fallback (nullable, created on demand)
    private var statusBarOverlay: View? = null

    private data class PendingStyle(
        val statusColor: Int?,
        val navColor: Int?,
        val statusLight: Boolean,
        val navLight: Boolean
    )
    private var pendingStyle: PendingStyle? = null

    companion object {
        private const val CHANNEL_NAME = "edge_to_edge_system_ui"
        private const val TAG = "EdgeToEdgeSystemUI"

        @JvmStatic
        fun registerWithEngine(engine: FlutterEngine, activity: Activity?) {
            val plugin = EdgeToEdgeSystemUiPlugin()
            plugin.attachActivityToEngine(engine, activity)
        }
    }

    fun attachActivityToEngine(engine: FlutterEngine, activity: Activity?) {
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        this.activity = activity
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                result.success(getSystemInfoMap())
            }
            "getSystemInfo" -> result.success(getSystemInfoMap())
            "enable" -> enableEdgeToEdge(call, result)
            "disable" -> disableEdgeToEdge(result)
            "setStyle" -> setSystemUIStyle(call, result)
            else -> result.notImplemented()
        }
    }

    private fun enableEdgeToEdge(call: MethodCall, result: Result) {
        val force = call.argument<Boolean>("force") ?: false
        val act = this.activity
        
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }

        if (!force && !isEdgeToEdgeSupported()) {
            result.error("NOT_SUPPORTED", "Edge-to-edge not supported on this device", null)
            return
        }

        act.runOnUiThread {
            try {
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM -> {
                        // Android 15+: Use enableEdgeToEdge() if activity is ComponentActivity
                        if (act is ComponentActivity) {
                            act.enableEdgeToEdge()
                            Log.d(TAG, "Used enableEdgeToEdge() for Android 15+")
                        } else {
                            // Fallback for non-ComponentActivity
                            enableEdgeToEdgeFallback(act)
                        }
                    }
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                        // Android 10-14: Use WindowCompat approach
                        enableEdgeToEdgeCompat(act)
                    }
                    else -> {
                        // Pre-Android 10: Use legacy approach
                        enableEdgeToEdgeLegacy(act)
                    }
                }
                
                isEdgeToEdgeEnabled = true
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to enable edge-to-edge", e)
                result.error("ENABLE_FAILED", "Failed to enable edge-to-edge: ${e.message}", null)
            }
        }
    }

    private fun disableEdgeToEdge(result: Result) {
        val act = this.activity
        
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }

        // If the OS enforces edge-to-edge (Android 15+), disabling is not possible.
        if (isEnforcedBySystem) {
            Log.d(TAG, "disableEdgeToEdge: OS enforces edge-to-edge; cannot disable")
            // Remove any overlay we created but report failure so UI knows disabling didn't change system state
            removeStatusBarOverlay()
            result.success(false)
            return
        }

        act.runOnUiThread {
            try {
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM -> {
                        // Android 15+: Edge-to-edge is enforced, but we can still adjust insets handling
                        disableEdgeToEdgeModern(act)
                    }
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                        // Android 10-14: Use WindowCompat approach
                        WindowCompat.setDecorFitsSystemWindows(act.window, true)
                    }
                    else -> {
                        // Pre-Android 10: Use legacy approach
                        disableEdgeToEdgeLegacy(act)
                    }
                }
                
                // Remove any overlay the plugin created so the visual state updates
                removeStatusBarOverlay()
                isEdgeToEdgeEnabled = false
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to disable edge-to-edge", e)
                result.error("DISABLE_FAILED", "Failed to disable edge-to-edge: ${e.message}", null)
            }
        }
    }

    private fun setSystemUIStyle(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        if (args == null) {
            result.error("INVALID_ARGS", "Arguments cannot be null", null)
            return
        }

        val statusColor = (args["statusBarColor"] as? Number)?.toInt()
        val navColor = (args["navigationBarColor"] as? Number)?.toInt()
        val statusLight = args["statusBarLight"] as? Boolean ?: false
        val navLight = args["navigationBarLight"] as? Boolean ?: false

        val act = activity
        if (act == null) {
            // Queue the style to apply later
            pendingStyle = PendingStyle(statusColor, navColor, statusLight, navLight)
            Log.d(TAG, "Queued system UI style until activity attaches: $pendingStyle")
            result.success(null)
            return
        }

        act.runOnUiThread {
            try {
                applySystemUIStyle(act, statusColor, navColor, statusLight, navLight)
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to apply system UI style", e)
                result.error("STYLE_FAILED", "Failed to apply style: ${e.message}", null)
            }
        }
    }

    private fun enableEdgeToEdgeCompat(activity: Activity) {
        val window = activity.window
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS or 
                WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION
            )
        }
        
        Log.d(TAG, "Enabled edge-to-edge using WindowCompat for API ${Build.VERSION.SDK_INT}")
    }

    private fun enableEdgeToEdgeFallback(activity: Activity) {
        val window = activity.window
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS or 
                WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION
            )
        }
        
        Log.d(TAG, "Enabled edge-to-edge using fallback method for Android 15+")
    }

    private fun enableEdgeToEdgeLegacy(activity: Activity) {
        val window = activity.window
        val decorView = window.decorView
        
        decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS or 
                WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION
            )
        }
        
        Log.d(TAG, "Enabled edge-to-edge using legacy method for API ${Build.VERSION.SDK_INT}")
    }

    private fun disableEdgeToEdgeModern(activity: Activity) {
        // On Android 15+, edge-to-edge is enforced, but we can control how content fits
        val window = activity.window
        WindowCompat.setDecorFitsSystemWindows(window, true)
        Log.d(TAG, "Adjusted insets handling for Android 15+")
    }

    private fun disableEdgeToEdgeLegacy(activity: Activity) {
        val window = activity.window
        val decorView = window.decorView
        decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
        Log.d(TAG, "Disabled edge-to-edge using legacy method")
    }

    private fun applySystemUIStyle(
        activity: Activity, 
        statusColor: Int?, 
        navColor: Int?, 
        statusLight: Boolean, 
        navLight: Boolean
    ) {
        val window = activity.window
        
        Log.d(TAG, "Applying system UI style - API: ${Build.VERSION.SDK_INT}, " +
                "statusColor: $statusColor, navColor: $navColor, " +
                "statusLight: $statusLight, navLight: $navLight")

        // For Android 15+, system bar colors are largely ignored in edge-to-edge mode
        // But we still try to set them for compatibility and non-edge-to-edge scenarios
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS or 
                WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION
            )

            statusColor?.let { color ->
                try {
                    window.statusBarColor = color
                    Log.d(TAG, "Set status bar color to: $color")
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to set status bar color: ${e.message}")
                }
            }

            navColor?.let { color ->
                try {
                    window.navigationBarColor = color
                    Log.d(TAG, "Set navigation bar color to: $color")
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to set navigation bar color: ${e.message}")
                }
            }
        }

        // Overlay fallback for devices where statusBarColor may be ignored 
        // (especially in edge-to-edge mode or when AppBar draws over status bar)
        try {
            if (statusColor != null && statusColor != Color.TRANSPARENT) {
                ensureStatusBarOverlay(window, statusColor)
                Log.d(TAG, "Applied status bar overlay with color: $statusColor")
            } else {
                removeStatusBarOverlay()
                Log.d(TAG, "Removed status bar overlay (transparent or null color)")
            }
        } catch (e: Exception) {
            Log.w(TAG, "StatusBar overlay handling failed: ${e.message}")
        }

        // Set icon/content brightness using WindowInsetsControllerCompat
        // FIXED: Correct the logic and API level checks
        try {
            val controller = WindowInsetsControllerCompat(window, window.decorView)
            
            // Status bar icons (Android 6.0+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // statusLight = true means we want light/white icons (for dark backgrounds)
                // isAppearanceLightStatusBars = true means dark icons (for light backgrounds)
                controller.isAppearanceLightStatusBars = !statusLight
                Log.d(TAG, "Set status bar icons to ${if (!statusLight) "dark" else "light"}")
            }
            
            // Navigation bar icons (Android 8.0+ API 26, not 27!)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // navLight = true means we want light/white icons (for dark backgrounds)
                // isAppearanceLightNavigationBars = true means dark icons (for light backgrounds)
                controller.isAppearanceLightNavigationBars = !navLight
                Log.d(TAG, "Set navigation bar icons to ${if (!navLight) "dark" else "light"}")
            } else {
                Log.d(TAG, "Navigation bar icon brightness not supported on API ${Build.VERSION.SDK_INT}")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to set system UI appearance: ${e.message}")
        }

        // Re-apply after a short delay to override potential embedding/Flutter overrides
        // Also re-apply the icon brightness settings
        try {
            window.decorView.postDelayed({
                try {
                    // Re-apply colors
                    if (statusColor != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        window.statusBarColor = statusColor
                        Log.d(TAG, "Reapplied status bar color: $statusColor")
                    }
                    if (navColor != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        window.navigationBarColor = navColor
                        Log.d(TAG, "Reapplied navigation bar color: $navColor")
                    }
                    
                    // Re-apply icon brightness
                    val controller = WindowInsetsControllerCompat(window, window.decorView)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        controller.isAppearanceLightStatusBars = !statusLight
                        Log.d(TAG, "Reapplied status bar icon brightness")
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        controller.isAppearanceLightNavigationBars = !navLight
                        Log.d(TAG, "Reapplied navigation bar icon brightness")
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Reapply failed: ${e.message}")
                }
            }, 250)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to schedule reapply: ${e.message}")
        }
    }

    // Create or update a top overlay view that simulates the status bar background.
    private fun ensureStatusBarOverlay(window: Window, color: Int) {
      try {
        val act = this.activity ?: return
        val decor = window.decorView as? ViewGroup ?: return

        if (statusBarOverlay == null) {
          val overlay = View(act)
          overlay.isClickable = false
          overlay.isFocusable = false
          overlay.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
          
          // Ensure overlay appears above all other content
          overlay.elevation = 1000f
          
          val height = getStatusBarHeight(act)
          val lp = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            height
          )
          lp.gravity = Gravity.TOP
          
          // Add overlay as the last child so it appears on top of app content
          decor.addView(overlay, lp)
          statusBarOverlay = overlay
          
          Log.d(TAG, "Created status bar overlay with height: ${height}px")
        }
        
        statusBarOverlay?.setBackgroundColor(color)
        statusBarOverlay?.visibility = View.VISIBLE
        
        Log.d(TAG, "Updated status bar overlay color to: $color")
      } catch (e: Exception) {
        Log.w(TAG, "ensureStatusBarOverlay failed: ${e.message}")
      }
    }
    
    private fun removeStatusBarOverlay() {
      try {
        val act = this.activity ?: run {
          statusBarOverlay = null
          return
        }
        val decor = act.window.decorView as? ViewGroup
        statusBarOverlay?.let { overlay ->
          try {
            decor?.removeView(overlay)
          } catch (_: Exception) {}
        }
        statusBarOverlay = null
      } catch (e: Exception) {
        Log.w("EdgeToEdgeSystemUiPlugin", "removeStatusBarOverlay failed: ${e.message}")
      }
    }
    
    private fun getStatusBarHeight(context: Context): Int {
      val resources = context.resources
      val id = resources.getIdentifier("status_bar_height", "dimen", "android")
      return if (id > 0) resources.getDimensionPixelSize(id) else (24 * resources.displayMetrics.density).toInt()
    }

    private fun isEdgeToEdgeSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP
    }

    private fun getSystemInfoMap(): Map<String, Any?> {
        val activity = this.activity
        val resultMap = hashMapOf<String, Any?>()

        // Return whether the plugin has enabled edge-to-edge (user action) and
        // also whether the system enforces it by default so UIs can adjust.
        resultMap["isEdgeToEdgeEnabled"] = isEdgeToEdgeEnabled
        resultMap["isEdgeToEdgeEnforcedBySystem"] = isEnforcedBySystem
        resultMap["isEdgeToEdgeSupported"] = isEdgeToEdgeSupported()
        resultMap["androidVersion"] = Build.VERSION.SDK_INT
        resultMap["androidRelease"] = Build.VERSION.RELEASE

        if (activity != null) {
            val window = activity.window
            val decorView = window.decorView
            val rootInsets = ViewCompat.getRootWindowInsets(decorView)
            val systemBars = rootInsets?.getInsets(WindowInsetsCompat.Type.systemBars())
            val statusBars = rootInsets?.getInsets(WindowInsetsCompat.Type.statusBars())
            val navigationBars = rootInsets?.getInsets(WindowInsetsCompat.Type.navigationBars())

            val density = activity.resources.displayMetrics.density
            fun toDp(px: Int?): Int = if (px == null) 0 else (px / density).toInt()

            resultMap["systemBarsTop"] = toDp(systemBars?.top)
            resultMap["systemBarsBottom"] = toDp(systemBars?.bottom)
            resultMap["systemBarsLeft"] = toDp(systemBars?.left)
            resultMap["systemBarsRight"] = toDp(systemBars?.right)
            resultMap["statusBarsHeight"] = toDp(statusBars?.top)
            resultMap["navigationBarsHeight"] = toDp(navigationBars?.bottom)
            resultMap["hasNavigationBar"] = hasNavigationBar(activity)
        } else {
            // Default values when activity is not available
            resultMap["systemBarsTop"] = 0
            resultMap["systemBarsBottom"] = 0
            resultMap["systemBarsLeft"] = 0
            resultMap["systemBarsRight"] = 0
            resultMap["statusBarsHeight"] = 0
            resultMap["navigationBarsHeight"] = 0
            resultMap["hasNavigationBar"] = false
        }

        return resultMap
    }

    private fun hasNavigationBar(context: Context): Boolean {
        return try {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val display = wm.defaultDisplay
            val realSize = Point()
            val displaySize = Point()

            display.getRealSize(realSize)
            display.getSize(displaySize)

            (realSize.x > displaySize.x) || (realSize.y > displaySize.y) ||
                hasNavigationBarResource(context)
        } catch (e: Exception) {
            Log.w(TAG, "hasNavigationBar fallback used: ${e.message}")
            hasNavigationBarResource(context)
        }
    }

    private fun hasNavigationBarResource(context: Context): Boolean {
        val id = context.resources.getIdentifier("config_showNavigationBar", "bool", "android")
        return id > 0 && context.resources.getBoolean(id)
    }

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity

        if (!initialConfigured) {
            try {
                // Android 15+ automatically enforces edge-to-edge
                isEnforcedBySystem = Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM
                Log.d(TAG, "isEnforcedBySystem=$isEnforcedBySystem (API=${Build.VERSION.SDK_INT})")
                initialConfigured = true
            } catch (e: Exception) {
                Log.w(TAG, "Failed to configure default edge-to-edge: ${e.message}")
            }
        }

        // Apply any pending style
        pendingStyle?.let { style ->
            activity?.runOnUiThread {
                Log.d(TAG, "Applying queued system UI style: $style")
                try {
                    applySystemUIStyle(
                        activity!!, 
                        style.statusColor, 
                        style.navColor, 
                        style.statusLight, 
                        style.navLight
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to apply queued style", e)
                }
                pendingStyle = null
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        // clean up overlay when activity detached
        removeStatusBarOverlay()
        activity = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}