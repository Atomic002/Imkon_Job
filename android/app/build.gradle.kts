plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // 🔥 YANGI: Bu qatorni qo'shing
}

android {
    namespace = "com.example.version1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.atomicdev.imkonjob"
        minSdk = flutter.minSdkVersion  // 🔥 MUHIM: Firebase uchun kamida 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // Firebase Messaging
    implementation("com.google.firebase:firebase-messaging-ktx")
    
    // Firebase Analytics (ixtiyoriy)
    implementation("com.google.firebase:firebase-analytics-ktx")
}

flutter {
    source = "../.."
}
