# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Fix for R8 Missing Play Core classes and Flutter deferred components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Firebase & Google Play Services
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Razorpay SDK
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Socket.IO & Engine.IO
-keep class io.socket.** { *; }
-keep class io.socket.client.** { *; }
-keep class io.socket.engineio.client.** { *; }
-dontwarn io.socket.**
