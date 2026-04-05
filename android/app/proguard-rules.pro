# Prevent obfuscation and stripping of ZEGOCLOUD SDK classes
-keep class **.zego.** { *; }

# Keep properties that are accessed via reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable
