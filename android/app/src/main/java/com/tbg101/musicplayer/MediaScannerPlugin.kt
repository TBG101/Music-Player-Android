package com.tbg101.musicplayer

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMethodCodec
import org.json.JSONArray
import org.json.JSONObject

class MediaScannerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var heavyChannel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "music.player/utils/scanMedia")
        channel.setMethodCallHandler(this)

        // MediaStore queries and MediaMetadataRetriever extraction are far too
        // heavy for the platform main thread: running them there stalls frames
        // for the whole background sync. This queue runs the handler (and its
        // Result) off the UI thread, serialized so calls don't race each other.
        heavyChannel = MethodChannel(
            binding.binaryMessenger,
            "music.player/utils/heavyScan",
            StandardMethodCodec.INSTANCE,
            binding.binaryMessenger.makeBackgroundTaskQueue()
        )
        heavyChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        heavyChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanMedia" -> {
                val path = call.argument<String>("mp3FilePath")
                if (path == null) {
                    result.error("INVALID_ARGS", "mp3FilePath is null", null)
                    return
                }
                androidScanMediaTrigger(path, result)
            }

            "getAllAudio" -> {
                val list = AudioScanner.getAllAudio(context)
                val json = JSONArray()
                for (audio in list) {
                    val obj = JSONObject()
                    obj.put("id", audio.id)
                    obj.put("title", audio.title)
                    obj.put("artist", audio.artist)
                    obj.put("album", audio.album)
                    obj.put("duration", audio.duration)
                    obj.put("uri", audio.uri)
                    obj.put("albumId", audio.albumId)
                    obj.put("albumArt", audio.albumArt ?: JSONObject.NULL)
                    json.put(obj)
                }
                result.success(json.toString())
            }

            "deleteAudio" -> {
                val audioUri = call.argument<String>("audioUri")
                if (audioUri == null) {
                    result.error("INVALID_ARGS", "audioUri is null", null)
                    return
                }
                try {
                    AudioScanner.deleteAudio(context, audioUri)
                    result.success(true)
                } catch (e: SecurityException) {
                    result.error("DELETE_DENIED", e.message, null)
                } catch (e: Exception) {
                    result.error("DELETE_FAILED", e.message, null)
                }
            }

            "cacheArtwork" -> {
                val audioUri = call.argument<String>("audioUri")
                val artUri = call.argument<String>("artUri")
                val cachePath = call.argument<String>("cachePath")
                val overwrite = call.argument<Boolean>("overwrite") ?: true

                if (cachePath == null) {
                    result.error("INVALID_ARGS", "cachePath is null", null)
                    return
                }
                val res =
                    AudioScanner.cacheArtwork(context, audioUri, artUri, cachePath, overwrite)
                if (res == true) {
                    result.success(true)
                } else {
                    result.error("CACHE_FAILED", "Failed to cache album art", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun androidScanMediaTrigger(filePath: String, result: Result) {
        val mimeType = when {
            filePath.endsWith(".mp3", true) -> "audio/mpeg"
            filePath.endsWith(".m4a", true) -> "audio/mp4"
            filePath.endsWith(".webm", true) -> "audio/webm"
            filePath.endsWith(".ogg", true) -> "audio/ogg"
            filePath.endsWith(".flac", true) -> "audio/flac"
            else -> null
        }

        val mainHandler = Handler(Looper.getMainLooper())
        var completed = false
        val finish = {
            if (!completed) {
                completed = true
                result.success(null)
            }
        }

        android.media.MediaScannerConnection.scanFile(
            context,
            arrayOf(filePath),
            arrayOf(mimeType)
        ) { _, _ ->
            mainHandler.post { finish() }
        }

        // Safety net so the Dart future never hangs if the scanner never
        // reports back (e.g. the file disappeared before it was indexed).
        mainHandler.postDelayed({ finish() }, 10000)
    }
}
