#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# WorkManager (Background Service)
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-keep class be.tramckrijte.workmanager.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Supabase / HTTP
-keep class io.supabase.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Hive
-keep class hive.** { *; }
-keep class io.hive.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Timezone
-keep class com.baseflow.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# GSON (critical for flutter_local_notifications serialization)
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.examples.android.model.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep AlarmManager BroadcastReceiver for scheduled notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.receivers.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# General Android
-keep class android.** { *; }
-keep class androidx.** { *; }
-dontwarn android.**
-dontwarn androidx.**

# Prevent R8 from stripping interfaces
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Prevent obfuscation of types used in reflection
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
