# Velvet ProGuard / R8 keep rules
# v26 release minification · 不破坏序列化和反射

# Flutter wrapper（dev.flutter Gradle plugin 已自动 keep · 这里加保险）
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 反射用枚举（API enum 序列化保留）
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# AndroidX 主流组件（防 R8 在 Activity 启动期 strip 注解）
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.** { *; }

# OkHttp 平台兼容（部分 Flutter 插件携带）
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Kotlin 元数据
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$Companion { *; }

# Velvet 应用入口
-keep class com.hrapp.velvet.** { *; }

# Crash 行号保留（线上问题诊断必需）
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# 通用注解
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Flutter Play Store deferred-components 引用 · 项目未启用 deferred features · 全部静音
# 不加这些会导致 R8 minify 失败：Missing class com.google.android.play.core.splitinstall.*
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
