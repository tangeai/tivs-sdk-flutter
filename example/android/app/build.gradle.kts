plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tange.ai.rapid_kit_example"
    compileSdk = 36
    ndkVersion = rootProject.extra["rapidNdkVersion"] as String
    

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
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
            signingConfig = signingConfigs.getByName("debug")
            isShrinkResources = true
            isMinifyEnabled = true
            ndk.abiFilters.clear()
            ndk.abiFilters.addAll(listOf("arm64-v8a"))
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")          
            ndk.abiFilters.clear()
            ndk.abiFilters.addAll(listOf("arm64-v8a"))            
        }
    }
}

flutter {
    source = "../.."
}
