plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

configurations.all {
    resolutionStrategy {

        // ✅ downgrade supaya tidak minta AGP 8.9+
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.browser:browser:1.8.0")

        // ✅ activity versi aman
        force("androidx.activity:activity:1.9.3")
        force("androidx.activity:activity-ktx:1.9.3")

        // ✅ fragment: pakai yang PASTI ADA
        force("androidx.fragment:fragment:1.6.2")
        force("androidx.fragment:fragment-ktx:1.6.2")

        // kalau masih bandel:
        eachDependency {
            if (requested.group == "androidx.core") useVersion("1.13.1")
            if (requested.group == "androidx.browser") useVersion("1.8.0")
            if (requested.group == "androidx.fragment") useVersion("1.6.2")
        }
    }
}


android {
    namespace = "com.example.fluent_ai"
    // Override flutter.compileSdkVersion to ensure newer Android attributes (e.g. android:attr/lStar) are available
    // Set to 36 to match modern Android libraries/plugins that require newer SDKs
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.fluent_ai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ✅ TAMBAHKAN BLOK INI
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
