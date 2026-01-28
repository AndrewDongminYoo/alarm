package com.gdelataillade.alarm.services

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import io.flutter.Log
import kotlin.math.round

class VolumeService(
    context: Context,
) {
    companion object {
        private const val TAG = "VolumeService"
    }

    private var previousVolume: Int? = null
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var focusRequest: AudioFocusRequest? = null
    private val handler = Handler(Looper.getMainLooper())
    private var targetVolume: Int = 0
    private var volumeCheckRunnable: Runnable? = null

    fun setVolume(
        volume: Double,
        volumeEnforced: Boolean,
        showSystemUI: Boolean,
    ) {
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        previousVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        targetVolume = (round(volume * maxVolume)).toInt()
        audioManager.setStreamVolume(
            AudioManager.STREAM_MUSIC,
            targetVolume,
            if (showSystemUI) AudioManager.FLAG_SHOW_UI else 0,
        )

        if (volumeEnforced) {
            startVolumeEnforcement(showSystemUI)
        }
    }

    private fun startVolumeEnforcement(showSystemUI: Boolean) {
        // Define the Runnable that checks and enforces the volume level
        volumeCheckRunnable =
            Runnable {
                val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                if (currentVolume != targetVolume) {
                    audioManager.setStreamVolume(
                        AudioManager.STREAM_MUSIC,
                        targetVolume,
                        if (showSystemUI) AudioManager.FLAG_SHOW_UI else 0,
                    )
                }
                // Schedule the next check after 1000ms
                handler.postDelayed(volumeCheckRunnable!!, 1000)
            }
        // Start the first run
        handler.post(volumeCheckRunnable!!)
    }

    private fun stopVolumeEnforcement() {
        // Remove callbacks to stop enforcing volume
        volumeCheckRunnable?.let { handler.removeCallbacks(it) }
        volumeCheckRunnable = null
    }

    fun restorePreviousVolume(showSystemUI: Boolean) {
        // Stop the volume enforcement if it's active
        stopVolumeEnforcement()

        // Restore the previous volume
        previousVolume?.let { prevVolume ->
            audioManager.setStreamVolume(
                AudioManager.STREAM_MUSIC,
                prevVolume,
                if (showSystemUI) AudioManager.FLAG_SHOW_UI else 0,
            )
            previousVolume = null
        }
    }

    fun requestAudioFocus() {
        // minSdk 29 always supports AudioFocusRequest (API 26+)
        val audioAttributes =
            AudioAttributes
                .Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

        focusRequest =
            AudioFocusRequest
                .Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(audioAttributes)
                .build()

        val result = audioManager.requestAudioFocus(focusRequest!!)
        if (result != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            Log.e(TAG, "Audio focus request failed")
        }
    }

    fun abandonAudioFocus() {
        // minSdk 29 always supports abandonAudioFocusRequest (API 26+)
        focusRequest?.let {
            audioManager.abandonAudioFocusRequest(it)
        }
    }
}
