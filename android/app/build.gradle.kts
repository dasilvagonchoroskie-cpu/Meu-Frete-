import java.io.FileInputStream
import java.util.Properties

// Assinatura: chave de envio da Play Store (segredo do GitHub). A esteira
// escreve o key.properties antes de compilar. Sem ele (build local de quem
// nao tem a chave), sai assinado com a chave de depuracao.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val temAssinaturaDeProducao = keystorePropertiesFile.exists()
if (temAssinaturaDeProducao) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.fortalezadigitalsecurity.meufrete"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.fortalezadigitalsecurity.meufrete"
        minSdk = flutter.minSdkVersion
        // Play Store: apps novos e atualizacoes precisam mirar o Android mais recente.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Bibliotecas nativas comprimidas dentro do APK: o arquivo fica bem menor
    // para mandar pelo WhatsApp. No AAB da Play Store a loja ja entrega so o
    // pedaco de cada celular.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        create("release") {
            if (temAssinaturaDeProducao) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (temAssinaturaDeProducao) {
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
