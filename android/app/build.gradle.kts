import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()

if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Un build release doit choisir son API explicitement (--dart-define=APP_ENV=dev|uat|prod) :
// sans cela l'application pointerait silencieusement en dev (voir lib/config/app_environment.dart).
val allowedAppEnvs = setOf("dev", "uat", "prod")
val isReleaseBuild = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
if (isReleaseBuild) {
    val dartDefines = (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.filter { it.isNotBlank() }
        ?.map { String(Base64.getDecoder().decode(it)) }
        .orEmpty()
    val appEnv = dartDefines.firstOrNull { it.startsWith("APP_ENV=") }
        ?.substringAfter("=")
        ?.trim()
        ?.lowercase()
    if (appEnv !in allowedAppEnvs) {
        throw GradleException(
            "APP_ENV manquant ou invalide (${appEnv ?: "absent"}) pour un build release. " +
                "Ajoutez --dart-define=APP_ENV=dev|uat|prod, ex. : " +
                "flutter build appbundle --dart-define=APP_ENV=prod"
        )
    }
    logger.lifecycle("Prosoc : build release pour APP_ENV=$appEnv")
}

android {
    namespace = "com.maash.prosoc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.maash.prosoc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fallback debug : permet `flutter run --release` sans keystore local.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
