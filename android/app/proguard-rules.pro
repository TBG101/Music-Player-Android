# R8 renames/strips com.ryanheise.just_audio.AudioPlayer$ObserverRenderer whose
# getName() is called by androidx.media3 MappingTrackSelector during track
# selection, which throws a NullPointerException on release builds (debug is
# unaffected since R8 does not run).
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**
