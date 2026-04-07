# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep your model classes
-keep class com.dinhkhanhtung.selleasy.models.** { *; }
-keep class com.dinhkhanhtung.selleasy.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep SQLite
-keep class com.dinhkhanhtung.selleasy.database.** { *; }

# Keep Google Play Libraries
-keep class com.google.android.play.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Keep In-App Purchase classes
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }

# Keep specific Play Core classes needed by Flutter
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Ignore warnings for missing classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Thêm các lớp cần thiết cho Flutter
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$FeatureInstallStateUpdatedListener { *; }

# Giữ lại các lớp quan trọng của Flutter
-keep class androidx.lifecycle.** { *; }
-keep class androidx.fragment.app.** { *; }
-keep class androidx.core.app.** { *; }
-keep class androidx.core.content.** { *; }
-keep class androidx.core.view.** { *; }

# Giữ lại các lớp Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Giữ lại các lớp của thư viện
-keep class org.jetbrains.** { *; }

# Tạo file mapping cho Google Play Console
-printmapping mapping.txt
-keepattributes SourceFile,LineNumberTable,Exceptions,InnerClasses,Signature,Deprecated,*Annotation*,EnclosingMethod
-renamesourcefileattribute SourceFile