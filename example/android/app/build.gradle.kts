import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val rapidSigningProperties = System.getenv("RAPID_ANDROID_SIGNING_PROPERTIES")?.let { path ->
    Properties().apply { file(path).inputStream().use { load(it) } }
}

android {
    namespace = "com.tange.ai.rapid_kit_example"
    compileSdk = 36
    ndkVersion = rootProject.extra["rapidNdkVersion"] as String
    

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {        
        applicationId = "com.tange.ai.rapid_kit_example"        
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName        
    }

        

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("rapid_kit")
            isShrinkResources = true
            isMinifyEnabled = true
            ndk.abiFilters.clear()
            ndk.abiFilters.addAll(listOf("arm64-v8a"))
        }
        debug {
            signingConfig = signingConfigs.findByName("rapid_kit") ?: signingConfigs.getByName("debug")
            ndk.abiFilters.clear()
            ndk.abiFilters.addAll(listOf("arm64-v8a"))            
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}
