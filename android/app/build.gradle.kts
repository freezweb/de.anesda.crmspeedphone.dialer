import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.github.triplet.play")
}

android {
    namespace = "de.anesda.speedphone_dialer"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "de.anesda.crmspeedphone.dialer"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val signingPropertiesFile = rootProject.file("key.properties")
    val signingProperties = Properties()
    if (signingPropertiesFile.exists()) {
        FileInputStream(signingPropertiesFile).use(signingProperties::load)
        signingConfigs {
            create("release") {
                storeFile = file(signingProperties["storeFile"] as String)
                storePassword = signingProperties["storePassword"] as String
                keyAlias = signingProperties["keyAlias"] as String
                keyPassword = signingProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signingPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

val playServiceAccount = System.getenv("PLAY_SERVICE_ACCOUNT_JSON")?.let { file(it) }
if (playServiceAccount != null && playServiceAccount.exists()) {
    play {
        serviceAccountCredentials.set(playServiceAccount)
        defaultToAppBundles.set(true)
        track.set("internal")
        releaseStatus.set(com.github.triplet.gradle.androidpublisher.ReleaseStatus.COMPLETED)
        resolutionStrategy.set(com.github.triplet.gradle.androidpublisher.ResolutionStrategy.AUTO)
    }
} else {
    play { enabled.set(false) }
}
