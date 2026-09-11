package com.nusarta.app

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.ViewGroup
import android.widget.ImageView
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var startupArtwork: ImageView? = null
    private var flutterVisible = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        }
        if (!flutterVisible) {
            // This resource is the unchanged official splash_screen.png artwork.
            startupArtwork = ImageView(this).apply {
                setBackgroundColor(Color.rgb(6, 59, 47))
                setImageResource(R.drawable.splash_full)
                scaleType = ImageView.ScaleType.FIT_CENTER
                importantForAccessibility = android.view.View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }
            addContentView(startupArtwork, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            ))
        }
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        flutterVisible = true
        startupArtwork?.let { artwork ->
            (artwork.parent as? ViewGroup)?.removeView(artwork)
        }
        startupArtwork = null
    }
}
