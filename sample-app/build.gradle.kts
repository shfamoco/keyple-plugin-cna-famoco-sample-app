plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    kotlin("android.extensions")
}

android {
    namespace = "com.famoco.keypleplugin.pcl.sampleapp"
    compileSdk = 33
    buildToolsVersion = "30.0.3"

    defaultConfig {
        applicationId = "com.famoco.keypleplugin.pcl.sampleapp"
        minSdk = 19
        targetSdk = 33
        versionCode = 10
        versionName = "0.1.0"
        multiDexEnabled = true

        setProperty("archivesBaseName", "keyple-plugin-pcl-sample-app-$versionName")
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("untrusted_app") {
            keyAlias= "untrusted"
            keyPassword = "untrusted"
            storeFile = file("keystore/untrusted_app.keystore")
            storePassword = "untrusted"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("untrusted_app")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    packagingOptions {
        exclude("META-INF/NOTICE.md")
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

val kotlinVersion: String by project
dependencies {

    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    implementation("org.calypsonet.keyple:keyple-plugin-cna-famoco-se-communication-java-lib:2.0.2")

    implementation("org.calypsonet.terminal:calypsonet-terminal-reader-java-api:1.2.0") {
        isChanging = true
    }
    implementation("org.calypsonet.terminal:calypsonet-terminal-calypso-java-api:1.5.0") {
        isChanging = true
    }
    implementation("org.eclipse.keyple:keyple-common-java-api:2.0.0") { isChanging = true }
    implementation("org.eclipse.keyple:keyple-service-java-lib:2.1.3")
    implementation("org.eclipse.keyple:keyple-service-resource-java-lib:2.0.2")
    implementation("org.eclipse.keyple:keyple-card-calypso-java-lib:2.3.2")
    implementation("org.eclipse.keyple:keyple-util-java-lib:2.3.0") { isChanging = true }

    // Log
    implementation("org.slf4j:slf4j-api:2.0.6")
    implementation("com.jakewharton.timber:timber:5.0.1")
    implementation("com.arcao:slf4j-timber:3.1@aar") //SLF4J binding for Timber

    implementation("androidx.activity:activity-ktx:1.6.1")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.8.0")
    implementation("androidx.multidex:multidex:2.0.1")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}