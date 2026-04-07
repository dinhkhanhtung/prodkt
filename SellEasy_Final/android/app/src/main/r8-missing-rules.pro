# Quy tắc R8 để xử lý các lớp bị thiếu
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Bỏ qua cảnh báo cho các lớp khác
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn org.slf4j.**
-dontwarn javax.**

# Giữ lại các lớp quan trọng
-keep class com.dinhkhanhtung.selleasy.MainActivity { *; }
