package com.example.flutter_application_dexcom

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class PermissionsRationaleActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Create layout programmatically (no XML needed)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(50, 100, 50, 50)
        }

        val explanation = TextView(this).apply {
            text = """
                This app requires access to your health data 
                (e.g., glucose, steps, heart rate) 
                to provide accurate health tracking and analytics.
                
                Your data is never shared without your consent.
                
                You can review or change permissions in Health Connect.
            """.trimIndent()
        }

        val privacyButton = Button(this).apply {
            text = "View Privacy Policy"
            setOnClickListener {
                val browserIntent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("https://your-privacy-policy-url.com") // ← CHANGE THIS
                )
                startActivity(browserIntent)
            }
        }

        val openSettingsButton = Button(this).apply {
            text = "Open Health Connect Settings"
            setOnClickListener {
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:com.google.android.apps.healthdata")
                    }
                    startActivity(intent)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }

        layout.addView(explanation)
        layout.addView(privacyButton)
        layout.addView(openSettingsButton)

        setContentView(layout)
    }
}
