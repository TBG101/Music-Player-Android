package com.tbg101.musicplayer

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore

data class AudioFile(
    val id: Long,
    val title: String?,
    val artist: String?,
    val album: String?,
    val duration: Long,
    val uri: String,
    val albumId: Long,
    val albumArt: String?
)

object AudioScanner {

    fun getAllAudio(context: Context): List<AudioFile> {
        val audioList = mutableListOf<AudioFile>()

        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.ALBUM_ID
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC"

        context.contentResolver.query(
            collection,
            projection,
            selection,
            null,
            sortOrder
        )?.use { cursor ->

            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

            while (cursor.moveToNext()) {

                val id = cursor.getLong(idCol)
                val albumId = cursor.getLong(albumIdCol)

                val audioUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id
                ).toString()

                val albumArtUri = ContentUris.withAppendedId(
                    Uri.parse("content://media/external/audio/albumart"),
                    albumId
                ).toString()

                audioList.add(
                    AudioFile(
                        id = id,
                        title = cursor.getString(titleCol),
                        artist = cursor.getString(artistCol),
                        album = cursor.getString(albumCol),
                        duration = cursor.getLong(durationCol),
                        uri = audioUri,
                        albumId = albumId,
                        albumArt = albumArtUri // allow null handling on Flutter side
                    )
                )
            }
        }

        return audioList
    }

    fun deleteAudio(context: Context, audioUri: String) {
        val uri = Uri.parse(audioUri)
        context.contentResolver.delete(uri, null, null)
    }

    fun cacheArtwork(
        context: Context,
        audioUri: String?,
        artUri: String?,
        cachePath: String,
        overwrite: Boolean = true
    ): Boolean {
        val outFile = java.io.File(cachePath)

        // Reuse an existing file only when we are not asked to refresh it.
        if (!overwrite && outFile.exists() && outFile.length() > 0) {
            return true
        }

        outFile.parentFile?.mkdirs()

        // The track's own embedded cover is authoritative. MediaStore groups
        // files by album id, so its album art can belong to a different track
        // (downloads in particular carry no album tag and share that bucket).
        val embedded = readEmbeddedArt(context, audioUri)
        if (embedded != null && embedded.size > 100) {
            outFile.writeBytes(embedded)
            return true
        }

        try {
            val uri = artUri?.let { Uri.parse(it) }

            if (uri != null) {
                context.contentResolver.openInputStream(uri)?.use { stream ->
                    val bytes = stream.readBytes()

                    if (bytes.isNotEmpty() && bytes.size > 100) {
                        outFile.writeBytes(bytes)
                        return true
                    }
                }
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }

        // No usable art: drop any stale file so the fallback is used.
        if (outFile.exists()) {
            outFile.delete()
        }
        return false
    }

    private fun readEmbeddedArt(context: Context, audioUri: String?): ByteArray? {
        val uri = audioUri?.let { Uri.parse(it) } ?: return null
        val retriever = android.media.MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            retriever.embeddedPicture
        } catch (e: Exception) {
            e.printStackTrace()
            null
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }
}