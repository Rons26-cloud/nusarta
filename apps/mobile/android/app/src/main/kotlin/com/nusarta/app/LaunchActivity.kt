package com.nusarta.app

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.view.ViewTreeObserver
import android.widget.ImageView

/** Paint the full-screen artwork before loading the Flutter engine. */
class LaunchActivity : Activity() {
    private var launchedFlutter = false
    private var artworkDrawn = false
    private var nativeReleased = Build.VERSION.SDK_INT < Build.VERSION_CODES.S

    private fun launchFlutterWhenVisible() {
        if (!artworkDrawn || !nativeReleased || launchedFlutter) return
        launchedFlutter = true
        startActivity(Intent(this, MainActivity::class.java))
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view ->
                view.remove()
                nativeReleased = true
                window.decorView.post { launchFlutterWhenVisible() }
            }
        }
        val artwork = ImageView(this).apply {
            setBackgroundColor(Color.rgb(6, 59, 47))
            // Full-screen activity content, never an Android splash icon.
            setImageResource(R.drawable.splash_full)
            scaleType = ImageView.ScaleType.CENTER_CROP
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        setContentView(artwork)
        artwork.viewTreeObserver.addOnDrawListener(object : ViewTreeObserver.OnDrawListener {
            override fun onDraw() {
                if (artworkDrawn) return
                artworkDrawn = true
                artwork.post {
                    artwork.viewTreeObserver.removeOnDrawListener(this)
                    launchFlutterWhenVisible()
                }
            }
        })
    }

    override fun onStop() {
        super.onStop()
        // Retain the painted artwork until MainActivity's first Flutter frame,
        // then remove this startup-only activity from back navigation.
        if (launchedFlutter) finish()
    }
}
