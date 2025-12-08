## ========================================
## ProGuard Rules for Silni App
## ========================================
##
## These rules configure R8/ProGuard for:
## - Code shrinking (removing unused code)
## - Code obfuscation (security)
## - Resource shrinking (smaller APK)
##
## ========================================

# ========================================
# Flutter Rules
# ========================================

# Keep Flutter wrapper code
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Keep Flutter embedding
-keep class io.flutter.embedding.** { *; }

# Preserve line numbers for stack traces
-keepattributes SourceFile,LineNumberTable

# Keep custom exceptions for better debugging
-keep public class * extends java.lang.Exception

# ========================================
# Supabase Rules
# ========================================

# Keep Supabase/Postgrest classes
-keep class io.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }

# Keep JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Keep Gson/JSON classes (Supabase uses JSON)
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Keep data model classes (Supabase serialization)
-keep class com.silni.app.** { *; }

# ========================================
# Firebase Cloud Messaging (FCM) Rules
# ========================================

# Keep Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keep class com.google.firebase.installations.** { *; }

# Keep Firebase core
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.FirebaseOptions { *; }
-keep class com.google.firebase.components.** { *; }

# ========================================
# Kotlin Rules
# ========================================

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep Kotlin coroutines (Supabase uses coroutines)
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** { volatile <fields>; }

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

-keep,includedescriptorclasses class com.silni.app.**$$serializer { *; }
-keepclassmembers class com.silni.app.** {
    *** Companion;
}
-keepclasseswithmembers class com.silni.app.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ========================================
# Networking Rules (OkHttp, Retrofit, Ktor)
# ========================================

# OkHttp (used by Supabase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Ktor (used by Supabase Kotlin client)
-keep class io.ktor.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.atomicfu.**
-dontwarn io.netty.**
-dontwarn com.typesafe.**
-dontwarn org.slf4j.**

# ========================================
# Image Loading (Cached Network Image)
# ========================================

-keep class com.bumptech.glide.** { *; }
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep public class * extends com.bumptech.glide.module.AppGlideModule
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}

# ========================================
# Cloudinary Rules
# ========================================

-keep class com.cloudinary.** { *; }
-dontwarn com.cloudinary.**

# ========================================
# Third-party Library Rules
# ========================================

# Lottie animations
-keep class com.airbnb.lottie.** { *; }
-dontwarn com.airbnb.lottie.**

# Rive animations
-keep class app.rive.** { *; }
-dontwarn app.rive.**

# ========================================
# General Android Rules
# ========================================

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep view constructors (for XML inflation)
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep activity methods (lifecycle)
-keepclassmembers class * extends android.app.Activity {
   public void *(android.view.View);
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementation
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable implementation
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ========================================
# Debugging & Crash Reporting
# ========================================

# Keep source file names and line numbers for crash reports
-keepattributes SourceFile,LineNumberTable

# Rename source file names to obfuscate while keeping line numbers
-renamesourcefileattribute SourceFile

# Keep all exception classes for better crash reports
-keep class * extends java.lang.Exception

# ========================================
# Optimization Flags
# ========================================

# Enable aggressive optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# ========================================
# Warnings to Ignore
# ========================================

# Suppress warnings for missing classes we don't use
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn edu.umd.cs.findbugs.annotations.**

# ========================================
# App-Specific Rules
# ========================================

# Keep your data models
-keep class com.silni.app.models.** { *; }
-keep class com.silni.app.shared.models.** { *; }

# Keep your services
-keep class com.silni.app.services.** { *; }
-keep class com.silni.app.shared.services.** { *; }

# ========================================
# Notes
# ========================================
#
# This file is used by R8 (replacement for ProGuard in modern Android)
# R8 is enabled when you build a release APK with minifyEnabled = true
#
# Testing ProGuard rules:
# 1. Build release APK: flutter build apk --release
# 2. Check app size reduction
# 3. Test all features thoroughly
# 4. Check crash reports have readable stack traces
#
# If you encounter issues:
# 1. Check build output for warnings
# 2. Add specific -keep rules for affected classes
# 3. Use -dontwarn for known safe warnings
#
# ========================================
# Google Play Core Rules (for Flutter deferred components)
# ========================================

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# ========================================
