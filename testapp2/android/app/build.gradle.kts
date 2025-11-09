plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Apply the Google services plugin so firebase config in google-services.json is processed
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.testapp2"
    compileSdk = flutter.compileSdkVersion
    // Use explicit NDK version required by some native dependencies (e.g. Firebase plugins)
    // This ensures Gradle selects NDK 27.0.12077973 instead of the older configured version.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.testapp2"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
    // Firebase Android libraries require a minimum SDK of 23+. Override the flutter-provided
    // minSdkVersion to ensure compatibility with the native Firebase dependencies.
    minSdk = 23
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

flutter {
    source = "../.."
}
