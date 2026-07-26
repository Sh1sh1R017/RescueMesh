# Flutter R8 / ProGuard Keep Rules for Release Builds
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.gms.**
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class com.google.android.gms.** { *; }
