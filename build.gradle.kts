// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    id("org.jetbrains.kotlin.android") version "1.7.20" apply false
    id("org.sonarqube") version "3.3"
    id("org.jetbrains.dokka") version "1.7.20"
}

buildscript {
    val kotlinVersion: String by project
    repositories {
        mavenLocal()
        google()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.android.tools.build:gradle:7.4.2")
        classpath("org.eclipse.keyple:keyple-gradle:0.2.17")
        classpath("org.sonarsource.scanner.gradle:sonarqube-gradle-plugin:3.3")

    }
}

sonarqube {
    properties {
        property("sonar.projectKey", "keyple-pcl-plugin")
        property("sonar.projectName", "Keyple PCL plugin")
        property("sonar.verbose", "false")
    }
}
