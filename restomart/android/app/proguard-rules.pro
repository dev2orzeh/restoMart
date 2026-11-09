# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Firebase & Google Play Services
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# Cloud Firestore & Firebase Auth
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

