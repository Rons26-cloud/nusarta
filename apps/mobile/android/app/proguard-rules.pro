# NUSARTA release ProGuard rules.
# Keep Supabase / networking as-is.
-dontwarn org.slf4j.**
-keep class com.nusarta.app.** { *; }
-keepattributes *Annotation*