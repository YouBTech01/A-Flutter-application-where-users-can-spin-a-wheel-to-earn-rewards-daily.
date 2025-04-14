plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")  // Google Services plugin
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.spin_to_earn"
    compileSdk = 35  // Updated as per requirements
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.spin_to_earn"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21  // Updated as per requirements
        targetSdk = 35  // Updated as per requirements
        versionCode = 1
        versionName = "1.0.0"
        
        // Disable the AdServices manifest placeholder
        manifestPlaceholders["adServicesEnabled"] = false
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // This helps with the manifest merger
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "META-INF/INDEX.LIST"
            excludes += "META-INF/io.netty.versions.properties"
        }
    }
}

dependencies {
    // Firebase BoM - ensures compatible versions are used
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // Firebase Analytics without version (uses BoM version)
    implementation("com.google.firebase:firebase-analytics")
    
    // Explicitly define the AdMob version to resolve conflicts
    implementation("com.google.android.gms:play-services-ads:22.5.0")
}

flutter {
    source = "../.."
}
