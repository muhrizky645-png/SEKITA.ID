import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // Flutter Gradle Plugin harus diterapkan setelah Android & Kotlin plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Muat kredensial keystore dari android/key.properties bila ada.
// File ini TIDAK di-commit ke Git. Codemagic membuatnya otomatis saat
// Android code signing diaktifkan di Workflow Editor.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasKeystore = keystorePropertiesFile.exists()

android {
    namespace = "id.sekita.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "id.sekita.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // PENTING: Nonaktifkan R8/minifikasi & shrink resources.
            // Di AGP 9, R8 aktif default untuk build release. R8 mengacak nama
            // class Room (WorkDatabase_Impl) yang diakses via reflection oleh
            // WorkManager, sehingga androidx.startup InitializationProvider gagal
            // membuat WorkDatabase -> FATAL EXCEPTION / force close saat app dibuka.
            // OneSignal menarik WorkManager, jadi ini wajib dimatikan.
            // (Untuk rilis Play Store dgn ukuran lebih kecil, bisa aktifkan lagi
            //  minify TAPI dengan keep rules Room/WorkManager/OneSignal di proguard-rules.pro.)
            isMinifyEnabled = false
            isShrinkResources = false

            // Pakai signing release bila key.properties tersedia,
            // selain itu fallback ke debug agar `flutter run --release` tetap jalan.
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
