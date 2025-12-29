# Tink optional classes (ignore missing)
-dontwarn com.google.api.client.**
-keep class com.google.crypto.tink.** { *; }

# Joda-Time optional classes
-dontwarn org.joda.convert.**
-keep class org.joda.time.** { *; }

# ErrorProne annotations
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# javax annotations
-dontwarn javax.lang.model.element.**
-dontwarn javax.annotation.**
-keep class javax.annotation.** { *; }
