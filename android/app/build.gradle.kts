import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.harkonedesigns.nmilleniumresource"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.harkonedesigns.dakeventures"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Dynamically resolve brand-specific signing credentials from tracked brands/<brand>/ directory
            val brandName = defaultConfig.applicationId?.substringAfterLast('.') ?: ""
            val brandDir = rootProject.file("../brands/$brandName")
            val brandKeyProp = File(brandDir, "key.properties")
            val rootKeyProp = rootProject.file("key.properties")

            val activePropFile = if (brandKeyProp.exists()) {
                brandKeyProp
            } else if (rootKeyProp.exists()) {
                rootKeyProp
            } else {
                null
            }

            if (activePropFile != null && activePropFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(activePropFile))

                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storePassword = keystoreProperties["storePassword"] as String?

                val brandStoreFile = File(brandDir, "upload-keystore.jks")
                if (brandStoreFile.exists()) {
                    storeFile = brandStoreFile
                } else if (keystoreProperties["storeFile"] != null) {
                    val customStore = File(activePropFile.parentFile, keystoreProperties["storeFile"] as String)
                    storeFile = if (customStore.exists()) customStore else file(keystoreProperties["storeFile"] as String)
                } else {
                    storeFile = file("upload-keystore.jks")
                }
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.getByName("release")
            if (releaseConfig.storeFile?.exists() == true) {
                signingConfig = releaseConfig
            } else {
                val brandName = defaultConfig.applicationId?.substringAfterLast('.') ?: ""
                throw GradleException("Release Build Failed: No valid release keystore found for brand '$brandName'. Checked brands/$brandName/upload-keystore.jks and android/key.properties.")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
